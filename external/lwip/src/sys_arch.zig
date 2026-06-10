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
//
// lwIP sys_arch port — board-independent CMSIS-RTOS2 implementation.
//
// This is the root Zig module of the lwip package. It re-exports the lwIP C
// API and provides all sys_arch symbols expected by lwIP when NO_SYS=0.
//
// Board package must inject via addImport/addIncludePath before build:
//   lwip_mod.addImport("cmsis_rtx", cmsis_rtx_mod)
//   lwip_mod.addIncludePath(<board>/lwip_config/)      -- lwipopts.h
//   lwip_mod.addIncludePath(<cmsis_6>/rtos2/include)   -- cmsis_os2.h
//   lwip_mod.addIncludePath(<cmsis_6>/core/include)    -- cmsis_compiler.h
//
// Board provides sys_arch_protect/sys_arch_unprotect (NXP SDK).

const rtx = @import("cmsis_rtx");

// Re-export the lwIP C API so consumers can do:
//   const lwip = @import("lwip");  lwip.c.lwip_init();
pub const c = @import("root.zig").c;

const mu  = rtx.mutex;
const sem = rtx.semaphore;
const mq  = rtx.messageQueue;
const th  = rtx.thread;

const ERR_OK: i8  = 0;
const ERR_MEM: i8 = -1;
const SYS_ARCH_TIMEOUT: u32 = 0xffffffff;
const SYS_MBOX_EMPTY: u32   = 0xffffffff;

// ARM Cortex-M IPSR: 0 = thread mode, non-zero = executing in an ISR.
inline fn getIPSR() u32 {
    return asm volatile ("mrs %[ret], ipsr"
        : [ret] "=r" (-> u32)
    );
}

// Defined by lwIP's sys.c when LWIP_TCPIP_CORE_LOCKING=1.
extern var lock_tcpip_core: mu.osMutexId_t;

// =========================================================================
// Random number generator
// =========================================================================
var rand_value: u32 = 0;

export fn lwip_rand() callconv(.c) u32 {
    rand_value = rand_value *% 1103515245 +% 12345;
    return (rand_value >> 16) % (32767 + 1);
}

// =========================================================================
// Assert
// =========================================================================
export fn sys_assert(pcMessage: [*:0]const u8) callconv(.c) void {
    _ = pcMessage;
    while (true) {}
}

// =========================================================================
// Timing
// =========================================================================
export fn sys_init() callconv(.c) void {}

export fn sys_now() callconv(.c) u32 {
    return rtx.kernel.getTickCount();
}

export fn sys_arch_msleep(delay_ms: u32) callconv(.c) void {
    rtx.osDelay(delay_ms) catch {};
}

// =========================================================================
// Semaphore
// =========================================================================
export fn sys_sem_new(sem_out: *sem.osSemaphoreId_t, count: u8) callconv(.c) i8 {
    sem_out.* = sem.osSemaphoreNew(1, @as(u32, count), null);
    if (sem_out.* == null) return ERR_MEM;
    return ERR_OK;
}

export fn sys_arch_sem_wait(sem_id: *sem.osSemaphoreId_t, timeout_ms: u32) callconv(.c) u32 {
    const t0    = rtx.kernel.getTickCount();
    const ticks = if (timeout_ms == 0) rtx.osWaitForever else timeout_ms;
    if (sem.osSemaphoreAcquire(sem_id.*, ticks) == 0) {
        const elapsed = rtx.kernel.getTickCount() -% t0;
        return if (elapsed == 0) 1 else elapsed;
    }
    return SYS_ARCH_TIMEOUT;
}

export fn sys_sem_signal(sem_id: *sem.osSemaphoreId_t) callconv(.c) void {
    _ = sem.osSemaphoreRelease(sem_id.*);
}

export fn sys_sem_free(sem_id: *sem.osSemaphoreId_t) callconv(.c) void {
    _ = sem.osSemaphoreDelete(sem_id.*);
}

// =========================================================================
// Mutex
// =========================================================================
export fn sys_mutex_new(mutex_out: *mu.osMutexId_t) callconv(.c) i8 {
    const attr = mu.osMutexAttr_t{
        .name     = null,
        .attr_bits = mu.osMutexPrioInherit,
        .cb_mem   = null,
        .cb_size  = 0,
    };
    mutex_out.* = mu.osMutexNew(&attr);
    if (mutex_out.* == null) return ERR_MEM;
    return ERR_OK;
}

export fn sys_mutex_lock(mutex_id: *mu.osMutexId_t) callconv(.c) void {
    _ = mu.osMutexAcquire(mutex_id.*, rtx.osWaitForever);
}

export fn sys_mutex_unlock(mutex_id: *mu.osMutexId_t) callconv(.c) void {
    _ = mu.osMutexRelease(mutex_id.*);
}

export fn sys_mutex_free(mutex_id: *mu.osMutexId_t) callconv(.c) void {
    _ = mu.osMutexDelete(mutex_id.*);
}

