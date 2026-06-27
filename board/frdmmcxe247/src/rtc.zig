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
    comptime rtc: *c.RTC_Type,
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
            // c.EnableIRQ goes through __NVIC_EnableIRQ, which zig's
            // translate-c can't translate (it uses inline asm for
            // __COMPILER_BARRIER), leaving an undefined extern symbol.
            // Enable the IRQ directly via the NVIC register instead.
            nvicEnableIRQ(c.RTC_SECONDS_IRQN);

            c.RTC_StartTimer(rtc);
        }

        // Increment the seconds timer by one
        pub inline fn handle_isr(self: *@This()) void {
            const isr_flags = c.RTC_GetStatusFlags(rtc);

            @atomicStore(
                @TypeOf(self.val),
                &self.val,
                1 + @atomicLoad(
                    @TypeOf(self.val),
                    &self.val,
                    .seq_cst,
                ),
                .seq_cst,
            );

            c.RTC_ClearStatusFlags(rtc, isr_flags);
        }
        // Get Unix timestamp
        pub inline fn get_timestamp(self: *@This()) u32 {
            _ = self;
            //return @atomicLoad(
            //    @TypeOf(self.val),
            //    &self.val,
            //    .seq_cst,
            //);
            return rtc.TSR;
        }
        // Set timestamp, returns timestamp difference
        pub fn set_timestamp(self: *@This(), val: u32) u64 {
            _ = self;
            c.RTC_StopTimer(rtc);

            const prev_val = rtc.TSR;

            rtc.TSR = val;

            c.RTC_StartTimer(rtc);

            return @abs(@as(i64, @intCast(val)) - @as(i64, @intCast(prev_val)));
        }
    };
}
