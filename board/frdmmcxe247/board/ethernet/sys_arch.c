/*
 * Copyright (c) 2013-2016, Freescale Semiconductor, Inc.
 * Copyright 2016-2020,2022-2023,2025 NXP
 * All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Board-specific lwIP sys_arch functions for FRDM-MCXE247.
 * Only functions that require the NXP SDK (fsl_common.h) live here.
 * All CMSIS-RTOS2 sys_arch functions are in external/lwip/src/sys_arch.c.
 */

#include "arch/sys_arch.h"
#include "lwip/opt.h"
#include "lwip/sys.h"
#include "fsl_common.h"

sys_prot_t sys_arch_protect(void)
{
    return (sys_prot_t)DisableGlobalIRQ();
}

void sys_arch_unprotect(sys_prot_t xValue)
{
    EnableGlobalIRQ((uint32_t)xValue);
}
