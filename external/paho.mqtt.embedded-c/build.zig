// Copyright 2026 Francisco Llobet-Blandino
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

    // Consumer injects the CMSIS device header filename via b.dependency("cmsis_rtx", .{ .device_header = "..." })
    // RTX_Config.h and device register include paths must also be injected by the consumer.
    //const device_header = b.option([]const u8, "device_header", "CMSIS device header filename (e.g. fsl_device_registers.h)") orelse "fsl_device_registers.h";

    //const cmsis_6 = b.dependency("cmsis_6", .{
    //    .target = target,
    //    .optimize = optimize,
    //});

    const lib = b.addLibrary(.{
        .name = "paho_mqtt_embedded_c",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    const mod = b.addModule("paho_mqtt_embedded_c", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    //const device_header_flag = std.fmt.allocPrint(
    //    b.allocator,
    //    "-DCMSIS_device_header=\"{s}\"",
    //    .{device_header},
    //) catch @panic("OOM");

    lib.root_module.addCSourceFiles(.{
        .files = &.{
            "paho.mqtt.embedded-c/MQTTPacket/src/MQTTFormat.c",
            "paho.mqtt.embedded-c/MQTTPacket/src/MQTTPacket.c",
            "paho.mqtt.embedded-c/MQTTPacket/src/MQTTSerializePublish.c",
            "paho.mqtt.embedded-c/MQTTPacket/src/MQTTDeserializePublish.c",
            "paho.mqtt.embedded-c/MQTTPacket/src/MQTTConnectClient.c",
            "paho.mqtt.embedded-c/MQTTPacket/src/MQTTSubscribeClient.c",
            "paho.mqtt.embedded-c/MQTTPacket/src/MQTTUnsubscribeClient.c",
        },
        .flags = &.{
            "-std=c99",
            "-DMQTT_CLIENT=1",
            // Skip RTE Pack infrastructure header; not used in standalone builds
            //"-DRTE_COMPONENTS_H",
            "-O2",
            "-ffunction-sections",
            "-fdata-sections",
        },
    });

    // RTX internal headers
    lib.root_module.addIncludePath(b.path("paho.mqtt.embedded-c/MQTTPacket/src/"));
    // CMSIS Core + RTOS2
    //lib.root_module.addIncludePath(cmsis_6.artifact("CMSIS_6").getEmittedIncludeTree().path(b, "cmsis_6/core/include"));
    //lib.root_module.addIncludePath(cmsis_6.artifact("CMSIS_6").getEmittedIncludeTree().path(b, "cmsis_6/rtos2/include"));
    // Stdlib
    lib.root_module.addIncludePath(b.path("../../external/picolibc/include"));

    // Consumer must inject RTX_Config.h dir and device register include path
    // (via addIncludePath on this artifact's root_module and on this module)

    lib.installHeadersDirectory(b.path("paho.mqtt.embedded-c/MQTTPacket/src/"), "paho_mqtt_embedded_c/include", .{});

    // Mirror includes on the Zig module for @cImport in src/c.zig
    mod.addIncludePath(b.path("paho.mqtt.embedded-c/MQTTPacket/src"));
    //mod.addIncludePath(cmsis_6.artifact("CMSIS_6").getEmittedIncludeTree().path(b, "cmsis_6/core/include"));
    //mod.addIncludePath(cmsis_6.artifact("CMSIS_6").getEmittedIncludeTree().path(b, "cmsis_6/rtos2/include"));
    mod.addIncludePath(b.path("../../external/picolibc/include"));

    b.installArtifact(lib);
}
