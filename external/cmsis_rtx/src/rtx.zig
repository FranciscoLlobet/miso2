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
const std = @import("std");
const core = @import("core.zig");
const c_rtx = core.c_rtx;

pub const kernel = @import("kernel.zig");
pub const delay = @import("delay.zig");
pub const eventFlags = @import("eventFlags.zig");
pub const thread = @import("thread.zig");
pub const timer = @import("timer.zig");
pub const mutex = @import("mutex.zig");
pub const semaphore = @import("semaphore.zig");

pub const StaticThread = thread.StaticThread;
pub const StaticTimer = timer.StaticTimer;
pub const StaticMutex = mutex.StaticMutex;
pub const StaticSemaphore = semaphore.StaticSemaphore;
pub const MessageQueue = @import("messageQueue.zig").MessageQueue;
pub const StaticMessageQueue = @import("messageQueue.zig").StaticMessageQueue;

pub const osError = core.osError;
pub const osFlagsError = core.osFlagsError;
pub const osWaitForever: u32 = @intCast(c_rtx.osWaitForever);

pub const Kernel = kernel.Kernel;

pub const osDelay = delay.osDelay;
pub const osDelayUntil = delay.osDelayUntil;
