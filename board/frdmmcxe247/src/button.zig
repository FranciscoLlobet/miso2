const c = @import("c.zig").c;
const rtx = @import("cmsis_rtx");
const runtime = @import("runtime.zig");

const GPIO_Type = c.GPIO_Type;

pub const ButtonId = enum(u32) {
    sw2,
    sw3,
};

const ButtonChangeCallback = *fn (id: ButtonId, val: bool) void;

pub fn Button(
    comptime name: []const u8,
    comptime id: ButtonId,
    comptime gpio: *GPIO_Type,
    comptime pin: u32,
    comptime polarity: bool,
) type {
    return struct {
        state: bool,
        isr_state: bool,
        stability_count: u32,
        button_change_callback: ?ButtonChangeCallback,
        debounce_timer: rtx.timer.StaticTimer(@This(), name ++ "_tmr", timerCallback),

        pub fn default() @This() {
            return .{
                .isr_state = false,
                .stability_count = 0,
                .state = undefined,
                .button_change_callback = null,
                .debounce_timer = undefined,
            };
        }

        inline fn readPin() bool {
            return (@intFromBool(polarity) == c.GPIO_PinRead(gpio, pin));
        }

        fn timerCallback(self: ?*@This()) void {
            // disable irq ?
            const s = self.?;

            const new_value = readPin();
            const old_value = @atomicLoad(bool, &s.isr_state, .seq_cst);

            if (new_value == old_value) {
                @atomicStore(
                    @TypeOf(s.state),
                    &s.state,
                    new_value,
                    .seq_cst,
                );

                if (s.button_change_callback) |callback| {
                    callback(id, s.state);
                }
            } else {
                @atomicStore(
                    @TypeOf(s.isr_state),
                    &s.isr_state,
                    new_value,
                    .seq_cst,
                );

                s.debounce_timer.start(20) catch unreachable;
            }
        }

        pub fn init(self: *@This(), callback: ?ButtonChangeCallback) !void {
            self.state = readPin();
            self.stability_count = 1;

            try self.debounce_timer.new(.osTimerOnce, self, 0);

            self.button_change_callback = callback;
        }

        pub fn get(self: *@This()) bool {
            return @atomicLoad(@TypeOf(self.state), &self.state, .seq_cst);
        }

        fn timerJob(param: ?*anyopaque) void {
            const self = @as(?*@This(), @ptrCast(@alignCast(param))) orelse unreachable;

            self.debounce_timer.start(20) catch unreachable;
        }

        pub fn handleIsr(self: *@This()) void {
            // read pin at isr state
            @atomicStore(
                @TypeOf(self.isr_state),
                &self.isr_state,
                readPin(),
                .seq_cst,
            );

            runtime.hwJobQueue.send(timerJob, @ptrCast(@alignCast(self)), 0) catch unreachable;
        }

        pub fn setCallback(self: *@This(), callback: ButtonChangeCallback) !void {
            self.callback = callback;
        }
    };
}