// =========================================================================
// Mailbox (message queue carrying void* pointers)
// =========================================================================
export fn sys_mbox_new(mbox_out: *mq.osMessageQueueId_t, size: c_int) callconv(.c) i8 {
    mbox_out.* = mq.osMessageQueueNew(@intCast(size), @sizeOf(?*anyopaque), null);
    if (mbox_out.* == null) return ERR_MEM;
    return ERR_OK;
}

export fn sys_mbox_post(mbox_id: *mq.osMessageQueueId_t, msg: ?*anyopaque) callconv(.c) void {
    var local: ?*anyopaque = msg;
    _ = mq.osMessageQueuePut(mbox_id.*, @as(?*anyopaque, @ptrCast(&local)), 0, rtx.osWaitForever);
}

export fn sys_mbox_trypost(mbox_id: *mq.osMessageQueueId_t, msg: ?*anyopaque) callconv(.c) i8 {
    var local: ?*anyopaque = msg;
    if (mq.osMessageQueuePut(mbox_id.*, @as(?*anyopaque, @ptrCast(&local)), 0, 0) == 0)
        return ERR_OK;
    return ERR_MEM;
}

export fn sys_mbox_trypost_fromisr(mbox_id: *mq.osMessageQueueId_t, msg: ?*anyopaque) callconv(.c) i8 {
    return sys_mbox_trypost(mbox_id, msg);
}

export fn sys_arch_mbox_fetch(mbox_id: *mq.osMessageQueueId_t, msg: ?*?*anyopaque, timeout_ms: u32) callconv(.c) u32 {
    var dummy: ?*anyopaque = null;
    const dst: *?*anyopaque = msg orelse &dummy;
    const t0    = rtx.kernel.getTickCount();
    const ticks = if (timeout_ms == 0) rtx.osWaitForever else timeout_ms;
    if (mq.osMessageQueueGet(mbox_id.*, @as(?*anyopaque, @ptrCast(dst)), null, ticks) == 0) {
        const elapsed = rtx.kernel.getTickCount() -% t0;
        return if (elapsed == 0) 1 else elapsed;
    }
    if (msg) |m| m.* = null;
    return SYS_ARCH_TIMEOUT;
}

export fn sys_arch_mbox_tryfetch(mbox_id: *mq.osMessageQueueId_t, msg: ?*?*anyopaque) callconv(.c) u32 {
    var dummy: ?*anyopaque = null;
    const dst: *?*anyopaque = msg orelse &dummy;
    if (mq.osMessageQueueGet(mbox_id.*, @as(?*anyopaque, @ptrCast(dst)), null, 0) == 0) return 0;
    return SYS_MBOX_EMPTY;
}

export fn sys_mbox_free(mbox_id: *mq.osMessageQueueId_t) callconv(.c) void {
    _ = mq.osMessageQueueDelete(mbox_id.*);
}

// =========================================================================
// Thread
// =========================================================================
export fn sys_thread_new(
    name:       [*:0]const u8,
    thread_fn:  ?*const fn (?*anyopaque) callconv(.c) void,
    arg:        ?*anyopaque,
    stack_size: c_int,
    prio:       c_int,
) callconv(.c) th.osThreadId_t {
    const attr = th.osThreadAttr_t{
        .name         = name,
        .attr_bits    = 0,
        .cb_mem       = null,
        .cb_size      = 0,
        .stack_mem    = null,
        .stack_size   = @intCast(stack_size),
        .priority     = @intFromEnum(th.osThreadPriority.osPriorityNormal) + @as(i32, prio),
        .tz_module    = 0,
        .affinity_mask = 0,
    };
    return th.osThreadNew(@ptrCast(thread_fn), arg, &attr);
}

// =========================================================================
// Core locking (LWIP_TCPIP_CORE_LOCKING=1)
// =========================================================================
var lwip_core_lock_count:  u8              = 0;
var lwip_core_lock_holder: th.osThreadId_t = null;
var lwip_tcpip_thread:     th.osThreadId_t = null;

export fn sys_lock_tcpip_core() callconv(.c) void {
    _ = mu.osMutexAcquire(lock_tcpip_core, rtx.osWaitForever);
    if (lwip_core_lock_count == 0) {
        lwip_core_lock_holder = rtx.thread.getThreadId().id;
    }
    lwip_core_lock_count += 1;
}

export fn sys_unlock_tcpip_core() callconv(.c) void {
    lwip_core_lock_count -= 1;
    if (lwip_core_lock_count == 0) {
        lwip_core_lock_holder = null;
    }
    _ = mu.osMutexRelease(lock_tcpip_core);
}

export fn sys_mark_tcpip_thread() callconv(.c) void {
    lwip_tcpip_thread = rtx.thread.getThreadId().id;
}

export fn sys_check_core_locking() callconv(.c) void {
    if (getIPSR() != 0) {
        while (true) {}
    }
    if (lwip_tcpip_thread != null) {
        const current = rtx.thread.getThreadId().id;
        if (current != lwip_core_lock_holder or lwip_core_lock_count == 0) {
            while (true) {}
        }
    }
}
