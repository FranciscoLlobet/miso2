//! By convention, root.zig is the root source file when making a package.
const std = @import("std");

const c = @import("c.zig");

const MQTTTransport = c.MQTTTransport;
const MQTTString = c.MQTTString;
const MQTTLenString = c.MQTTLenString;

/// MQTT OK return code
/// Used internally to check the return code of the MQTTPacket functions
const mqtt_ok: c_int = 1;

/// Message types from MQTTPacket
const msgTypes = enum(c_int) {
    err_msg = -1,
    try_again = 0,
    connect = c.CONNECT,
    connack = c.CONNACK,
    publish = c.PUBLISH,
    puback = c.PUBACK,
    pubrec = c.PUBREC,
    pubrel = c.PUBREL,
    pubcomp = c.PUBCOMP,
    subscribe = c.SUBSCRIBE,
    suback = c.SUBACK,
    unsubscribe = c.UNSUBSCRIBE,
    unsuback = c.UNSUBACK,
    pingreq = c.PINGREQ,
    pingresp = c.PINGRESP,
    disconnect = c.DISCONNECT,
};

//// Mqtt Error codes
pub const mqtt_error = error{
    packetlen,
    enqueue_failed,
    dequeue_failed,
    connect_failed,
    send_failed,
    connack_failed,
    parse_failed,
    publish_parse_failed,
    subscribe_qos_topic_count_mismatch, // The number of topics and qos do not match
    qos_not_supported,

    qos_packet_not_found,
    pubrel_packet_not_found,
    qos_packet_timeout,
};

/// MQTT String initializer
const MQTTString_initializer = MQTTString{
    .cstring = null,
    .lenstring = .{
        .len = 0,
        .data = null,
    },
};

/// Manually translated initializer
const MQTTPacket_willOptions_initializer = c.MQTTPacket_willOptions{
    .struct_id = [_]u8{ 'M', 'Q', 'T', 'W' },
    .struct_version = 0,
    .topicName = MQTTString_initializer,
    .message = MQTTString_initializer,
    .retained = 0,
    .qos = 0,
};

/// Manually translated initializer
const MQTTPacket_connectData_initializer = c.MQTTPacket_connectData{
    .struct_id = [_]u8{ 'M', 'Q', 'T', 'C' },
    .struct_version = 0,
    .MQTTVersion = 4,
    .clientID = MQTTString_initializer,
    .keepAliveInterval = 0,
    .cleansession = 1,
    .willFlag = 0,
    .will = MQTTPacket_willOptions_initializer,
    .username = MQTTString_initializer,
    .password = MQTTString_initializer,
};

/// Init a MQTT String using slice.
/// Has been tested in comptime
inline fn initMQTTString(data: ?[]const u8) MQTTString {
    if (data) |val| {
        return MQTTString{
            .cstring = null,
            .lenstring = .{
                .len = @intCast(val.len),
                .data = @constCast(val.ptr),
            },
        };
    } else {
        return MQTTString_initializer;
    }
}

/// Get MQTT String as slice
inline fn getMQTTString(data: MQTTString) []u8 {
    if (data.cstring) |cstring| {
        return cstring[0..c.strlen(cstring)];
    } else if ((data.lenstring.data != null) and (data.lenstring.len > 0)) {
        return data.lenstring.data[0..@intCast(data.lenstring.len)];
    } else {
        return undefined;
    }
}

/// Quality of Service
const QoS = enum(c_int) {
    qos0 = 0,
    qos1 = 1,
    qos2 = 2,

    fn fromInt(x: c_int) !QoS {
        return switch (x) {
            0 => .qos0,
            1 => .qos1,
            2 => .qos2,
            else => mqtt_error.qos_not_supported,
        };
    }
};

const publish_response = struct {
    packetId: u16,
    qos: QoS,
    dup: bool,
    retained: bool,
    topic: []u8,
    payload: []u8,
};

