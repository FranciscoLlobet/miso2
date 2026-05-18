const c = @import("c.zig").c;

pub fn Led(
    comptime port: *c.GPIO_Type,
    comptime pin: u32,
    comptime polarity: bool,
) type {
    return struct {
        /// Set value
        pub fn set(self: *@This()) void {
            _ = self;

            c.GPIO_PinWrite(port, pin, @intFromBool(polarity));
        }
        /// Clear current value
        pub fn clear(self: *@This()) void {
            _ = self;

            c.GPIO_PinWrite(port, pin, @intFromBool(!polarity));
        }
        /// Toggle (invert) current value
        pub fn toggle(self: *@This()) void {
            _ = self;

            const val = c.GPIO_PinRead(port, pin);

            c.GPIO_PinWrite(port, pin, if (val == @as(u32, 1)) 0 else 1);
        }
        pub fn get(self: *@This()) bool {
            _ = self;

            return (@intFromBool(polarity) == c.GPIO_PinRead(port, pin));
        }
    };
}
