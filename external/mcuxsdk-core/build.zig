const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

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

    // =========================================================================
    // ARM Cortex-M Core Files (for MCXE247 - Cortex M4F)
    // =========================================================================

    // ARM CMSIS compatibility headers are provided by the cmsis_6 package
    // The mcuxsdk-core works alongside CMSIS for core functionality

    // =========================================================================
    // Common Driver Files (required for all MCX devices)
    // =========================================================================

    // Get cmsis_6 for core headers
    const cmsis_6 = b.dependency("cmsis_6", .{
        .target = target,
        .optimize = optimize,
    });

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
    lib.root_module.addIncludePath(b.path("../mcux-devices-mcx/mcux-devices-mcx/MCXE/MCXE247"));
    lib.root_module.addIncludePath(b.path("../mcux-devices-mcx/mcux-devices-mcx/MCXE/periph0"));
    lib.root_module.addIncludePath(b.path("../mcux-devices-mcx/mcux-devices-mcx/MCXE/MCXE247/drivers"));
    lib.root_module.addIncludePath(cmsis_6.artifact("CMSIS_6").getEmittedIncludeTree().path(b, "cmsis_6/core/include"));

    // Install common headers
    lib.installHeadersDirectory(
        b.path("mcuxsdk-core/drivers/common"),
        "mcuxsdk-core/include",
        .{ .include_extensions = &.{".h"} },
    );

    // Install essential driver headers (without compiling source files)
    // These headers are needed by board configuration files
    lib.installHeadersDirectory(
        b.path("mcuxsdk-core/drivers/port"),
        "mcuxsdk-core/include",
        .{ .include_extensions = &.{".h"} },
    );
    lib.installHeadersDirectory(
        b.path("mcuxsdk-core/drivers/gpio_1"),
        "mcuxsdk-core/include",
        .{ .include_extensions = &.{".h"} },
    );
    lib.installHeadersDirectory(
        b.path("mcuxsdk-core/drivers/lpuart"),
        "mcuxsdk-core/include",
        .{ .include_extensions = &.{".h"} },
    );

    // =========================================================================
    // Compiler-specific definitions
    // =========================================================================

    // Define CPU architecture macros
    lib.root_module.addCMacro("CPU_MCXE247VLQ", "1");
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
