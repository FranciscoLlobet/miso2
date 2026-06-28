const std = @import("std");
const c = @import("c.zig").c;
const epoch = @import("std").time.epoch;

const nvic_iser: [*]volatile u32 = @ptrFromInt(0xE000E100);

fn nvicEnableIRQ(irqn: c.IRQn_Type) void {
    const irqn_u: u32 = @intCast(irqn);
    nvic_iser[irqn_u >> 5] = @as(u32, 1) << @intCast(irqn_u & 0x1F);
}

pub inline fn ntp_to_unix(ntp_timestamp: u32) u32 {
    return @intCast(
        @as(i64, @intCast(ntp_timestamp)) + @as(i64, @intCast(epoch.zos)),
    );
}

pub inline fn unix_to_ntp(unix_timestamp: u32) u32 {
    return @intCast(
        @as(i64, @intCast(unix_timestamp)) - @as(i64, @intCast(epoch.zos)),
    );
}

pub fn Rtc(
    comptime rtc: [*c]c.RTC_Type,
    comptime initial_time_stamp: u32,
) type {
    return struct {
        val: u32,

        pub fn default() @This() {
            return .{
                .val = initial_time_stamp,
            };
        }
        pub fn start(_: *@This()) void {
            rtc.*.TSR = comptime if (initial_time_stamp != 0) initial_time_stamp else 1;

            c.RTC_ClearStatusFlags(rtc, c.RTC_GetStatusFlags(rtc));

            c.RTC_SetTimerSecondsInterruptFrequency(rtc, c.kRTC_TimerSecondsFrequency1Hz);

            c.RTC_StartTimer(rtc);
        }

        // Increment the seconds timer by one
        pub fn handle_isr(self: *@This()) void {
            const isr_flags = c.RTC_GetStatusFlags(rtc);

            @atomicStore(
                @TypeOf(self.val),
                &self.val,
                rtc.*.TSR,
                .seq_cst,
            );

            c.RTC_ClearStatusFlags(rtc, isr_flags);
        }
        // Get Unix timestamp
        pub inline fn get_timestamp(self: *@This()) u32 {
            _ = self;

            return rtc.*.TSR;
        }
        // Set timestamp, returns timestamp difference
        pub fn set_timestamp(self: *@This(), val: u32) u64 {
            _ = self;
            //_ = val;
            c.RTC_StopTimer(rtc);

            const prev_val = rtc.*.TSR;

            rtc.*.TSR = if (val != 0) val else 1;

            c.RTC_StartTimer(rtc);

            return @abs(@as(i64, @intCast(val)) - @as(i64, @intCast(prev_val)));
        }
    };
}
