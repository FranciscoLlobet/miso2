const std = @import("std");
const miso2 = @import("miso2");

extern fn main() callconv(.c) c_int;

export fn zigMain() noreturn {
    //_ = main();

    // Initialize kernel

    unreachable;
}

export fn _start() linksection(".init") callconv(.naked) void {
    asm volatile ("b Reset_Handler");
}
