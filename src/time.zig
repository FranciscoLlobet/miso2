const std = @import("std");
const board = @import("board");
const rtx = @import("cmsis_rtx");
const ntp = @import("ntp.zig");

//
rtcTimer: rtx.StaticTimer(
    @This(),
    "rtxTimer",
    rtc_timer_tick,
),

current_time_s: u32,

pub fn rtc_timer_tick(self: *@This()) void {
    @atomicStore(
        u32,
        &self.current_time_s,
        @atomicLoad(
            u32,
            &self.current_time_s,
            .seq_cst,
        ) + 1,
        .seq_cst,
    );
}

pub fn get_time(self: *@This()) u32 {
    return @atomicLoad(
        u32,
        &self.current_time_s,
        .seq_cst,
    );
}

pub fn set_time(self: *@This(), val: u32) !void {
    try self.rtcTimer.stop();

    @atomicStore(
        @TypeOf(val),
        &self.current_time_s,
        val,
        .seq_cst,
    );

    try self.rtcTimer.start(1000);
}
