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

    // Install headers based on selected device
    // MCXE247 (default for FRDM-MCXE247 board)
    if (std.mem.eql(u8, device, "MCXE247")) {
        lib.installHeadersDirectory(b.path("mcux-devices-mcx/MCXE/MCXE247"), "mcux-devices-mcx/include", .{});
        lib.installHeadersDirectory(b.path("mcux-devices-mcx/MCXE/periph0"), "mcux-devices-mcx/include", .{});
        lib.installHeadersDirectory(b.path("mcux-devices-mcx/MCXE/MCXE247/drivers"), "mcux-devices-mcx/include", .{});
    }
    // MCXA156 (future support)
    else if (std.mem.eql(u8, device, "MCXA156")) {
        lib.installHeadersDirectory(b.path("mcux-devices-mcx/MCXA/MCXA156"), "mcux-devices-mcx/include", .{});
    }

    b.installArtifact(lib);
}
