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

pub const osError = core.osError;

const osFlagsErrorMap = core.osFlagsErrorMap;
const osErrorMap = core.osErrorMap;

pub const osThreadId_t = c.osThreadId_t;
pub const osThreadFunc_t = c.osThreadFunc_t;
pub const osThreadAttr_t = c.osThreadAttr_t;

const osThreadNew = c.osThreadNew;
const osThreadGetState = c.osThreadGetState;
const osThreadGetId = c.osThreadGetId;
const osThreadGetStackSize = c.osThreadGetStackSize;
const osThreadGetStackSpace = c.osThreadGetStackSpace;
const osThreadYield = c.osThreadYield;
const osThreadSuspend = c.osThreadSuspend;
const osThreadResume = c.osThreadResume;
const osThreadTerminate = c.osThreadTerminate;
const osThreadJoin = c.osThreadJoin;

const osThreadFlagsSet = c.osThreadFlagsSet;
const osThreadFlagsGet = c.osThreadFlagsGet;
const osThreadFlagsClear = c.osThreadFlagsClear;
const osThreadFlagsWait = c.osThreadFlagsWait;

const osThreadFeedWatchdog = c.osThreadFeedWatchdog;

pub const osThreadState = enum(i32) {
    osThreadInactive = c.osThreadInactive,
    osThreadReady = c.osThreadReady,
    osThreadRunning = c.osThreadRunning,
    osThreadBlocked = c.osThreadBlocked,
    osThreadTerminated = c.osThreadTerminated,
    osThreadError = c.osThreadError,
};

/// Thread priority values
pub const osThreadPriority = enum(i32) {
    osPriorityNone = c.osPriorityNone,
    osPriorityIdle = c.osPriorityIdle,
    osPriorityLow = c.osPriorityLow,
    osPriorityLow1 = c.osPriorityLow1,
    osPriorityLow2 = c.osPriorityLow2,
    osPriorityLow3 = c.osPriorityLow3,
    osPriorityLow4 = c.osPriorityLow4,
    osPriorityLow5 = c.osPriorityLow5,
    osPriorityLow6 = c.osPriorityLow6,
    osPriorityLow7 = c.osPriorityLow7,
    osPriorityBelowNormal = c.osPriorityBelowNormal,
    osPriorityBelowNormal1 = c.osPriorityBelowNormal1,
    osPriorityBelowNormal2 = c.osPriorityBelowNormal2,
    osPriorityBelowNormal3 = c.osPriorityBelowNormal3,
    osPriorityBelowNormal4 = c.osPriorityBelowNormal4,
    osPriorityBelowNormal5 = c.osPriorityBelowNormal5,
    osPriorityBelowNormal6 = c.osPriorityBelowNormal6,
    osPriorityBelowNormal7 = c.osPriorityBelowNormal7,
    osPriorityNormal = c.osPriorityNormal,
    osPriorityNormal1 = c.osPriorityNormal1,
    osPriorityNormal2 = c.osPriorityNormal2,
    osPriorityNormal3 = c.osPriorityNormal3,
    osPriorityNormal4 = c.osPriorityNormal4,
    osPriorityNormal5 = c.osPriorityNormal5,
    osPriorityNormal6 = c.osPriorityNormal6,
    osPriorityNormal7 = c.osPriorityNormal7,
    osPriorityAboveNormal = c.osPriorityAboveNormal,
    osPriorityAboveNormal1 = c.osPriorityAboveNormal1,
    osPriorityAboveNormal2 = c.osPriorityAboveNormal2,
    osPriorityAboveNormal3 = c.osPriorityAboveNormal3,
    osPriorityAboveNormal4 = c.osPriorityAboveNormal4,
    osPriorityAboveNormal5 = c.osPriorityAboveNormal5,
    osPriorityAboveNormal6 = c.osPriorityAboveNormal6,
    osPriorityAboveNormal7 = c.osPriorityAboveNormal7,
    osPriorityHigh = c.osPriorityHigh,
    osPriorityHigh1 = c.osPriorityHigh1,
    osPriorityHigh2 = c.osPriorityHigh2,
    osPriorityHigh3 = c.osPriorityHigh3,
    osPriorityHigh4 = c.osPriorityHigh4,
    osPriorityHigh5 = c.osPriorityHigh5,
    osPriorityHigh6 = c.osPriorityHigh6,
    osPriorityHigh7 = c.osPriorityHigh7,
    osPriorityRealtime = c.osPriorityRealtime,
    osPriorityRealtime1 = c.osPriorityRealtime1,
    osPriorityRealtime2 = c.osPriorityRealtime2,
    osPriorityRealtime3 = c.osPriorityRealtime3,
    osPriorityRealtime4 = c.osPriorityRealtime4,
    osPriorityRealtime5 = c.osPriorityRealtime5,
    osPriorityRealtime6 = c.osPriorityRealtime6,
    osPriorityRealtime7 = c.osPriorityRealtime7,
    osPriorityISR = c.osPriorityISR,
    osPriorityError = c.osPriorityError,
    osPriorityReserved = c.osPriorityReserved,
};

