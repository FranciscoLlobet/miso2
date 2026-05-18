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
const c_rtx = @import("c.zig").c_rtx;
const core = @import("core.zig");

pub const osError = core.osError;
const osErrorMap = core.osErrorMap;

pub const osMessageQueueAttr_t = c_rtx.osMessageQueueAttr_t;
pub const osMessageQueueId_t = c_rtx.osMessageQueueId_t;

fn messageQueueMemSize(comptime msg_count: usize, comptime msg_size: usize) usize {
    return @intCast((4 * @as(u32, @intCast(msg_count))) * (3 + ((@as(u32, @intCast(msg_size)) + 3) / 4)));
}

pub fn Message(comptime T: type) type {
    return struct { msg: T, priority: u8 };
}

pub fn MessageQueue(comptime T: type) type {
    return struct {
        id: osMessageQueueId_t = undefined,

        /// Creates a MessageQueue object using an existing MessageQueueId reference
        pub fn create(id: osMessageQueueId_t) @This() {
            return .{ .id = id };
        }

        /// Creates a new MessageQueue for type T
        pub fn new(self: *@This(), msg_count: u32, attr: ?*const osMessageQueueAttr_t) osError!void {
            self.id = c_rtx.osMessageQueueNew(msg_count, @sizeOf(T), attr);

            if (null == self.id) return osError.osErrorResource;
        }

        /// Get message queue name
        pub fn getName(self: *const @This()) ?[*:0]const u8 {
            return c_rtx.osMessageQueueGetName(self.id);
        }

        /// Put a message into the queue
        pub fn put(self: *const @This(), msg: *const T, msg_prio: u8, timeout: ?u32) osError!void {
            return osErrorMap(c_rtx.osMessageQueuePut(self.id, msg, msg_prio, timeout orelse core.osWaitForever));
        }

        /// Get a message from the queue
        inline fn get(self: *const @This(), msg: *T, msg_prio: ?*u8, timeout: u32) osError!void {
            return osErrorMap(c_rtx.osMessageQueueGet(self.id, msg, msg_prio, timeout));
        }

        /// Get a message from the queue
        pub fn getMsg(self: *const @This(), timeout: ?u32) osError!?Message(T) {
            var msg: T = undefined;
            var priority: u8 = undefined;

            return if (self.get(&msg, &priority, timeout orelse core.osWaitForever)) .{ .msg = msg, .priority = priority } else |err| switch (err) {
                osError.osErrorTimeout, osError.osErrorResource => null,
                else => err,
            };
        }

        /// Get maximum number of messages in the queue
        pub fn getCapacity(self: *const @This()) usize {
            return @intCast(c_rtx.osMessageQueueGetCapacity(self.id));
        }

        /// Get maximum message size in bytes
        pub fn getMsgSize(self: *const @This()) u32 {
            return c_rtx.osMessageQueueGetMsgSize(self.id);
        }

        /// Get number of queued messages
        pub fn getCount(self: *const @This()) usize {
            return @intCast(c_rtx.osMessageQueueGetCount(self.id));
        }

        /// Get number of available slots for messages
        pub fn getSpace(self: *const @This()) usize {
            return @intCast(c_rtx.osMessageQueueGetSpace(self.id));
        }

        /// Reset the message queue to initial empty state
        pub fn reset(self: *const @This()) osError!void {
            return osErrorMap(c_rtx.osMessageQueueReset(self.id));
        }

        /// Delete the message queue
        pub fn delete(self: *const @This()) osError!void {
            return osErrorMap(c_rtx.osMessageQueueDelete(self.id));
        }
    };
}

pub fn StaticMessageQueue(comptime T: type, comptime msg_count: usize, comptime name: [*:0]const u8) type {
    return struct {
        /// MessageQueue object
        mq: MessageQueue(T) = undefined,

        /// Control Block, 32-Bit alignment needed
        cb: c_rtx.osRtxMessageQueue_t align(4) = undefined,

        /// Static message storage, 32-Bit alignment needed
        storage: [messageQueueMemSize(msg_count, @sizeOf(T))]u8 align(4) = undefined,

        /// Create new static message queue
        pub fn new(self: *@This(), attr_bits: u32) osError!void {
            // MessageQueue attributes
            const attr: c_rtx.osMessageQueueAttr_t = .{
                .name = name,
                .attr_bits = attr_bits,
                .cb_mem = &self.cb,
                .cb_size = c_rtx.osRtxMessageQueueCbSize,
                .mq_mem = self.storage[0..].ptr,
                .mq_size = self.storage.len,
            };

            try self.mq.new(msg_count, &attr);
        }

        /// Get message queue reference
        pub fn getMessageQueueRef(self: *const @This()) *const MessageQueue(T) {
            return &self.mq;
        }

        /// Get message queue name
        pub fn getName(self: *const @This()) ?[*:0]const u8 {
            return self.mq.getName();
        }

        /// Put a message into the queue
        pub fn put(self: *const @This(), msg: *const T, msg_prio: u8, timeout: ?u32) osError!void {
            return self.mq.put(msg, msg_prio, timeout);
        }

        /// Ger a message from the queue
        pub fn getMsg(self: *const @This(), timeout: ?u32) osError!?Message(T) {
            return self.mq.getMsg(timeout);
        }

        /// Get maximum number of messages in the queue
        pub fn getCapacity(self: *const @This()) usize {
            return self.mq.getCapacity();
        }

        /// Get maximum message size in bytes
        pub fn getMsgSize(self: *const @This()) u32 {
            return self.mq.getMsgSize();
        }

        /// Get number of queued messages
        pub fn getCount(self: *const @This()) usize {
            return self.mq.getCount();
        }

        /// Get number of available slots for messages
        pub fn getSpace(self: *const @This()) usize {
            return self.mq.getSpace();
        }

        /// Reset the message queue to initial empty state
        pub fn reset(self: *const @This()) osError!void {
            return self.mq.reset();
        }

        /// Delete the message queue
        pub fn delete(self: *const @This()) osError!void {
            return self.mq.delete();
        }
    };
}
