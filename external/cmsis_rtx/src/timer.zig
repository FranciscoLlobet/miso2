/// Copyright 2025 Francisco Llobet-Blandino
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
const core = @import("core.zig");
const c_rtx = core.c_rtx;

pub const osError = core.osError;
const osErrorMap = core.osErrorMap;

pub const osTimerFunc_t = c_rtx.osTimerFunc_t;
pub const osTimerAttr_t = c_rtx.osTimerAttr_t;
pub const osTimerId_t = c_rtx.osTimerId_t;
pub const osRtxTimer_t = c_rtx.osRtxTimer_t;

pub const osTimerType = enum(u32) {
    osTimerOnce = c_rtx.osTimerOnce,
    osTimerPeriodic = c_rtx.osTimerPeriodic,
};

const timer = @This();

id: osTimerId_t = undefined,

/// Creates a Timer object using an existing TimerId reference
pub fn create(id: osTimerId_t) @This() {
    return .{ .id = id };
}

/// Creates a new Timer
pub fn new(func: osTimerFunc_t, timer_type: osTimerType, argument: ?*anyopaque, attr: ?*const osTimerAttr_t) @This() {
    return @This().create(c_rtx.osTimerNew(func, @intFromEnum(timer_type), argument, attr));
}

/// Get timer name
pub fn getName(self: *const @This()) ?[*:0]const u8 {
    return c_rtx.osTimerGetName(self.id);
}

/// Start or restart the timer
pub fn start(self: *const @This(), ticks: u32) osError!void {
    return osErrorMap(c_rtx.osTimerStart(self.id, ticks));
}

/// Stop the timer
pub fn stop(self: *const @This()) osError!void {
    return osErrorMap(c_rtx.osTimerStop(self.id));
}

/// Check if timer is running
pub fn isRunning(self: *const @This()) bool {
    return c_rtx.osTimerIsRunning(self.id) != 0;
}

/// Delete the timer
pub fn delete(self: *const @This()) osError!void {
    return osErrorMap(c_rtx.osTimerDelete(self.id));
}

/// Static timer with compile-time control block allocation
pub fn StaticTimer(comptime T: type, comptime name: [*:0]const u8, comptime timerCallbackFn: *const fn (?*T) void) type {
    return struct {
        /// Timer object
        tim: timer = undefined,

        /// Control Block, 32-Bit alignment needed
        cb: osRtxTimer_t align(4) = undefined,

        fn callback(arg: ?*anyopaque) callconv(.c) void {
            timerCallbackFn(@as(?*T, @ptrCast(@alignCast(arg))));
        }

        /// Create new static timer
        pub fn new(self: *@This(), timer_type: osTimerType, arg: ?*T, attr_bits: u32) osError!void {
            // Timer attributes
            const attr: osTimerAttr_t = .{
                .name = name,
                .attr_bits = attr_bits,
                .cb_mem = &self.cb,
                .cb_size = @sizeOf(osRtxTimer_t),
            };

            self.tim = timer.new(callback, timer_type, @ptrCast(@alignCast(arg)), &attr);

            // Check if timer creation failed
            if (self.tim.id == null) {
                return osError.osError;
            }
        }

        /// Get timer reference
        pub fn getTimerRef(self: *const @This()) *const timer {
            return &self.tim;
        }

        /// Get timer name
        pub fn getName(self: *const @This()) ?[*:0]const u8 {
            return self.tim.getName();
        }

        /// Start or restart the timer
        pub fn start(self: *const @This(), ticks: u32) osError!void {
            return self.tim.start(ticks);
        }

        /// Stop the timer
        pub fn stop(self: *const @This()) osError!void {
            return self.tim.stop();
        }

        /// Check if timer is running
        pub fn isRunning(self: *const @This()) bool {
            return self.tim.isRunning();
        }

        /// Delete the timer
        pub fn delete(self: *const @This()) osError!void {
            return self.tim.delete();
        }
    };
}