const thread = @This();

id: osThreadId_t = undefined,

pub fn default() @This() {
    return .{ .id = undefined };
}

pub fn getThreadId() @This() {
    return .{ .id = osThreadGetId() };
}

/// Creates a Thread object using an existing ThreadId reference
pub fn create(id: osThreadId_t) !@This() {
    return if (id == null) osError.osError else .{ .id = id };
}

/// Creates a new Thread
pub inline fn new(func: osThreadFunc_t, argument: ?*anyopaque, attr: *const osThreadAttr_t) !@This() {
    return @This().create(osThreadNew(func, argument, attr));
}

/// Get thread state
pub inline fn getState(self: *const @This()) osThreadState {
    return @as(osThreadState, @enumFromInt(osThreadGetState(self.id)));
}

/// Get thread stack size
pub inline fn getStackSize(self: *const @This()) usize {
    return @intCast(osThreadGetStackSize(self.id));
}

/// Get thread stack space
pub inline fn getStackSpace(self: *const @This()) usize {
    return @intCast(osThreadGetStackSpace(self.id));
}

/// Yield own thread execution.
pub inline fn yield() osError!void {
    return osErrorMap(osThreadYield());
}

/// Suspend thread execution
pub inline fn threadSuspend(self: *const @This()) osError!void {
    return osErrorMap(osThreadSuspend(self.id));
}

/// Resume thread execution
pub inline fn threadResume(self: *const @This()) osError!void {
    return osErrorMap(osThreadResume(self.id));
}

pub inline fn threadTerminate(self: *const @This()) osError!void {
    return osErrorMap(osThreadTerminate(self.id));
}

/// Set flags for a specific thread
pub inline fn flagsSet(self: *const @This(), flags: u32) osError!u32 {
    return osFlagsErrorMap(osThreadFlagsSet(self.id, flags));
}

/// Clear flags in current thread
pub inline fn flagsClear(flags: u32) osError!u32 {
    return osFlagsErrorMap(osThreadFlagsClear(flags));
}

/// Get current thread flags
pub inline fn flagsGet() osError!u32 {
    return osFlagsErrorMap(osThreadFlagsGet());
}

/// Wait for current flags
pub inline fn flagsWait(flags: u32, options: u32, timeout: u32) osError!u32 {
    return osFlagsErrorMap(osThreadFlagsWait(flags, options, timeout));
}

pub inline fn feedWatchdog(ticks: u32) osError!void {
    return osErrorMap(osThreadFeedWatchdog(ticks));
}

/// Static thread
pub fn StaticThread(
    comptime T: type,
    comptime stack_size: usize,
    comptime name: [*:0]const u8,
    comptime taskRunnerFn: *const fn (?*T) void,
) type {
    return struct {
        /// ThreadId
        thread: thread = undefined,

        /// Control Block, 32-Bit alignment needed
        cb: c.osRtxThread_t align(4) = undefined,

        /// Static task, 64-Bit alignment needed
        stack: [stack_size]u8 align(8) = undefined,

        pub fn default() @This() {
            return .{
                .thread = thread.default(),
                .cb = undefined,
                .stack = undefined,
            };
        }

        /// Thread runner
        fn run(arg: ?*anyopaque) callconv(.c) void {
            taskRunnerFn(@as(?*T, @ptrCast(@alignCast(arg))));
        }

        pub fn new(self: *@This(), arg: ?*T, attrs: u32, priority: thread.osThreadPriority) osError!void {

            // Thread attributes
            const attr: c.osThreadAttr_t = .{
                .name = name,
                .attr_bits = attrs,
                .cb_mem = &self.cb,
                .cb_size = @sizeOf(c.osRtxThread_t),
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
        pub fn flagsSet(self: *const @This(), flags: u32) osError!u32 {
            return self.thread.flagsSet(flags);
        }
        pub fn feedWatchdog(_: *const @This(), ticks: u32) osError!void {
            return thread.feedWatchdog(ticks);
        }
        pub fn flagsClear(_: *const @This(), flags: u32) osError!void {
            return thread.flagsClear(flags);
        }
        pub fn flagsGet(_: *const @This()) osError!u32 {
            return thread.flagsGet();
        }
        pub fn flagsWait(_: *const @This(), flags: u32, options: u32, timeout: u32) osError!u32 {
            return thread.flagsWait(flags, options, timeout);
        }
        pub fn yield(_: *const @This()) osError!void {
            return thread.yield();
        }
    };
}
