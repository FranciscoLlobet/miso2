const c = @import("c.zig").c;

pub fn Led(
    comptime port: *c.GPIO_Type,
    comptime pin: u32,
    comptime polarity: bool,
) type {
    return struct {
        pub fn default() @This() {
            return .{};
        }
        /// Set value
        pub fn set(_: *@This()) void {
            c.GPIO_PinWrite(port, pin, @intFromBool(polarity));
        }
        /// Clear current value
        pub fn clear(_: *@This()) void {
            c.GPIO_PinWrite(port, pin, @intFromBool(!polarity));
        }
        /// Toggle (invert) current value
        pub fn toggle(_: *@This()) void {
            const val = c.GPIO_PinRead(port, pin);

            c.GPIO_PinWrite(port, pin, if (val == @as(u32, 1)) 0 else 1);
        }
        pub fn get(_: *@This()) bool {
            return (@intFromBool(polarity) == c.GPIO_PinRead(port, pin));
        }
    };
}
