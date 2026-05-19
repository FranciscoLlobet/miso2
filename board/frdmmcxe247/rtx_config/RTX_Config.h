/*
 * Copyright (c) 2025 Francisco Llobet-Blandino
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * RTX configuration for FRDM-MCXE247 (NXP MCXE247, Cortex-M4, 256kB SRAM).
 * This is a complete, self-contained replacement for the upstream RTX_Config.h.
 * Values are tuned for the MCXE247 platform; see comments for upstream defaults.
 */

#ifndef RTX_CONFIG_H_
#define RTX_CONFIG_H_

/* Global dynamic memory: 8kB (upstream default: 32768) */
#define OS_DYNAMIC_MEM_SIZE         8192

/* Kernel tick: 1ms (upstream default: 1000 — same) */
#define OS_TICK_FREQ                1000

/* Round-robin scheduling */
#define OS_ROBIN_ENABLE             1
#define OS_ROBIN_TIMEOUT            5

/* Safety features: disabled */
#define OS_SAFETY_FEATURES          0
#define OS_SAFETY_CLASS             1
#define OS_EXECUTION_ZONE           1
#define OS_THREAD_WATCHDOG          1
#define OS_OBJ_PTR_CHECK            0
#define OS_SVC_PTR_CHECK            0

/* ISR FIFO queue */
#define OS_ISR_FIFO_QUEUE           16

/* Object memory usage counters */
#define OS_OBJ_MEM_USAGE            0

/* Thread configuration */
#define OS_THREAD_OBJ_MEM           0
#define OS_THREAD_NUM               1
#define OS_THREAD_DEF_STACK_NUM     0
#define OS_THREAD_USER_STACK_SIZE   0

/* Default thread stack: 512 bytes (upstream default: 3072) */
#define OS_STACK_SIZE               512
/* Idle thread stack: 256 bytes (upstream default: 512) */
#define OS_IDLE_THREAD_STACK_SIZE   256
#define OS_IDLE_THREAD_TZ_MOD_ID    0
#define OS_IDLE_THREAD_CLASS        0
#define OS_IDLE_THREAD_ZONE         0

#define OS_STACK_CHECK              1
#define OS_STACK_WATERMARK          1
#define OS_PRIVILEGE_MODE           1

/* Timer configuration */
#define OS_TIMER_OBJ_MEM            0
#define OS_TIMER_NUM                1
#define OS_TIMER_THREAD_PRIO        40
/* Timer thread stack: 256 bytes (upstream default: 512) */
#define OS_TIMER_THREAD_STACK_SIZE  512
#define OS_TIMER_THREAD_TZ_MOD_ID   0
#define OS_TIMER_THREAD_CLASS       0
#define OS_TIMER_THREAD_ZONE        0
#define OS_TIMER_CB_QUEUE           4

/* Event flags */
#define OS_EVFLAGS_OBJ_MEM          0
#define OS_EVFLAGS_NUM              1

/* Mutex */
#define OS_MUTEX_OBJ_MEM            0
#define OS_MUTEX_NUM                1

/* Semaphore */
#define OS_SEMAPHORE_OBJ_MEM        0
#define OS_SEMAPHORE_NUM            1

/* Memory pool */
#define OS_MEMPOOL_OBJ_MEM          0
#define OS_MEMPOOL_NUM              1
#define OS_MEMPOOL_DATA_SIZE        0

/* Message queue */
#define OS_MSGQUEUE_OBJ_MEM         0
#define OS_MSGQUEUE_NUM             1
#define OS_MSGQUEUE_DATA_SIZE       0

/* Event recorder: disabled */
#define OS_EVR_INIT                 0
#define OS_EVR_START                1
#define OS_EVR_LEVEL                0x00U
#define OS_EVR_MEMORY_LEVEL         0x81U
#define OS_EVR_KERNEL_LEVEL         0x81U
#define OS_EVR_THREAD_LEVEL         0x85U
#define OS_EVR_WAIT_LEVEL           0x81U
#define OS_EVR_THFLAGS_LEVEL        0x81U
#define OS_EVR_EVFLAGS_LEVEL        0x81U
#define OS_EVR_TIMER_LEVEL          0x81U
#define OS_EVR_MUTEX_LEVEL          0x81U
#define OS_EVR_SEMAPHORE_LEVEL      0x81U
#define OS_EVR_MEMPOOL_LEVEL        0x81U
#define OS_EVR_MSGQUEUE_LEVEL       0x81U

#define OS_EVR_MEMORY               1
#define OS_EVR_KERNEL               1
#define OS_EVR_THREAD               1
#define OS_EVR_WAIT                 1
#define OS_EVR_THFLAGS              1
#define OS_EVR_EVFLAGS              1
#define OS_EVR_TIMER                1
#define OS_EVR_MUTEX                1
#define OS_EVR_SEMAPHORE            1
#define OS_EVR_MEMPOOL              1
#define OS_EVR_MSGQUEUE             1

/* Libspace threads (required by upstream when OS_THREAD_OBJ_MEM == 0) */
#define OS_THREAD_LIBSPACE_NUM      4

#endif /* RTX_CONFIG_H_ */
