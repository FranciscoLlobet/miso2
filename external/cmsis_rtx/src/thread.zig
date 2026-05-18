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
const c_rtx = core.c_rtx;

pub const osError = core.osError;
pub const osFlagsError = core.osFlagsError;

const osErrorMap = core.osErrorMap;
const osFlagsErrorMap = core.osFlagsErrorMap;

pub const osThreadId_t = c_rtx.osThreadId_t;
pub const osThreadFunc_t = c_rtx.osThreadFunc_t;
pub const osThreadAttr_t = c_rtx.osThreadAttr_t;

const osThreadNew = c_rtx.osThreadNew;
const osThreadGetState = c_rtx.osThreadGetState;
const osThreadGetId = c_rtx.osThreadGetId;
const osThreadGetStackSize = c_rtx.osThreadGetStackSize;
const osThreadGetStackSpace = c_rtx.osThreadGetStackSpace;
const osThreadYield = c_rtx.osThreadYield;
const osThreadSuspend = c_rtx.osThreadSuspend;
const osThreadResume = c_rtx.osThreadResume;
const osThreadTerminate = c_rtx.osThreadTerminate;
const osThreadJoin = c_rtx.osThreadJoin;

const osThreadFlagsSet = c_rtx.osThreadFlagsSet;
const osThreadFlagsGet = c_rtx.osThreadFlagsGet;
const osThreadFlagsClear = c_rtx.osThreadFlagsClear;
const osThreadFlagsWait = c_rtx.osThreadFlagsWait;

pub const osThreadState = enum(i32) {
    osThreadInactive = c_rtx.osThreadInactive,
    osThreadReady = c_rtx.osThreadReady,
    osThreadRunning = c_rtx.osThreadRunning,
    osThreadBlocked = c_rtx.osThreadBlocked,
    osThreadTerminated = c_rtx.osThreadTerminated,
    osThreadError = c_rtx.osThreadError,
};

/// Thread priority values
pub const osThreadPriority = enum(i32) {
    osPriorityNone = c_rtx.osPriorityNone,
    osPriorityIdle = c_rtx.osPriorityIdle,
    osPriorityLow = c_rtx.osPriorityLow,
    osPriorityLow1 = c_rtx.osPriorityLow1,
    osPriorityLow2 = c_rtx.osPriorityLow2,
    osPriorityLow3 = c_rtx.osPriorityLow3,
    osPriorityLow4 = c_rtx.osPriorityLow4,
    osPriorityLow5 = c_rtx.osPriorityLow5,
    osPriorityLow6 = c_rtx.osPriorityLow6,
    osPriorityLow7 = c_rtx.osPriorityLow7,
    osPriorityBelowNormal = c_rtx.osPriorityBelowNormal,
    osPriorityBelowNormal1 = c_rtx.osPriorityBelowNormal1,
    osPriorityBelowNormal2 = c_rtx.osPriorityBelowNormal2,
    osPriorityBelowNormal3 = c_rtx.osPriorityBelowNormal3,
    osPriorityBelowNormal4 = c_rtx.osPriorityBelowNormal4,
    osPriorityBelowNormal5 = c_rtx.osPriorityBelowNormal5,
    osPriorityBelowNormal6 = c_rtx.osPriorityBelowNormal6,
    osPriorityBelowNormal7 = c_rtx.osPriorityBelowNormal7,
    osPriorityNormal = c_rtx.osPriorityNormal,
    osPriorityNormal1 = c_rtx.osPriorityNormal1,
    osPriorityNormal2 = c_rtx.osPriorityNormal2,
    osPriorityNormal3 = c_rtx.osPriorityNormal3,
    osPriorityNormal4 = c_rtx.osPriorityNormal4,
    osPriorityNormal5 = c_rtx.osPriorityNormal5,
    osPriorityNormal6 = c_rtx.osPriorityNormal6,
    osPriorityNormal7 = c_rtx.osPriorityNormal7,
    osPriorityAboveNormal = c_rtx.osPriorityAboveNormal,
    osPriorityAboveNormal1 = c_rtx.osPriorityAboveNormal1,
    osPriorityAboveNormal2 = c_rtx.osPriorityAboveNormal2,
    osPriorityAboveNormal3 = c_rtx.osPriorityAboveNormal3,
    osPriorityAboveNormal4 = c_rtx.osPriorityAboveNormal4,
    osPriorityAboveNormal5 = c_rtx.osPriorityAboveNormal5,
    osPriorityAboveNormal6 = c_rtx.osPriorityAboveNormal6,
    osPriorityAboveNormal7 = c_rtx.osPriorityAboveNormal7,
    osPriorityHigh = c_rtx.osPriorityHigh,
    osPriorityHigh1 = c_rtx.osPriorityHigh1,
    osPriorityHigh2 = c_rtx.osPriorityHigh2,
    osPriorityHigh3 = c_rtx.osPriorityHigh3,
    osPriorityHigh4 = c_rtx.osPriorityHigh4,
    osPriorityHigh5 = c_rtx.osPriorityHigh5,
    osPriorityHigh6 = c_rtx.osPriorityHigh6,
    osPriorityHigh7 = c_rtx.osPriorityHigh7,
    osPriorityRealtime = c_rtx.osPriorityRealtime,
    osPriorityRealtime1 = c_rtx.osPriorityRealtime1,
    osPriorityRealtime2 = c_rtx.osPriorityRealtime2,
    osPriorityRealtime3 = c_rtx.osPriorityRealtime3,
    osPriorityRealtime4 = c_rtx.osPriorityRealtime4,
    osPriorityRealtime5 = c_rtx.osPriorityRealtime5,
    osPriorityRealtime6 = c_rtx.osPriorityRealtime6,
    osPriorityRealtime7 = c_rtx.osPriorityRealtime7,
    osPriorityISR = c_rtx.osPriorityISR,
    osPriorityError = c_rtx.osPriorityError,
    osPriorityReserved = c_rtx.osPriorityReserved,
};

