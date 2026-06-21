// Copyright 2025 Francisco Llobet-Blandino
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .name = "lwip",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/sys_arch.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const c_flags = &.{
        "-std=c99",
        "-ffunction-sections",
        "-fdata-sections",
        "-fno-common",
        // Suppress UBSan instrumentation: each pointer check emits a 20-byte
        // .data record; with thousands of checks across lwIP this bloats SRAM.
        "-fno-sanitize=undefined",
        // lwIP uses flexible array structs internally; silence GCC -Waddress
        "-Wno-address",
    };

    // =========================================================================
    // lwIP core protocol stack
    // =========================================================================
    lib.root_module.addCSourceFiles(.{
        .root = b.path("lwip/src/core"),
        .files = &.{
            "init.c",
            "def.c",
            "dns.c",
            "inet_chksum.c",
            "ip.c",
            "mem.c",
            "memp.c",
            "netif.c",
            "pbuf.c",
            "raw.c",
            "stats.c",
            "sys.c",
            "altcp.c",
            "altcp_alloc.c",
            "altcp_tcp.c",
            "tcp.c",
            "tcp_in.c",
            "tcp_out.c",
            "timeouts.c",
            "udp.c",
        },
        .flags = c_flags,
    });

    // =========================================================================
    // IPv4 stack (DHCP, ARP, ICMP, IGMP, IP fragmentation)
    // =========================================================================
    lib.root_module.addCSourceFiles(.{
        .root = b.path("lwip/src/core/ipv4"),
        .files = &.{
            "acd.c",
            "autoip.c",
            "dhcp.c",
            "etharp.c",
            "icmp.c",
            "igmp.c",
            "ip4.c",
            "ip4_addr.c",
            "ip4_frag.c",
        },
        .flags = c_flags,
    });

    // =========================================================================
    // Ethernet netif glue
    // =========================================================================
    lib.root_module.addCSourceFiles(.{
        .root = b.path("lwip/src/netif"),
        .files = &.{
            "ethernet.c",
        },
        .flags = c_flags,
    });

    // =========================================================================
    // API layer (err.c is always needed; full api/ requires NO_SYS=0)
    // =========================================================================
    lib.root_module.addCSourceFiles(.{
        .root = b.path("lwip/src/api"),
        .files = &.{
            "api_lib.c",
            "api_msg.c",
            "err.c",
            "tcpip.c",
            "if_api.c",
            "netifapi.c",
            "netdb.c",
            "netbuf.c",
            "sockets.c",
        },
        .flags = c_flags,
    });

    // sys_arch is provided by the Zig module (src/sys_arch.zig), not a C file.
    // Consumer must inject before building (see lwip module comment below).

    // =========================================================================
    // Include paths
    // =========================================================================

    // lwIP public headers: <lwip/xxx.h>, <netif/xxx.h>, <arch/xxx.h>
    lib.root_module.addIncludePath(b.path("lwip/src/include"));
    // picolibc for stdint.h, string.h, etc.
    lib.root_module.addIncludePath(b.path("../picolibc/include"));
    // arch/cc.h and arch/sys_arch.h live here.
    // lwipopts.h is NOT here — it must be injected by the consumer (board).
    lib.root_module.addIncludePath(b.path("src"));

    // =========================================================================
    // Export headers for consumers
    // =========================================================================

    lib.installHeadersDirectory(
        b.path("lwip/src/include"),
        "lwip/include",
        .{ .include_extensions = &.{".h"} },
    );
    // Export arch/cc.h and arch/sys_arch.h. lwipopts.h is board-owned and
    // not exported from here — the board re-exports it via its own install step.
    lib.installHeadersDirectory(
        b.path("src/arch"),
        "lwip/include/arch",
        .{ .include_extensions = &.{".h"} },
    );

    b.installArtifact(lib);

    // =========================================================================
    // Zig module — root is sys_arch.zig which re-exports the lwIP C API and
    // provides all sys_arch symbols.  Consumer must inject before build:
    //   lwip_mod.addImport("cmsis_rtx", cmsis_rtx_mod)
    //   lwip_mod.addIncludePath(<board>/lwip_config/)     -- lwipopts.h
    //   lwip_mod.addIncludePath(<cmsis_6>/rtos2/include)  -- cmsis_os2.h
    //   lwip_mod.addIncludePath(<cmsis_6>/core/include)   -- __get_IPSR
    // =========================================================================
    const mod = b.addModule("lwip", .{
        .root_source_file = b.path("src/sys_arch.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.addIncludePath(b.path("lwip/src/include"));
    mod.addIncludePath(b.path("../picolibc/include"));
    mod.addIncludePath(b.path("src"));
}
