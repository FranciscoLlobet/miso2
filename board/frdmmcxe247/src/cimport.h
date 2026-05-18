/*
 * Compatibility shims for Zig @cImport on thumb-freestanding-eabihf.
 *
 * arm_acle.h: this file is shadowed by src/arm_acle.h (see that file).
 * Zig's bundled Clang rejects __builtin_arm_ldrex and __builtin_arm_rbit64
 * as compilation errors for this target, so the real arm_acle.h cannot be
 * used during C translation.  We set __ARM_ACLE here too as a belt-and-
 * suspenders measure in case cmsis_gcc.h is included from elsewhere.
 *
 * cmsis_gcc.h: checks __ARM_ARCH_PROFILE == 'M' (char literal 77).  Zig's
 * Clang does not auto-define this for thumb freestanding targets.  Setting
 * it to the identifier M (not 'M') in addCMacro was wrong; define it
 * correctly here.
 *
 * wint_t: picolibc's sys/_types.h relies on the __need_wint_t + <stddef.h>
 * idiom, but fsl_common.h brings in <stdlib.h> first which triggers a full
 * Clang stddef.h pass.  The subsequent __need_wint_t re-include then does
 * nothing and wint_t stays undefined.  Pre-define it with the standard ARM
 * unsigned-int underlying type to break the dependency.
 */

#ifndef __ARM_ACLE
#define __ARM_ACLE 200
#endif

#ifndef __ARM_ARCH_PROFILE
#define __ARM_ARCH_PROFILE 'M'
#endif

#ifndef _WINT_T
#define _WINT_T
typedef unsigned int wint_t;
#endif

/* __picolibc_deprecated: sys/cdefs.h defines this via __GNUC_PREREQ__/
 * __clang__ detection, but the detection can fall through to the
 * _ATTRIBUTE() fallback form which translate-c doesn't expand correctly.
 * Include sys/cdefs.h now, then force the correct definition. */
#include <sys/cdefs.h>
#undef __picolibc_deprecated
#define __picolibc_deprecated(m)

#include "peripherals.h"
#include "clock_config.h"
#include "pin_mux.h"