const thread = @This();

id: osThreadId_t = undefined,

pub fn getThreadId() @This() {
    return .{ .id = osThreadGetId() };
}

/// Creates a Thread object using an existing ThreadId reference
pub fn create(id: osThreadId_t) !@This() {
    return if (id == null) osError.osError else .{ .id = id };
}

/// Creates a new Thread
pub fn new(func: osThreadFunc_t, argument: ?*anyopaque, attr: *const osThreadAttr_t) !@This() {
    return @This().create(osThreadNew(func, argument, attr));
}

/// Get thread state
pub fn getState(self: *const @This()) osThreadState {
    return @as(osThreadState, @enumFromInt(osThreadGetState(self.id)));
}

/// Get thread stack size
pub fn getStackSize(self: *const @This()) usize {
    return @intCast(osThreadGetStackSize(self.id));
}

/// Get thread stack space
pub fn getStackSpace(self: *const @This()) usize {
    return @intCast(osThreadGetStackSpace(self.id));
}

/// Yield own thread execution.
pub fn yield() osError!void {
    return osErrorMap(osThreadYield());
}

/// Suspend thread execution
pub fn threadSuspend(self: *const @This()) osError!void {
    return osErrorMap(osThreadSuspend(self.id));
}

/// Resume thread execution
pub fn threadResume(self: *const @This()) osError!void {
    return osErrorMap(osThreadResume(self.id));
}

pub fn threadTerminate(self: *const @This()) osError!void {
    return osErrorMap(osThreadTerminate(self.id));
}

/// Set flags for a specific thread
pub fn flagsSet(self: *const @This(), flags: u32) osFlagsError!u32 {
    return osFlagsErrorMap(osThreadFlagsSet(self.id, flags));
}

/// Clear flags in current thread
pub fn flagsClear(flags: u32) osFlagsError!u32 {
    return osFlagsErrorMap(osThreadFlagsClear(flags));
}

/// Get current thread flags
pub fn flagsGet() osFlagsError!u32 {
    return osFlagsErrorMap(osThreadFlagsGet());
}

/// Wait for current flags
pub fn flagsWait(flags: u32, options: u32, timeout: u32) osFlagsError!u32 {
    return osFlagsErrorMap(osThreadFlagsWait(flags, options, timeout));
}

/// Static thread
pub fn StaticThread(comptime T: type, comptime stack_size: usize, comptime name: [*:0]const u8, comptime taskRunnerFn: *const fn (?*T) void) type {
    return struct {
        /// ThreadId
        thread: thread = undefined,

        /// Control Block, 32-Bit alignment needed
        cb: c_rtx.osRtxThread_t align(4) = undefined,

        /// Static task, 64-Bit alignment needed
        stack: [stack_size]u8 align(8) = undefined,

        /// Thread runner
        fn run(arg: ?*anyopaque) callconv(.c) void {
            taskRunnerFn(@as(?*T, @ptrCast(@alignCast(arg))));
        }

        pub fn new(self: *@This(), arg: ?*T, attrs: u32, priority: thread.osThreadPriority) osError!void {

            // Thread attributes
            const attr: c_rtx.osThreadAttr_t = .{
                .name = name,
                .attr_bits = attrs,
                .cb_mem = &self.cb,
                .cb_size = @sizeOf(c_rtx.osRtxThread_t),
                .stack_mem = self.stack[0..].ptr,
                .stack_size = self.stack[0..].len,
                .priority = @intFromEnum(priority),
                .tz_module = undefined,
                .affinity_mask = 0,
            };

            self.thread = try thread.new(run, @ptrCast(@alignCast(arg)), &attr);
        }

        pub fn getThreadRef(self: *const @This()) *thread {
            return &self.thread;
        }
        pub fn getState(self: *const @This()) osThreadState {
            return self.thread.getState();
        }
        pub fn getStackSize(self: *const @This()) usize {
            return self.thread.getStackSize();
        }
        pub fn getStackSpace(self: *const @This()) usize {
            return self.thread.getStackSpace();
        }
        pub fn threadSuspend(self: *const @This()) osError!void {
            return self.thread.threadSuspend();
        }
        pub fn threadResume(self: *const @This()) osError!void {
            return self.thread.threadResume();
        }
        pub fn flagsSet(self: *const @This(), flags: u32) osFlagsError!u32 {
            return self.thread.flagsSet(flags);
        }
    };
}
