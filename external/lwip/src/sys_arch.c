/*
 * Copyright (c) 2001-2003 Swedish Institute of Computer Science.
 * Copyright (c) 2013-2016, Freescale Semiconductor, Inc.
 * Copyright 2016-2020,2022-2023,2025 NXP
 * All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * lwIP sys_arch — board-independent CMSIS-RTOS2 port.
 *
 * Board-specific functions (sys_arch_protect / sys_arch_unprotect) that call
 * DisableGlobalIRQ / EnableGlobalIRQ from the NXP SDK are provided by the
 * board package (board/ethernet/sys_arch.c), exactly as the board provides
 * RTX_Config.h for the cmsis_rtx package.
 *
 * Consumer must inject include paths for:
 *   - cmsis_os2.h   (CMSIS-RTOS2, from cmsis_6 rtos2/include)
 *   - cmsis_gcc.h   (for __get_IPSR, from cmsis_6 core/include)
 *   - lwipopts.h    (from board's lwip_config/)
 */

#include "arch/sys_arch.h"
#include "cmsis_compiler.h"  /* __get_IPSR — from cmsis_6 core/include, injected by board */
#include "lwip/opt.h"
#include "lwip/debug.h"
#include "lwip/def.h"
#include "lwip/sys.h"
#include "lwip/mem.h"
#include "lwip/stats.h"
#include "lwip/tcpip.h"

/* -------------------------------------------------------------------------
 * Board-independent utilities
 * ------------------------------------------------------------------------- */

static uint32_t _rand_value;
uint32_t lwip_rand(void)
{
    _rand_value = _rand_value * 1103515245u + 12345u;
    return ((uint32_t)(_rand_value >> 16u) % (32767u + 1u));
}

void sys_assert(const char *pcMessage)
{
#ifdef LWIP_DEBUG
    LWIP_PLATFORM_DIAG((pcMessage));
#endif
    for (;;) {}
}

#if !NO_SYS

#include "cmsis_os2.h"

/* -------------------------------------------------------------------------
 * Timing
 * ------------------------------------------------------------------------- */

void sys_init(void) {}

u32_t sys_now(void)
{
    return (u32_t)osKernelGetTickCount();
}

void sys_arch_msleep(u32_t delay_ms)
{
    osDelay((uint32_t)delay_ms);
}

/* -------------------------------------------------------------------------
 * Semaphore
 * ------------------------------------------------------------------------- */

err_t sys_sem_new(sys_sem_t *sem, u8_t count)
{
    LWIP_ASSERT("sem != NULL", sem != NULL);
    *sem = osSemaphoreNew(1, (uint32_t)count, NULL);
    if (*sem == NULL) {
        SYS_STATS_INC(sem.err);
        return ERR_MEM;
    }
    SYS_STATS_INC_USED(sem);
    return ERR_OK;
}

u32_t sys_arch_sem_wait(sys_sem_t *sem, u32_t timeout_ms)
{
    uint32_t t0    = osKernelGetTickCount();
    uint32_t ticks = (timeout_ms == 0u) ? osWaitForever : (uint32_t)timeout_ms;
    osStatus_t st  = osSemaphoreAcquire(*sem, ticks);
    if (st == osOK) {
        uint32_t elapsed = osKernelGetTickCount() - t0;
        return (elapsed == 0u) ? 1u : elapsed;
    }
    return SYS_ARCH_TIMEOUT;
}

void sys_sem_signal(sys_sem_t *sem)
{
    osSemaphoreRelease(*sem);
}

void sys_sem_free(sys_sem_t *sem)
{
    SYS_STATS_DEC(sem.used);
    osSemaphoreDelete(*sem);
}

/* -------------------------------------------------------------------------
 * Mutex
 * ------------------------------------------------------------------------- */

err_t sys_mutex_new(sys_mutex_t *mutex)
{
    static const osMutexAttr_t attr = { .attr_bits = osMutexPrioInherit };
    *mutex = osMutexNew(&attr);
    if (*mutex == NULL) {
        SYS_STATS_INC(mutex.err);
        return ERR_MEM;
    }
    SYS_STATS_INC_USED(mutex);
    return ERR_OK;
}

void sys_mutex_lock(sys_mutex_t *mutex)
{
    osMutexAcquire(*mutex, osWaitForever);
}

void sys_mutex_unlock(sys_mutex_t *mutex)
{
    osMutexRelease(*mutex);
}

void sys_mutex_free(sys_mutex_t *mutex)
{
    SYS_STATS_DEC(mutex.used);
    osMutexDelete(*mutex);
}

