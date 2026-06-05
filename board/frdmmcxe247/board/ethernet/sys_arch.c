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
