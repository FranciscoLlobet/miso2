/*
 * Copyright (c) 2001-2003 Swedish Institute of Computer Science.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 *
 * SPDX-License-Identifier: BSD-3-Clause (Swedish Institute of Computer Science)
 *
 * lwIP sys_arch type definitions for CMSIS-RTOS2 (RTX5).
 * Consumer must inject cmsis_os2.h include path.
 */

#ifndef __ARCH_SYS_ARCH_H__
#define __ARCH_SYS_ARCH_H__

#include "lwip/opt.h"
#include "arch/cc.h"

#include <stdint.h>

typedef uint32_t sys_prot_t;

#if !NO_SYS

#include "cmsis_os2.h"

typedef osSemaphoreId_t    sys_sem_t;
typedef osMutexId_t        sys_mutex_t;
typedef osMessageQueueId_t sys_mbox_t;
typedef osThreadId_t       sys_thread_t;

#define SYS_MBOX_NULL                   ((osMessageQueueId_t)NULL)
#define SYS_SEM_NULL                    ((osSemaphoreId_t)NULL)
#define SYS_DEFAULT_THREAD_STACK_DEPTH  1024

#define sys_mbox_valid(x)        ((*(x)) != NULL)
#define sys_mbox_set_invalid(x)  (*(x) = NULL)
#define sys_sem_valid(x)         ((*(x)) != NULL)
#define sys_sem_set_invalid(x)   (*(x) = NULL)
#define sys_mutex_valid(x)       ((*(x)) != NULL)
#define sys_mutex_set_invalid(x) (*(x) = NULL)

void sys_arch_msleep(uint32_t ms);
#define sys_msleep(ms) sys_arch_msleep(ms)

#endif /* !NO_SYS */

#if defined(__cplusplus)
extern "C" {
#endif

void sys_assert(const char *pcMessage);

#if defined(__cplusplus)
}
#endif

#endif /* __ARCH_SYS_ARCH_H__ */
