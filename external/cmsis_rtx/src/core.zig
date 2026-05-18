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
pub const c_rtx = @import("c.zig").c_rtx;

// Error type for OS errors
pub const osError = error{
    osError,
    osErrorTimeout,
    osErrorResource,
    osErrorParameter,
    osErrorNoMemory,
    osErrorISR,
    osErrorSafetyClass,
};

// Error type for OS flags
pub const osFlagsError = error{
    osFlagsErrorUnknown,
    osFlagsErrorTimeout,
    osFlagsErrorResource,
    osFlagsErrorParameter,
    osFlagsErrorISR,
    osFlagsErrorSafetyClass,
};

// All basic types that multiple modules need
pub const osStatus_t = c_rtx.osStatus_t;
pub const osThreadId_t = c_rtx.osThreadId_t;
pub const osTimerId_t = c_rtx.osTimerId_t;
pub const osEventFlagsId_t = c_rtx.osEventFlagsId_t;
pub const osSemaphoreId_t = c_rtx.osSemaphoreId_t;
pub const osMutexId_t = c_rtx.osMutexId_t;
pub const osMessageQueueId_t = c_rtx.osMessageQueueId_t;

// Wait forever
pub const osWaitForever: u32 = @intCast(c_rtx.osWaitForever);

// Flag options
pub const osFlagsOptions = enum(u32) {
    osFlagsWaitAny = c_rtx.osFlagsWaitAny,
    osFlagsWaitAll = c_rtx.osFlagsWaitAll,
    osFlagsNoClear = c_rtx.osFlagsNoClear,
};

// Map `osStatus` codes to zig errors
pub fn osErrorMap(osStatus: osStatus_t) osError!void {
    return switch (osStatus) {
        c_rtx.osOK => {},
        c_rtx.osError => osError.osError,
        c_rtx.osErrorISR => osError.osErrorISR,
        c_rtx.osErrorTimeout => osError.osErrorTimeout,
        c_rtx.osErrorResource => osError.osErrorResource,
        c_rtx.osErrorParameter => osError.osErrorParameter,
        c_rtx.osErrorNoMemory => osError.osErrorNoMemory,
        c_rtx.osErrorSafetyClass => osError.osErrorSafetyClass,
        else => osError.osError,
    };
}

// Map return codes into errors
pub fn osFlagsErrorMap(ef: u32) osFlagsError!u32 {
    if (@as(u32, @intCast(c_rtx.osFlagsError & ef)) == @as(u32, @intCast(c_rtx.osFlagsError))) {
        return switch (ef) {
            c_rtx.osFlagsErrorUnknown => osFlagsError.osFlagsErrorUnknown,
            c_rtx.osFlagsErrorTimeout => osFlagsError.osFlagsErrorTimeout,
            c_rtx.osFlagsErrorResource => osFlagsError.osFlagsErrorResource,
            c_rtx.osFlagsErrorParameter => osFlagsError.osFlagsErrorParameter,
            c_rtx.osFlagsErrorISR => osFlagsError.osFlagsErrorISR,
            c_rtx.osFlagsErrorSafetyClass => osFlagsError.osFlagsErrorSafetyClass,
            else => osFlagsError.osFlagsErrorUnknown,
        };
    } else {
        return ef;
    }
}
