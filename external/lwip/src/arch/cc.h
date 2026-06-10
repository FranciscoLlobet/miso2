/*
 * Copyright 2025 Francisco Llobet-Blandino
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * lwIP compiler/architecture abstraction for ARM Cortex-M4 (MCXE247)
 * built with GCC/Clang + picolibc in bare-metal (freestanding) mode.
 *
 * Placed at arch/cc.h so lwip/arch.h (#include "arch/cc.h") finds it.
 */

#ifndef LWIP_ARCH_CC_H
#define LWIP_ARCH_CC_H

#include <stdint.h>  /* uint32_t must be defined before lwip_rand() below */

/* Cortex-M4 is always little-endian */
#define BYTE_ORDER LITTLE_ENDIAN

#define LWIP_ERR_T  int32_t

/* picolibc provides stdint.h / inttypes.h / limits.h in bare-metal builds */
/* No POSIX unistd.h or sys/time.h in freestanding mode */
#define LWIP_NO_UNISTD_H 1

/* picolibc bare-metal errno.h declares the variable but may not define
 * the thread-local storage variant; let lwIP manage its own errno copy. */
#define LWIP_PROVIDE_ERRNO 1

/* GCC/Clang handle packed structs natively; no wrapper needed */
/* PACK_STRUCT_STRUCT, PACK_STRUCT_BEGIN, PACK_STRUCT_END default to GCC attrs */
#define PACK_STRUCT_BEGIN
#define PACK_STRUCT_STRUCT __attribute__((__packed__))
#define PACK_STRUCT_END
#define PACK_STRUCT_FIELD(x) x

#include "lwipopts.h"
#include "arch/sys_arch.h"

/* Suppress diagnostic output on bare-metal (no printf available by default).
 * Override in the application by defining LWIP_PLATFORM_DIAG before any
 * lwIP header is included. */
#ifndef LWIP_PLATFORM_DIAG
#define LWIP_PLATFORM_DIAG(x) do {} while (0)
#endif

/* Bare-metal assert: spin forever on assertion failure.
 * Override in the application for a more useful handler. */
#ifndef LWIP_PLATFORM_ASSERT
#define LWIP_PLATFORM_ASSERT(x) do { (void)(x); while (1) {} } while (0)
#endif

/* Simple 32-bit PRNG seeded at link time.  Replace with a hardware RNG
 * (e.g. TRNG peripheral) for production use. */
uint32_t lwip_rand(void);
#define LWIP_RAND() ((u32_t)lwip_rand())

/* -------------------------------------------------------------------------
 * Critical section abstraction:
 *
 * With SYS_LIGHTWEIGHT_PROT=1 (set in lwipopts.h), lwIP calls
 * sys_arch_protect() / sys_arch_unprotect() for critical sections.
 * Those are provided by the board package (board/ethernet/sys_arch.c)
 * using DisableGlobalIRQ/EnableGlobalIRQ from the NXP SDK.
 * ------------------------------------------------------------------------- */

#endif /* LWIP_ARCH_CC_H */
