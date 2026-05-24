// Copyright 2025 Francisco Llobet-Blandino
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
pub const c = @import("c.zig").c;

// Error type for OS errors
pub const osError = error{
    osError,
    osErrorTimeout,
    osErrorResource,
    osErrorParameter,
    osErrorNoMemory,
    osErrorISR,
    osErrorSafetyClass,
    osRtxErrorStackOverflow,
    osRtxErrorISRQueueOverflow,
    osRtxErrorTimerQueueOverflow,
    osRtxErrorClibSpace,
    osRtxErrorClibMutex,
    osRtxErrorSVC,

    osErrorUnknown,
};

pub const osTick = u32;

// All basic types that multiple modules need
pub const osStatus_t = c.osStatus_t;
pub const osThreadId_t = c.osThreadId_t;
pub const osTimerId_t = c.osTimerId_t;
pub const osEventFlagsId_t = c.osEventFlagsId_t;
pub const osSemaphoreId_t = c.osSemaphoreId_t;
pub const osMutexId_t = c.osMutexId_t;
pub const osMessageQueueId_t = c.osMessageQueueId_t;

// Wait forever
pub const osWaitForever: osTick = @intCast(c.osWaitForever);
pub const osWaitNever: osTick = 0;

// Flag options
pub const osFlagsOptions = enum(u32) {
    osFlagsWaitAny = c.osFlagsWaitAny,
    osFlagsWaitAll = c.osFlagsWaitAll,
    osFlagsNoClear = c.osFlagsNoClear,
};

// Map `osStatus` codes to zig errors
pub inline fn osErrorMap(osStatus: osStatus_t) osError!void {
    return switch (osStatus) {
        c.osOK => {},

        c.osError => osError.osError,
        c.osErrorISR => osError.osErrorISR,
        c.osErrorTimeout => osError.osErrorTimeout,
        c.osErrorResource => osError.osErrorResource,
        c.osErrorParameter => osError.osErrorParameter,
        c.osErrorNoMemory => osError.osErrorNoMemory,
        c.osErrorSafetyClass => osError.osErrorSafetyClass,

        c.osRtxErrorStackOverflow => osError.osRtxErrorStackOverflow,
        c.osRtxErrorISRQueueOverflow => osError.osRtxErrorISRQueueOverflow,
        c.osRtxErrorTimerQueueOverflow => osError.osRtxErrorTimerQueueOverflow,
        c.osRtxErrorClibSpace => osError.osRtxErrorClibSpace,
        c.osRtxErrorClibMutex => osError.osRtxErrorClibMutex,
        c.osRtxErrorSVC => osError.osRtxErrorSVC,

        else => osError.osErrorUnknown,
    };
}

pub inline fn osErrorMapAsError(osStatus: osStatus_t) osError {
    osErrorMap(osStatus) catch |err| return err;

    unreachable;
}

// Map return codes into errors
pub fn osFlagsErrorMap(ef: u32) osError!u32 {
    if (@as(u32, @intCast(c.osFlagsError & ef)) == @as(u32, @intCast(c.osFlagsError))) {
        return switch (ef) {
            c.osFlagsErrorUnknown => osError.osErrorUnknown,
            c.osFlagsErrorTimeout => osError.osErrorTimeout,
            c.osFlagsErrorResource => osError.osErrorResource,
            c.osFlagsErrorParameter => osError.osErrorParameter,
            c.osFlagsErrorISR => osError.osErrorISR,
            c.osFlagsErrorSafetyClass => osError.osErrorSafetyClass,
            else => osError.osErrorUnknown,
        };
    } else {
        return ef;
    }
}
