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
const osErrorMap = core.osErrorMap;

pub const osSemaphoreAttr_t = c_rtx.osSemaphoreAttr_t;
pub const osSemaphoreId_t = c_rtx.osSemaphoreId_t;
pub const osRtxSemaphore_t = c_rtx.osRtxSemaphore_t;

const semaphore = @This();

id: osSemaphoreId_t = undefined,

/// Creates a Semaphore object using an existing SemaphoreId reference
pub fn create(id: osSemaphoreId_t) @This() {
    return .{ .id = id };
}

/// Creates a new Semaphore
pub fn new(max_count: u32, initial_count: u32, attr: ?*const osSemaphoreAttr_t) @This() {
    return @This().create(c_rtx.osSemaphoreNew(max_count, initial_count, attr));
}

/// Get semaphore name
pub fn getName(self: *const @This()) ?[*:0]const u8 {
    return c_rtx.osSemaphoreGetName(self.id);
}

/// Acquire a semaphore token or timeout if no tokens are available
pub fn acquire(self: *const @This(), timeout: u32) osError!void {
    return osErrorMap(c_rtx.osSemaphoreAcquire(self.id, timeout));
}

/// Release a semaphore token up to the initial maximum count
pub fn release(self: *const @This()) osError!void {
    return osErrorMap(c_rtx.osSemaphoreRelease(self.id));
}

/// Get current semaphore token count
pub fn getCount(self: *const @This()) u32 {
    return c_rtx.osSemaphoreGetCount(self.id);
}

/// Delete the semaphore
pub fn delete(self: *const @This()) osError!void {
    return osErrorMap(c_rtx.osSemaphoreDelete(self.id));
}

/// Static semaphore with compile-time control block allocation
pub fn StaticSemaphore(comptime name: [*:0]const u8) type {
    return struct {
        /// Semaphore object
        sem: semaphore = undefined,

        /// Control Block, 32-Bit alignment needed
        cb: osRtxSemaphore_t align(4) = undefined,

        /// Create new static semaphore
        pub fn new(self: *@This(), max_count: u32, initial_count: u32, attr_bits: u32) osError!void {
            // Semaphore attributes
            const attr: c_rtx.osSemaphoreAttr_t = .{
                .name = name,
                .attr_bits = attr_bits,
                .cb_mem = &self.cb,
                .cb_size = @sizeOf(osRtxSemaphore_t),
            };

            self.sem = semaphore.new(max_count, initial_count, &attr);

            // Check if semaphore creation failed
            if (self.sem.id == null) {
                return osError.osError;
            }
        }

        /// Get semaphore reference
        pub fn getSemaphoreRef(self: *const @This()) *const semaphore {
            return &self.sem;
        }

        /// Get semaphore name
        pub fn getName(self: *const @This()) ?[*:0]const u8 {
            return self.sem.getName();
        }

        /// Acquire a semaphore token or timeout if no tokens are available
        pub fn acquire(self: *const @This(), timeout: u32) osError!void {
            return self.sem.acquire(timeout);
        }

        /// Release a semaphore token up to the initial maximum count
        pub fn release(self: *const @This()) osError!void {
            return self.sem.release();
        }

        /// Get current semaphore token count
        pub fn getCount(self: *const @This()) u32 {
            return self.sem.getCount();
        }

        /// Delete the semaphore
        pub fn delete(self: *const @This()) osError!void {
            return self.sem.delete();
        }
    };
}
