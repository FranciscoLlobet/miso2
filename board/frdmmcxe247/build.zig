const std = @import("std");

// Although this function looks imperative, it does not perform the build
// directly and instead it mutates the build graph (`b`) that will be then
// executed by an external runner. The functions in `std.Build` implement a DSL
// for defining build steps and express dependencies between them, allowing the
// build runner to parallelize the build automatically (and the cache system to
// know when a step doesn't need to be re-run).
pub fn build(b: *std.Build) void {
    // Standard target options allow the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    //const target = b.standardTargetOptions(.{});
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .abi = .eabihf,
        .cpu_model = .{
            .explicit = &std.Target.arm.cpu.cortex_m4,
        },
    });
    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});
    // It's also possible to define more custom flags to toggle optional features
    // of this build script using `b.option()`. All defined flags (including
    // target and optimize options) will be listed when running `zig build --help`
    // in this directory.

    // This creates a module, which represents a collection of source files alongside
    // some compilation options, such as optimization mode and linked system libraries.
    // Zig modules are the preferred way of making Zig code available to consumers.
    // addModule defines a module that we intend to make available for importing
    // to our consumers. We must give it a name because a Zig package can expose
    // multiple modules and consumers will need to be able to specify which
    // module they want to access.
    //const lib_mod = b.createModule(.{
    //    .root_source_file = b.path("src/root.zig"),
    //    .target = target,
    //    .optimize = optimize,
    //});

    const mcux_devices_mcx = b.dependency("mcux_devices_mcx", .{
        .target = target,
        .optimize = optimize,
    });
    const mcuxsdk_core = b.dependency("mcuxsdk_core", .{
        .target = target,
        .optimize = optimize,
    });
    const cmsis_6 = b.dependency("cmsis_6", .{
        .target = target,
        .optimize = optimize,
    });

    // Create a Zig module for board-specific code (Zig only, no C files)
    const board = b.addModule("board", .{
        .root_source_file = b.path("src/board.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create a static library for C board support files
    // This library contains only C code and assembly, no Zig root module
    const lib = b.addLibrary(.{
        .name = "board",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    // Board startup file
    lib.root_module.addAssemblyFile(b.path("startup/startup_MCXE247.S"));

    // Board C files (compiled into the static library only, not propagated to consumers)
    lib.root_module.addCSourceFiles(.{
        .root = b.path("."),
        .files = &.{
            "board/clock_config.c",
            "board/peripherals.c",
            "board/pin_mux.c",
            "board/system_MCXE247.c",
            "board/picolibc_stubs.c", // Picolibc runtime stubs
        },
        .flags = &.{
            "-std=c99",
            "-Og",
            "-ffunction-sections",
            "-fdata-sections",
            "-DCPU_MCXE247VLQ",
            "-D__START=zmain",
        },
    });

    board.addCMacro("CPU_MCXE247VLQ", "1");
    board.addCMacro("__ARM_ARCH_PROFILE", "M");
    board.addIncludePath(b.path("board"));
    board.addIncludePath(b.path("../../external/picolibc/include"));
    board.addIncludePath(mcuxsdk_core.artifact("mcuxsdk-core").getEmittedIncludeTree().path(b, "mcuxsdk-core/include"));
    board.addIncludePath(mcux_devices_mcx.artifact("mcux-devices-mcx").getEmittedIncludeTree().path(b, "mcux-devices-mcx/include"));
    board.addIncludePath(cmsis_6.artifact("CMSIS_6").getEmittedIncludeTree().path(b, "cmsis_6/core/include"));

    // Add include paths for C compilation
    lib.root_module.addIncludePath(b.path("../../external/picolibc/include"));
    lib.root_module.addIncludePath(mcuxsdk_core.artifact("mcuxsdk-core").getEmittedIncludeTree().path(b, "mcuxsdk-core/include"));
    lib.root_module.addIncludePath(mcux_devices_mcx.artifact("mcux-devices-mcx").getEmittedIncludeTree().path(b, "mcux-devices-mcx/include"));
    lib.root_module.addIncludePath(cmsis_6.artifact("CMSIS_6").getEmittedIncludeTree().path(b, "cmsis_6/core/include"));

    // Link device-specific libraries (contains fsl_clock.c and device drivers)
    lib.root_module.linkLibrary(mcux_devices_mcx.artifact("mcux-devices-mcx"));
    lib.root_module.linkLibrary(mcuxsdk_core.artifact("mcuxsdk-core"));

    b.installArtifact(lib);
}
