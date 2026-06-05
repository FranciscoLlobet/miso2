const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "mcux-component",
        .root_module = lib_mod,
    });

    // =========================================================================
    // Dependencies
    // =========================================================================

    const cmsis_6 = b.dependency("cmsis_6", .{
        .target = target,
        .optimize = optimize,
    });
    const mcuxsdk_core = b.dependency("mcuxsdk_core", .{
        .target = target,
        .optimize = optimize,
    });
    const mcux_devices_mcx = b.dependency("mcux_devices_mcx", .{
        .target = target,
        .optimize = optimize,
    });

    // =========================================================================
    // PHY component source files
    // =========================================================================

    lib.root_module.addCSourceFiles(.{
        .files = &.{
            "mcux-component/phy/device/phylan8741/fsl_phylan8741.c",
            "mcux-component/silicon_id/fsl_silicon_id.c",
            "mcux-component/gpio/fsl_adapter_gpio.c",
        },
        .root = b.path("."),
        .flags = &.{
            "-std=c99",
            "-ffunction-sections",
            "-fdata-sections",
            "-fno-common",
            "-DCPU_MCXE247VLQ",
        },
    });

    // =========================================================================
    // Include paths
    // =========================================================================

    lib.root_module.addIncludePath(b.path("mcux-component/phy"));
    lib.root_module.addIncludePath(b.path("mcux-component/phy/device/phylan8741"));
    lib.root_module.addIncludePath(b.path("../picolibc/include"));
    lib.root_module.addIncludePath(cmsis_6.artifact("CMSIS_6").getEmittedIncludeTree().path(b, "cmsis_6/core/include"));
    lib.root_module.addIncludePath(mcuxsdk_core.artifact("mcuxsdk-core").getEmittedIncludeTree().path(b, "mcuxsdk-core/include"));
    lib.root_module.addIncludePath(mcux_devices_mcx.artifact("mcux-devices-mcx").getEmittedIncludeTree().path(b, "mcux-devices-mcx/include"));

    // =========================================================================
    // Install headers for consumers
    // =========================================================================

    lib.installHeadersDirectory(
        b.path("mcux-component/phy"),
        "mcux-component/include",
        .{ .include_extensions = &.{".h"} },
    );
    lib.installHeadersDirectory(
        b.path("mcux-component/phy/device/phylan8741"),
        "mcux-component/include",
        .{ .include_extensions = &.{".h"} },
    );
    lib.installHeadersDirectory(
        b.path("mcux-component/silicon_id/"),
        "mcux-component/include",
        .{ .include_extensions = &.{".h"} },
    );
    lib.installHeadersDirectory(
        b.path("mcux-component/gpio/"),
        "mcux-component/include",
        .{ .include_extensions = &.{".h"} },
    );
    b.installArtifact(lib);
}