/* -------------------------------------------------------------------------
 * Mailbox
 * ------------------------------------------------------------------------- */

err_t sys_mbox_new(sys_mbox_t *mbox, int size)
{
    *mbox = osMessageQueueNew((uint32_t)size, sizeof(void *), NULL);
    if (*mbox == NULL) {
        SYS_STATS_INC(mbox.err);
        return ERR_MEM;
    }
    SYS_STATS_INC_USED(mbox);
    return ERR_OK;
}

void sys_mbox_post(sys_mbox_t *mbox, void *msg)
{
    osMessageQueuePut(*mbox, &msg, 0u, osWaitForever);
}

err_t sys_mbox_trypost(sys_mbox_t *mbox, void *msg)
{
    if (osMessageQueuePut(*mbox, &msg, 0u, 0u) == osOK) {
        return ERR_OK;
    }
    SYS_STATS_INC(mbox.err);
    return ERR_MEM;
}

err_t sys_mbox_trypost_fromisr(sys_mbox_t *mbox, void *msg)
{
    return sys_mbox_trypost(mbox, msg);
}

u32_t sys_arch_mbox_fetch(sys_mbox_t *mbox, void **msg, u32_t timeout_ms)
{
    void  *dummy;
    if (msg == NULL) {
        msg = &dummy;
    }
    uint32_t t0    = osKernelGetTickCount();
    uint32_t ticks = (timeout_ms == 0u) ? osWaitForever : (uint32_t)timeout_ms;
    osStatus_t st  = osMessageQueueGet(*mbox, msg, NULL, ticks);
    if (st == osOK) {
        uint32_t elapsed = osKernelGetTickCount() - t0;
        return (elapsed == 0u) ? 1u : elapsed;
    }
    *msg = NULL;
    return SYS_ARCH_TIMEOUT;
}

u32_t sys_arch_mbox_tryfetch(sys_mbox_t *mbox, void **msg)
{
    void *dummy;
    if (msg == NULL) {
        msg = &dummy;
    }
    return (osMessageQueueGet(*mbox, msg, NULL, 0u) == osOK) ? 0u : (u32_t)SYS_MBOX_EMPTY;
}

void sys_mbox_free(sys_mbox_t *mbox)
{
    SYS_STATS_DEC(mbox.used);
    osMessageQueueDelete(*mbox);
}

/* -------------------------------------------------------------------------
 * Thread
 * ------------------------------------------------------------------------- */

sys_thread_t sys_thread_new(const char *name, void (*fn)(void *), void *arg,
                             int stack_size, int prio)
{
    osThreadAttr_t attr = {
        .name       = name,
        .stack_size = (uint32_t)stack_size,
        .priority   = (osPriority_t)(osPriorityNormal + prio),
    };
    osThreadId_t id = osThreadNew(fn, arg, &attr);
    LWIP_ASSERT("sys_thread_new: osThreadNew failed", id != NULL);
    return id;
}

/* -------------------------------------------------------------------------
 * Core locking
 * ------------------------------------------------------------------------- */

#if LWIP_TCPIP_CORE_LOCKING

static u8_t          lwip_core_lock_count;
static osThreadId_t  lwip_core_lock_holder;

void sys_lock_tcpip_core(void)
{
    sys_mutex_lock(&lock_tcpip_core);
    if (lwip_core_lock_count == 0u) {
        lwip_core_lock_holder = osThreadGetId();
    }
    lwip_core_lock_count++;
}

void sys_unlock_tcpip_core(void)
{
    lwip_core_lock_count--;
    if (lwip_core_lock_count == 0u) {
        lwip_core_lock_holder = NULL;
    }
    sys_mutex_unlock(&lock_tcpip_core);
}

#endif /* LWIP_TCPIP_CORE_LOCKING */

static osThreadId_t lwip_tcpip_thread;

void sys_mark_tcpip_thread(void)
{
    lwip_tcpip_thread = osThreadGetId();
}

void sys_check_core_locking(void)
{
    LWIP_ASSERT("Function called from interrupt context", (__get_IPSR() == 0));

    if (lwip_tcpip_thread != NULL) {
        osThreadId_t current = osThreadGetId();
        LWIP_UNUSED_ARG(current);
#if LWIP_TCPIP_CORE_LOCKING
        LWIP_UNUSED_ARG(lwip_core_lock_holder);
        LWIP_ASSERT("Function called without core lock",
                    current == lwip_core_lock_holder && lwip_core_lock_count > 0u);
#else
        LWIP_ASSERT("Function called from wrong thread", current == lwip_tcpip_thread);
#endif
    }
}

#endif /* !NO_SYS */
