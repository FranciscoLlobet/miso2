const std = @import("std");
const miso2 = @import("miso2");
const board = @import("board");
//extern fn main() callconv(.c) c_int;

export fn main() callconv(.c) c_int {
    while (true) {
        //
    }
    unreachable;
}

export fn zmain() noreturn {
    board.initialize();
    while (true) {
        //
    }
}

export fn _start() linksection(".init") callconv(.naked) void {
    asm volatile ("b Reset_Handler");
}
