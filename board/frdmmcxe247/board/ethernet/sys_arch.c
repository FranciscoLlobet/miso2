/*
 * Copyright (c) 2001-2003 Swedish Institute of Computer Science.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 * OF SUCH DAMAGE.
 *
 * This file is part of the lwIP TCP/IP stack.
 *
 * Author: Adam Dunkels <adam@sics.se>
 *
 */

#include <stdint.h>

#include "lwip/opt.h"
#include "lwip/def.h"
#include "lwip/ethip6.h"
#include "lwip/igmp.h"
#include "lwip/mem.h"
#include "lwip/mld6.h"
#include "lwip/pbuf.h"
#include "lwip/snmp.h"
#include "lwip/stats.h"
#include "lwip/sys.h"

#include "fsl_common.h"

sys_prot_t sys_arch_protect(void)
{
    sys_prot_t result;

    result = (sys_prot_t)DisableGlobalIRQ();

    return result;
}

void sys_arch_unprotect(sys_prot_t xValue)
{
    EnableGlobalIRQ((uint32_t)xValue);
}

void sys_check_core_locking(void)
{
    LWIP_ASSERT("Function called from interrupt context",
#ifdef __CA7_REV
                (SystemGetIRQNestingLevel() == 0)
#else
                (__get_IPSR() == 0)
#endif
    );
}

/************************************************************************
 * Generates a pseudo-random number.
 * NOTE: Contributed by the FNET project.
 *************************************************************************/
static uint32_t _rand_value;
uint32_t lwip_rand(void)
{
    _rand_value = _rand_value * 1103515245u + 12345u;
    return ((uint32_t)(_rand_value >> 16u) % (32767u + 1u));
}

