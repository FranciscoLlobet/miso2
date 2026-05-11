const std = @import("std");
const miso2 = @import("miso2");
const board = @import("board");

export fn zmain() noreturn {
    board.initialize();
    while (true) {
        //
    }
}

export fn _start() linksection(".init") callconv(.naked) void {
    asm volatile ("b Reset_Handler");
}