/// Deserialization methods
const deserialize = struct {
    /// Deserialize a publish packet from buffer and converts it into a `publish_response`
    fn publish(buffer: []const u8) mqtt_error!publish_response {
        var topicName = MQTTString_initializer;
        var payload: [*c]u8 = undefined;
        var payloadLen: isize = undefined;
        var packetId: u16 = 0;
        var retained: u8 = undefined;
        var dup: u8 = undefined;
        var qos: c_int = undefined;

        if (mqtt_ok != c.MQTTDeserialize_publish(&dup, &qos, &retained, &packetId, &topicName, &payload, &payloadLen, @constCast(buffer.ptr), @intCast(buffer.len))) {
            return mqtt_error.parse_failed;
        }

        const retQos = try QoS.fromInt(qos);

        return publish_response{ .packetId = packetId, .qos = retQos, .dup = (if (dup == 0) false else true), .retained = (if (retained == 0) false else true), .topic = getMQTTString(topicName), .payload = payload[0..@intCast(payloadLen)] };
    }

    fn puback(buffer: []const u8) mqtt_error!struct { packetId: u16, dup: bool } {
        var packetId: u16 = undefined;
        var dup: u8 = undefined;
        var packetType: u8 = undefined;

        if (mqtt_ok != c.MQTTDeserialize_ack(&packetType, &dup, &packetId, @constCast(buffer.ptr), @intCast(buffer.len))) {
            return mqtt_error.parse_failed;
        }
        if (packetType != c.PUBACK) {
            return mqtt_error.parse_failed; // Not actually a puback when expected
        }
        return .{ .packetId = packetId, .dup = (if (dup == 0) false else true) };
    }

    /// Deserialize a pubrel packet from buffer
    fn pubrel(buffer: []const u8) mqtt_error!struct { packetId: u16, dup: bool } {
        var packetId: u16 = undefined;
        var dup: u8 = undefined;
        var packetType: u8 = undefined;

        if (mqtt_ok != c.MQTTDeserialize_ack(&packetType, &dup, &packetId, @constCast(buffer.ptr), @intCast(buffer.len))) {
            return mqtt_error.parse_failed;
        }
        if (packetType != c.PUBREL) {
            return mqtt_error.parse_failed; // Not actually a pubrel when expected
        }
        return .{ .packetId = packetId, .dup = (if (dup == 0) false else true) };
    }

    /// Deserialize a pubrec packet from buffer
    fn pubrec(buffer: []const u8) mqtt_error!u16 {
        var packetId: u16 = undefined;
        var dup: u8 = undefined;
        var packetType: u8 = undefined;

        if (mqtt_ok != c.MQTTDeserialize_ack(
            &packetType,
            &dup,
            &packetId,
            @constCast(buffer.ptr),
            @intCast(buffer.len),
        )) {
            return mqtt_error.parse_failed;
        }
        if (packetType != c.PUBREC) {
            return mqtt_error.parse_failed; // Not actually a pubrec when expected
        }

        return packetId;
    }

    /// Deserialize a pubcomp packet from buffer
    fn pubcomp(buffer: []const u8) mqtt_error!u16 {
        var packetId: u16 = undefined;
        var dup: u8 = undefined;
        var packetType: u8 = undefined;

        if (mqtt_ok != c.MQTTDeserialize_ack(
            &packetType,
            &dup,
            &packetId,
            @constCast(buffer.ptr),
            @intCast(buffer.len),
        )) {
            return mqtt_error.parse_failed;
        }
        if (packetType != c.PUBCOMP) {
            return mqtt_error.parse_failed; // Not actually a pubcomp when expected
        }

        return packetId;
    }

    /// Deserialize a suback packet from buffer
    fn suback(buffer: []const u8, qos: []QoS) mqtt_error!struct {
        packetId: u16,
        qos: []QoS,
    } {
        var packetId: u16 = undefined;
        var count: c_int = 0;

        if (mqtt_ok != c.MQTTDeserialize_suback(
            &packetId,
            @intCast(qos.len),
            &count,
            @ptrCast(qos.ptr),
            @constCast(buffer.ptr),
            @intCast(buffer.len),
        )) {
            return mqtt_error.parse_failed;
        }
        return .{
            .packetId = packetId,
            .qos = qos[0..@as(usize, @intCast(count))],
        };
    }

    /// Process the connack packet
    fn connack(buffer: []u8) mqtt_error!void {
        var sessionPresent: u8 = undefined;
        var connack_rc: u8 = undefined;

        if (mqtt_ok == c.MQTTDeserialize_connack(
            &sessionPresent,
            &connack_rc,
            @ptrCast(&buffer[0]),
            @intCast(buffer.len),
        )) {
            if (connack_rc != c.MQTT_CONNECTION_ACCEPTED) {
                return mqtt_error.connack_failed;
            }
        } else {
            return mqtt_error.parse_failed;
        }
    }
};

const sendToQueueFn = *const fn (buffer: []u8, packetId: ?u16) u16;

