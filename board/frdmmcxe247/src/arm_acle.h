/*
 * Shim arm_acle.h for Zig @cImport compatibility.
 *
 * Zig's bundled Clang (both from the extension and from /usr/lib/zig) emits
 * hard compilation errors for two intrinsics in the real arm_acle.h when
 * targeting thumb-freestanding-eabihf:
 *   - __builtin_arm_ldrex returns void, which is not assignable to uint32_t
 *   - __builtin_arm_rbit64 is unknown for 32-bit ARM targets
 *
 * These are inline function bodies; they are only needed if the Zig code
 * calls the ACLE intrinsics directly.  SDK headers only need the macro
 * definitions and the existence of the header, not the inline implementations.
 *
 * The real arm_acle.h is still compiled into the C board library via the
 * normal GCC/Clang pipeline; this stub only applies to @cImport translation.
 */

#ifndef __ARM_ACLE_H
#define __ARM_ACLE_H

#ifndef __ARM_ACLE
#define __ARM_ACLE 200
#endif

#include <stdint.h>

#endif /* __ARM_ACLE_H */
