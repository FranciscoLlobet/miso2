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
    const mcux_component = b.dependency("mcux_component", .{
        .target = target,
        .optimize = optimize,
    });
    const cmsis_rtx_dep = b.dependency("cmsis_rtx", .{
        .target = target,
        .optimize = optimize,
        .device_header = @as([]const u8, "fsl_device_registers.h"),
    });
    const cmsis_rtx_lib = cmsis_rtx_dep.artifact("cmsis_rtx");
    const cmsis_rtx_mod = cmsis_rtx_dep.module("cmsis_rtx");

    const lwip_dep = b.dependency("lwip", .{
        .target = target,
        .optimize = optimize,
    });
    const lwip_lib = lwip_dep.artifact("lwip");
    const lwip_mod = lwip_dep.module("lwip");

    // Inject board-owned lwipopts.h and CMSIS headers into the lwip package —
    // analogous to how rtx_config/ and device headers are injected into cmsis_rtx.
    // lwipopts.h lives in lwip_config/ (board-specific configuration).
    // CMSIS-RTOS2 headers (cmsis_os2.h) and core headers (__get_IPSR) are needed
    // by lwip/src/sys_arch.c which uses CMSIS-RTOS2 API.
    const lwip_config_path = b.path("lwip_config");
    const cmsis_core_inc   = cmsis_6.artifact("CMSIS_6").getEmittedIncludeTree().path(b, "cmsis_6/core/include");
    const cmsis_rtos2_inc  = cmsis_6.artifact("CMSIS_6").getEmittedIncludeTree().path(b, "cmsis_6/rtos2/include");
    lwip_lib.root_module.addIncludePath(lwip_config_path);
    lwip_lib.root_module.addIncludePath(cmsis_rtos2_inc);
    lwip_lib.root_module.addIncludePath(cmsis_core_inc);
    lwip_lib.root_module.addImport("cmsis_rtx", cmsis_rtx_mod);
    lwip_mod.addIncludePath(lwip_config_path);
    lwip_mod.addIncludePath(cmsis_rtos2_inc);
    lwip_mod.addIncludePath(cmsis_core_inc);
    lwip_mod.addImport("cmsis_rtx", cmsis_rtx_mod);

    // Create a Zig module for board-specific code (Zig only, no C files)
    const board = b.addModule("board", .{
        .root_source_file = b.path("src/board.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Include paths for @cImport in board.zig and any driver code that imports
    // this module.  Note: __ARM_ARCH_PROFILE is intentionally NOT set here —
    // Zig's clang defines it correctly ('M') for cortex_m4 automatically.
    // Setting it to the bare identifier M (not the char literal 'M') breaks
    // the cmsis_gcc.h architecture check.
    board.addCMacro("CPU_MCXE247VLQ", "1");
    board.addIncludePath(b.path("src")); // for cimport.h
    board.addIncludePath(b.path("board"));
    board.addIncludePath(b.path("board/ethernet"));
    board.addIncludePath(b.path("../../external/picolibc/include"));
    board.addIncludePath(mcuxsdk_core.artifact("mcuxsdk-core").getEmittedIncludeTree().path(b, "mcuxsdk-core/include"));
    board.addIncludePath(mcux_devices_mcx.artifact("mcux-devices-mcx").getEmittedIncludeTree().path(b, "mcux-devices-mcx/include"));
    board.addIncludePath(cmsis_6.artifact("CMSIS_6").getEmittedIncludeTree().path(b, "cmsis_6/core/include"));
    board.addIncludePath(cmsis_6.artifact("CMSIS_6").getEmittedIncludeTree().path(b, "cmsis_6/rtos2/include"));
    board.addIncludePath(mcux_component.artifact("mcux-component").getEmittedIncludeTree().path(b, "mcux-component/include"));
    board.addIncludePath(lwip_lib.getEmittedIncludeTree().path(b, "lwip/include"));
    board.addIncludePath(lwip_config_path);

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

    // Module-level macro: addAssemblyFile does not inherit per-file C flags,
    // so the BSS-clear guard must be set at module level to reach the assembler.
    lib.root_module.addCMacro("__STARTUP_CLEAR_BSS", "1");

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
            "board/picolibc_stubs.c",
            "board/ethernet/enet_ethernetif.c",
            "board/ethernet/enet_ethernetif_kinetis.c",
            "board/ethernet/ethernetif.c",
            "board/ethernet/ethernetif_mmac.c",
            "board/ethernet/sys_arch.c",
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

    // Add include paths for C compilation
    lib.root_module.addIncludePath(b.path("../../external/picolibc/include"));
    lib.root_module.addIncludePath(mcuxsdk_core.artifact("mcuxsdk-core").getEmittedIncludeTree().path(b, "mcuxsdk-core/include"));
    lib.root_module.addIncludePath(mcux_devices_mcx.artifact("mcux-devices-mcx").getEmittedIncludeTree().path(b, "mcux-devices-mcx/include"));
    lib.root_module.addIncludePath(cmsis_6.artifact("CMSIS_6").getEmittedIncludeTree().path(b, "cmsis_6/core/include"));
    lib.root_module.addIncludePath(cmsis_6.artifact("CMSIS_6").getEmittedIncludeTree().path(b, "cmsis_6/rtos2/include"));
    lib.root_module.addIncludePath(mcux_component.artifact("mcux-component").getEmittedIncludeTree().path(b, "mcux-component/include"));
    lib.root_module.addIncludePath(lwip_lib.getEmittedIncludeTree().path(b, "lwip/include"));
    lib.root_module.addIncludePath(lwip_config_path);

    // Link device-specific libraries (contains fsl_clock.c and device drivers)
    lib.root_module.linkLibrary(mcux_devices_mcx.artifact("mcux-devices-mcx"));
    lib.root_module.linkLibrary(mcuxsdk_core.artifact("mcuxsdk-core"));
    lib.root_module.linkLibrary(mcux_component.artifact("mcux-component"));
    lib.root_module.linkLibrary(lwip_lib);

    // Inject board RTX config and NXP device headers into cmsis_rtx
    cmsis_rtx_lib.root_module.addCMacro("CPU_MCXE247VLQ", "1");
    const rtx_config_path = b.path("rtx_config");
    const device_include = mcux_devices_mcx.artifact("mcux-devices-mcx")
        .getEmittedIncludeTree().path(b, "mcux-devices-mcx/include");
    cmsis_rtx_lib.root_module.addIncludePath(rtx_config_path);
    cmsis_rtx_lib.root_module.addIncludePath(device_include);
    cmsis_rtx_mod.addIncludePath(rtx_config_path);
    cmsis_rtx_mod.addIncludePath(device_include);

    // Make cmsis_rtx available for import inside board.zig
    board.addImport("cmsis_rtx", cmsis_rtx_mod);

    // Link cmsis_rtx into the board lib so root only needs to link board
    lib.root_module.linkLibrary(cmsis_rtx_lib);

    // Expose the configured cmsis_rtx module directly to consumers of this package.
    // b.modules is the authoritative map that b.dependency().module() reads from.
    b.modules.put(b.allocator, b.dupe("cmsis_rtx"), cmsis_rtx_mod) catch @panic("OOM");
    b.modules.put(b.allocator, b.dupe("lwip"), lwip_mod) catch @panic("OOM");

    b.installArtifact(lib);
}
