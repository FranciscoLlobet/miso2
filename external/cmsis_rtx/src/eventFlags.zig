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

// Import shared types and functions
pub const osError = core.osError;
pub const osFlagsError = core.osFlagsError;

const osErrorMap = core.osErrorMap;
const osFlagsErrorMap = core.osFlagsErrorMap;

// Local constants
pub const osFlagsWaitAny = c_rtx.osFlagsWaitAny;
pub const osFlagsWaitAll = c_rtx.osFlagsWaitAll;
pub const osFlagsNoClear = c_rtx.osFlagsNoClear;

// Types
pub const osEventFlagsAttr_t = c_rtx.osEventFlagsAttr_t;
pub const osEventFlagsId_t = c_rtx.osEventFlagsId_t;
pub const osRtxEventFlags_t = c_rtx.osRtxEventFlags_t;

const eventFlags = @This();

id: osEventFlagsId_t = undefined,

/// Creates an EventFlags object using an existing EventFlagsId reference
pub fn create(id: osEventFlagsId_t) @This() {
    return .{ .id = id };
}

/// Creates a new EventFlags object
pub fn new(attr: ?*const osEventFlagsAttr_t) @This() {
    return @This().create(c_rtx.osEventFlagsNew(attr));
}

/// Get event flags name
pub fn getName(self: *const @This()) ?[*:0]const u8 {
    return c_rtx.osEventFlagsGetName(self.id);
}

/// Set specified event flags
pub fn set(self: *const @This(), flags: u32) osFlagsError!u32 {
    return osFlagsErrorMap(c_rtx.osEventFlagsSet(self.id, flags));
}

/// Clear specified event flags
pub fn clear(self: *const @This(), flags: u32) osFlagsError!u32 {
    return osFlagsErrorMap(c_rtx.osEventFlagsClear(self.id, flags));
}

/// Get current event flags
pub fn get(self: *const @This()) osFlagsError!u32 {
    return osFlagsErrorMap(c_rtx.osEventFlagsGet(self.id));
}

/// Wait for one or more event flags to become signaled
pub fn wait(self: *const @This(), flags: u32, options: u32, timeout: u32) osFlagsError!u32 {
    return osFlagsErrorMap(c_rtx.osEventFlagsWait(self.id, flags, options, timeout));
}

/// Delete the event flags object
pub fn delete(self: *const @This()) osError!void {
    return osErrorMap(c_rtx.osEventFlagsDelete(self.id));
}

/// Static event flags with compile-time control block allocation
pub fn StaticEventFlags(comptime name: [*:0]const u8) type {
    return struct {
        /// EventFlags object
        ef: eventFlags = undefined,

        /// Control Block, 32-Bit alignment needed
        cb: osRtxEventFlags_t align(4) = undefined,

        /// Create new static event flags
        pub fn new(self: *@This(), attr_bits: u32) osError!void {
            // EventFlags attributes
            const attr: c_rtx.osEventFlagsAttr_t = .{
                .name = name,
                .attr_bits = attr_bits,
                .cb_mem = &self.cb,
                .cb_size = @sizeOf(osRtxEventFlags_t),
            };

            self.ef = eventFlags.new(&attr);

            // Check if event flags creation failed
            if (self.ef.id == null) {
                return osError.osError;
            }
        }

        /// Get event flags reference
        pub fn getEventFlagsRef(self: *const @This()) *const eventFlags {
            return &self.ef;
        }

        /// Get event flags name
        pub fn getName(self: *const @This()) ?[*:0]const u8 {
            return self.ef.getName();
        }

        /// Set specified event flags
        pub fn set(self: *const @This(), flags: u32) osFlagsError!u32 {
            return self.ef.set(flags);
        }

        /// Clear specified event flags
        pub fn clear(self: *const @This(), flags: u32) osFlagsError!u32 {
            return self.ef.clear(flags);
        }

        /// Get current event flags
        pub fn get(self: *const @This()) osFlagsError!u32 {
            return self.ef.get();
        }

        /// Wait for one or more event flags to become signaled
        pub fn wait(self: *const @This(), flags: u32, options: u32, timeout: u32) osFlagsError!u32 {
            return self.ef.wait(flags, options, timeout);
        }

        /// Delete the event flags object
        pub fn delete(self: *const @This()) osError!void {
            return self.ef.delete();
        }
    };
}