const serialize = struct {
    /// Check the output of the MQTTSerialize_xyz functions for error returns and avoids buffer overflows
    /// Returns a slice of the workBuffer
    fn serializeCheck(
        workBuffer: []u8,
        packetLen: isize,
    ) mqtt_error![]u8 {
        if (packetLen <= 0) {
            return mqtt_error.packetlen; // Could not serialize packet
        } else if (packetLen > workBuffer.len) {
            return mqtt_error.packetlen; // Packet too big fow workBuffer
        } else {
            return workBuffer[0..@intCast(packetLen)];
        }
    }

    /// Prepare a connect packet
    fn connect(
        workBuffer: []u8,
        clientID: []const u8,
        username: ?[]const u8,
        password: ?[]const u8,
    ) mqtt_error!struct {
        packetBuffer: []u8,
        packetId: ?u16,
    } {
        var connectPacket = MQTTPacket_connectData_initializer;

        connectPacket.clientID = initMQTTString(clientID);
        connectPacket.username = initMQTTString(username);
        connectPacket.password = initMQTTString(password);

        connectPacket.keepAliveInterval = 400;

        return .{
            .packetBuffer = try serializeCheck(
                workBuffer,
                c.MQTTSerialize_connect(
                    @ptrCast(&workBuffer[0]),
                    workBuffer.len,
                    &connectPacket,
                ),
            ),
            .packetId = null,
        };
    }

    /// Prepare the puback packet and sends to TX Queue
    fn puback(
        workBuffer: []u8,
        packetId: u16,
    ) mqtt_error![]u8 {
        return serializeCheck(
            c.MQTTSerialize_puback(
                @ptrCast(&workBuffer[0]),
                workBuffer.len,
                packetId,
            ),
        );
    }

    /// Prepare the pubrec packet and sends to TX Queue
    fn pubrec(
        workBuffer: []u8,
        packetId: u16,
    ) mqtt_error![]u8 {
        return serializeCheck(
            c.MQTTSerialize_pubrec(
                @ptrCast(&workBuffer[0]),
                workBuffer.len,
                packetId,
            ),
        );
    }

    /// Prepare the pubcomp packet and sends to TX Queue
    fn pubcomp(
        workBuffer: []u8,
        packetId: u16,
    ) mqtt_error![]u8 {
        return serializeCheck(
            c.MQTTSerialize_pubcomp(
                @ptrCast(&workBuffer[0]),
                workBuffer.len,
                packetId,
            ),
        );
    }

    /// Prepare the `pubrel` packet and sends to TX Queue
    fn pubrel(
        workBuffer: []u8,
        packetId: u16,
        dup: bool,
    ) mqtt_error![]u8 {
        return serializeCheck(
            c.MQTTSerialize_pubrel(
                @ptrCast(&workBuffer[0]),
                workBuffer.len,
                @intFromBool(dup),
                packetId,
            ),
        );
    }

    /// Prepare the subscribe packet and sends to TX Queue
    /// Both topicFilter and qos must have the same length
    fn subscribe(
        workBuffer: []u8,
        packetId: u16,
        topicFilter: []MQTTString,
        qos: []QoS,
    ) mqtt_error![]u8 {
        const count = if (topicFilter.len == qos.len) topicFilter.len else return mqtt_error.subscribe_qos_topic_count_mismatch;
        const dup: u8 = 0;

        return serializeCheck(
            c.MQTTSerialize_subscribe(
                @ptrCast(&workBuffer[0]),
                workBuffer.len,
                dup,
                packetId,
                @intCast(count),
                topicFilter.ptr,
                @ptrCast(qos.ptr),
            ),
        );
    }

    /// Prepare a ping packet and sends to TX Queue
    fn ping(
        workBuffer: []u8,
    ) mqtt_error![]u8 {
        return serializeCheck(
            c.MQTTSerialize_pingreq(
                @ptrCast(&workBuffer[0]),
                workBuffer.len,
            ),
        );
    }

    /// prepare a disconnect packet and sends to TX Queue
    fn disconnect(
        workBuffer: []u8,
    ) mqtt_error![]u8 {
        return serializeCheck(
            c.MQTTSerialize_disconnect(
                @ptrCast(&workBuffer[0]),
                workBuffer.len,
            ),
        );
    }

    /// Prepare a publish packet and sends to TX Queue
    pub fn publish(
        workBuffer: []u8,
        topic: []const u8,
        payload: []const u8,
        qos: QoS,
        dup: bool,
        packetId: u16,
    ) mqtt_error![]u8 {
        const topic_name = initMQTTString(topic);
        const retain: u8 = 0;

        return serializeCheck(
            c.MQTTSerialize_publish(
                &workBuffer[0],
                workBuffer.len,
                if (dup) 1 else 0,
                @intFromEnum(qos),
                retain,
                packetId,
                topic_name,
                @constCast(payload.ptr),
                @intCast(payload.len),
            ),
        );
    }
};
