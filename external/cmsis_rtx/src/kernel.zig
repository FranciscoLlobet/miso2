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
const core = @import("core.zig");
const c = core.c;
const messageQueue = @import("messageQueue.zig");

pub const osError = core.osError;

const osErrorMap = core.osErrorMap;

/// Kernel states
pub const osKernelState = enum(i32) {
    osKernelInactive = c.osKernelInactive,
    osKernelReady = c.osKernelReady,
    osKernelRunning = c.osKernelRunning,
    osKernelLocked = c.osKernelLocked,
    osKernelSuspended = c.osKernelSuspended,
    osKernelError = c.osKernelError,
};

// Kernel instance
pub fn Kernel(
    comptime IdleThread: *const fn (in: ?*anyopaque) noreturn,
    comptime ErrorNotify: *const fn (code: osError, object_id: ?*anyopaque) noreturn,
) type {
    return struct {
        /// Initialize RTX kernel
        pub fn initialize(_: *@This()) osError!void {
            return osErrorMap(c.osKernelInitialize());
        }
        /// Start the RTX kernel
        pub fn start(_: *@This()) osError!void {
            return osErrorMap(c.osKernelStart());
        }
        /// Get Kernel tick count
        pub fn getTickCount(_: *@This()) u32 {
            return c.osKernelGetTickCount();
        }

        pub fn getSysTimerFreq(_: *@This()) u32 {
            return c.osKernelGetSysTimerFreq();
        }

        pub fn getState(_: *@This()) osKernelState {
            return @enumFromInt(c.osKernelGetState());
        }

        pub fn kernelSuspend(_: *@This()) u32 {
            return c.osKernelSuspend();
        }

        pub fn kernelResume(_: *@This(), ticks: u32) void {
            return c.osKernelResume(ticks);
        }

        export fn osRtxErrorNotify(code: u32, object_id: ?*anyopaque) callconv(.c) u32 {
            ErrorNotify(core.osErrorMapAsError(@intCast(code)), object_id);

            return 0;
        }

        export fn osRtxIdleThread(in: ?*anyopaque) callconv(.c) noreturn {
            IdleThread(in);
        }
    };
}

pub const osTimerFunc_t = c.osTimerFunc_t;

/// Access to RTX internals not exposed by the public CMSIS-RTOS2 API.
pub const Hacks = struct {
    pub fn osKernelTimer(T: type) type {
        return struct {
            pub fn send(func: *const fn (arg: *T) callconv(.c) void, arg: *T) osError!void {
                const mq = messageQueue.MessageQueue(c.osRtxTimerFinfo_t).create(
                    @ptrCast(c.osRtxInfo.timer.mq),
                );

                const finfo: c.osRtxTimerFinfo_t = .{
                    .func = @ptrCast(func),
                    .arg = @ptrCast(arg),
                };

                try mq.put(&finfo, 0, core.osWaitNever);
            }
        };
    }
};
