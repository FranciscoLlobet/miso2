const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Option to select target device (default: MCXE247)
    const device = b.option([]const u8, "device", "Target MCX device (e.g., MCXE247, MCXA156)") orelse "MCXE247";

    // Create the mcuxsdk-core module
    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "mcuxsdk-core",
        .root_module = lib_mod,
    });

    const mcux_devices_mcx = b.dependency("mcux_devices_mcx", .{});
    // =========================================================================
    // ARM Cortex-M Core Files (for MCXE247 - Cortex M4F)
    // =========================================================================

    // ARM CMSIS compatibility headers are provided by the cmsis_6 package
    // The mcuxsdk-core works alongside CMSIS for core functionality

    // =========================================================================
    // Common Driver Files (required for all MCX devices)
    // =========================================================================

    lib.root_module.addCSourceFiles(.{
        .files = &.{
            "mcuxsdk-core/drivers/common/fsl_common.c",
            "mcuxsdk-core/drivers/common/fsl_common_arm.c",
        },
        .flags = &.{
            "-std=c99",
            "-Wall",
            "-ffunction-sections",
            "-fdata-sections",
            "-fno-common",
        },
    });

    lib.root_module.addIncludePath(b.path("mcuxsdk-core/drivers/common"));
    lib.root_module.addIncludePath(b.path("../picolibc/include"));

    // Install common headers
    lib.installHeadersDirectory(
        b.path("mcuxsdk-core/drivers/common"),
        "mcuxsdk-core/include",
        .{ .include_extensions = &.{".h"} },
    );

    // =========================================================================
    // Device-Specific Drivers for MCXE247
    // =========================================================================

    if (std.mem.eql(u8, device, "MCXE247")) {
        // GPIO Driver (gpio_1 variant for MCX E-series)
        lib.root_module.addIncludePath(mcux_devices_mcx.artifact("mcux-devices-mcx").getEmittedIncludeTree().path(b, "mcux-devices-mcx/include"));

        lib.root_module.addCSourceFile(.{
            .file = b.path("mcuxsdk-core/drivers/gpio_1/fsl_gpio.c"),
            .flags = &.{"-std=c99"},
        });
        lib.installHeadersDirectory(
            b.path("mcuxsdk-core/drivers/port"),
            "mcuxsdk-core/include",
            .{ .include_extensions = &.{".h"} },
        );
    }
    // Future support for MCXA156
    else if (std.mem.eql(u8, device, "MCXA156")) {
        // Similar driver configuration for MCXA156
        // This would use different driver variants (lpc_gpio, etc.)
        @panic("MCXA156 support not yet implemented");
    }

    // =========================================================================
    // Compiler-specific definitions
    // =========================================================================

    // Define CPU architecture macros
    lib.root_module.addCMacro("CPU_MCXE247VDF", "1");
    lib.root_module.addCMacro("__STARTUP_CLEAR_BSS", "1");
    lib.root_module.addCMacro("__STARTUP_INITIALIZE_NONCACHEDATA", "1");

    // ARM Cortex-M4 with FPU
    lib.root_module.addCMacro("__ARM_ARCH_7EM__", "1");
    lib.root_module.addCMacro("ARM_MATH_CM4", "1");
    lib.root_module.addCMacro("__FPU_PRESENT", "1");

    // SDK version
    lib.root_module.addCMacro("SDK_DEBUGCONSOLE", "1");

    b.installArtifact(lib);

    // =========================================================================
    // Export module for consumers
    // =========================================================================

    _ = b.addModule("mcuxsdk_core", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
}
