const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Option to select target device family (default: MCXE247 for FRDM board)
    const device = b.option([]const u8, "device", "Target MCX device (e.g., MCXE247, MCXA156)") orelse "MCXE247";

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "mcux-devices-mcx",
        .root_module = lib_mod,
    });

    // Get dependencies
    const mcuxsdk_core = b.dependency("mcuxsdk_core", .{
        .target = target,
        .optimize = optimize,
    });
    const cmsis_6 = b.dependency("cmsis_6", .{
        .target = target,
        .optimize = optimize,
    });

    // Install headers based on selected device
    // MCXE247 (default for FRDM-MCXE247 board)
    if (std.mem.eql(u8, device, "MCXE247")) {
        lib.installHeadersDirectory(b.path("mcux-devices-mcx/MCXE/MCXE247"), "mcux-devices-mcx/include", .{});
        lib.installHeadersDirectory(b.path("mcux-devices-mcx/MCXE/periph0"), "mcux-devices-mcx/include", .{});
        lib.installHeadersDirectory(b.path("mcux-devices-mcx/MCXE/MCXE247/drivers"), "mcux-devices-mcx/include", .{});

        // Add include paths for compilation
        lib.root_module.addIncludePath(b.path("../picolibc/include"));
        lib.root_module.addIncludePath(b.path("mcux-devices-mcx/MCXE/MCXE247"));
        lib.root_module.addIncludePath(b.path("mcux-devices-mcx/MCXE/periph0"));
        lib.root_module.addIncludePath(b.path("mcux-devices-mcx/MCXE/MCXE247/drivers"));
        lib.root_module.addIncludePath(cmsis_6.artifact("CMSIS_6").getEmittedIncludeTree().path(b, "cmsis_6/core/include"));
        lib.root_module.addIncludePath(mcuxsdk_core.artifact("mcuxsdk-core").getEmittedIncludeTree().path(b, "mcuxsdk-core/include"));

        // Add NXP MCUXpresso SDK drivers
        lib.root_module.addCSourceFiles(.{
            .root = b.path("mcux-devices-mcx/MCXE/MCXE247/drivers"),
            .files = &.{
                "fsl_clock.c",
            },
            .flags = &.{
                "-std=c99",
                "-Og",
                "-ffunction-sections",
                "-fdata-sections",
                "-DCPU_MCXE247VLQ",
            },
        });
    }
    // MCXA156 (future support)
    else if (std.mem.eql(u8, device, "MCXA156")) {
        lib.installHeadersDirectory(b.path("mcux-devices-mcx/MCXA/MCXA156"), "mcux-devices-mcx/include", .{});
    }

    b.installArtifact(lib);
}
