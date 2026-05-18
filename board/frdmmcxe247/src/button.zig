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
) type {
    return struct {
        state: bool,
        button_change_callback: ?ButtonChangeCallback,
        debounce_timer: rtx.timer.StaticTimer(@This(), name ++ "_tmr", timerCallback),

        inline fn readPin() bool {
            return (@intFromBool(polarity) == c.GPIO_PinRead(gpio, pin));
        }

        fn timerCallback(self: ?*@This()) void {
            // disable irq ?
            const state = readPin();

            @atomicStore(@TypeOf(self.?.state), &self.?.state, state, .seq_cst);

            if (self.?.button_change_callback) |callback| {
                callback(id, self.?.state);
            }
        }

        pub fn init(self: *@This(), callback: ?ButtonChangeCallback) !void {
            self.state = readPin();

            try self.debounce_timer.new(.osTimerOnce, self, 0);

            self.button_change_callback = callback;
        }

        pub fn get(self: *@This()) bool {
            return @atomicLoad(@TypeOf(self.state), &self.state, .seq_cst);
        }

        pub fn handleIsr(self: *@This()) void {
            self.debounce_timer.start(20) catch {};
        }
    };
}
