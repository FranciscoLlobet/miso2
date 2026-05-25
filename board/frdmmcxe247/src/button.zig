const c = @import("c.zig").c;
const rtx = @import("cmsis_rtx");

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
    comptime debounce_ticks: u32,
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
                .state = false,
                .button_change_callback = null,
                .debounce_timer = undefined,
            };
        }

        inline fn readPin() bool {
            return (@intFromBool(polarity) == c.GPIO_PinRead(gpio, pin));
        }

        fn timerCallback(self: *@This()) void {
            const new_value = readPin();
            const old_value = @atomicLoad(
                bool,
                &self.isr_state,
                .seq_cst,
            );

            if (new_value == old_value) {
                @atomicStore(
                    @TypeOf(self.state),
                    &self.state,
                    new_value,
                    .seq_cst,
                );

                if (self.button_change_callback) |callback| {
                    callback(id, self.state);
                }
            } else {
                @atomicStore(
                    @TypeOf(self.isr_state),
                    &self.isr_state,
                    new_value,
                    .seq_cst,
                );

                self.debounce_timer.start(debounce_ticks) catch unreachable;
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

        fn timerJob(self: *@This()) callconv(.c) void {
            self.debounce_timer.start(debounce_ticks) catch unreachable;
        }

        pub fn handleIsr(self: *@This()) void {
            // read pin at isr state
            @atomicStore(
                @TypeOf(self.isr_state),
                &self.isr_state,
                readPin(),
                .seq_cst,
            );

            rtx.kernel.Hacks.osKernelTimer(@This()).send(
                timerJob,
                self,
            ) catch unreachable;
        }

        pub fn setCallback(self: *@This(), callback: ButtonChangeCallback) void {
            self.button_change_callback = callback;
        }
    };
}
