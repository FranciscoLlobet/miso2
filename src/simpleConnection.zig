// Copyright (c) 2023-2024 Francisco Llobet-Blandino and the "Miso Project".
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

const std = @import("std");
const rtx = @import("cmsis_rtx");
const lwip = @import("lwip");

const connection = @import("connection.zig");
const conn_error = connection.connection_error;

const c = lwip.c;

const INVALID_SOCKET: c_int = -1;

const ipv4Peer = struct {
    addr: c.sockaddr_in,

    pub fn create(addr: u32, port: u16) @This() {
        return .{
            .addr = .{
                .sin_len = @sizeOf(c.sockaddr_in),
                .sin_family = c.AF_INET,
                .sin_port = @byteSwap(port),
                .sin_addr = .{ .s_addr = @byteSwap(addr) },
                .sin_zero = std.mem.zeroes([8]u8),
            },
        };
    }

    pub inline fn sockLen(_: *const @This()) c.socklen_t {
        return @sizeOf(c.sockaddr_in);
    }

    pub inline fn asAddr(self: *@This()) *c.sockaddr {
        return @ptrCast(&self.addr);
    }
};

/// Experimental — IPv6 support not yet validated.
const ipv6Peer = struct {
    addr: c.sockaddr_in6,

    pub fn create(_: u128, port: u16) @This() {
        var a = std.mem.zeroes(c.sockaddr_in6);
        a.sin6_len = @sizeOf(c.sockaddr_in6);
        a.sin6_family = c.AF_INET6;
        a.sin6_port = @byteSwap(port);
        return .{ .addr = a };
    }

    pub inline fn sockLen(_: *const @This()) c.socklen_t {
        return @sizeOf(c.sockaddr_in6);
    }

    pub inline fn asAddr(self: *@This()) *c.sockaddr {
        return @ptrCast(&self.addr);
    }
};

fn mapProto(proto: connection.proto) struct {
    family: c_int,
    sock_type: c_int,
    protocol: c_int,
} {
    return .{
        .family = if (proto.isIp6()) c.AF_INET6 else c.AF_INET,
        .sock_type = if (proto.isStream()) c.SOCK_STREAM else c.SOCK_DGRAM,
        .protocol = if (proto.isUdp()) c.IPPROTO_UDP else c.IPPROTO_TCP,
    };
}

pub fn LwipConnection(comptime proto: connection.proto) type {
    const settings = mapProto(proto);

    return struct {
        proto: connection.proto = proto,
        sd: c_int,
        peer: if (proto.isIp6()) ipv6Peer else ipv4Peer,
        local: if (proto.isIp6()) ipv6Peer else ipv4Peer,

        pub fn create() @This() {
            return .{
                .proto = proto,
                .sd = INVALID_SOCKET,
                .peer = @TypeOf(@This().peer).create(0, 0),
                .local = @TypeOf(@This().local).create(0, 0),
            };
        }

        pub fn init(self: *@This()) !void {
            self.sd = INVALID_SOCKET;
        }

        pub fn deinit(_: *@This()) !void {}

        pub fn open(self: *@This(), uri: std.Uri, local_port: ?u16) !void {
            const host_component = uri.host orelse return conn_error.dns;
            const host_str = switch (host_component) {
                .raw, .percent_encoded => |s| s,
            };
            const port = uri.port orelse return conn_error.dns;

            // Null-terminate the host string for netconn_gethostbyname.
            var host_buf: [256]u8 = undefined;
            if (host_str.len >= host_buf.len) return conn_error.dns;
            @memcpy(host_buf[0..host_str.len], host_str);
            host_buf[host_str.len] = 0;

            var ip_addr: c.ip_addr_t = undefined;
            if (c.netconn_gethostbyname(&host_buf, &ip_addr) != 0) {
                return conn_error.dns;
            }

            // Build the peer address from the resolved IP and URI port.
            // ip_addr.u_addr.ip4.addr is already in network byte order,
            // matching what sockaddr_in.sin_addr.s_addr expects.
            self.peer = @TypeOf(self.peer).create(0, port);
            if (comptime proto.isIp6()) {
                self.peer.addr.sin6_addr = ip_addr.u_addr.ip6;
            } else {
                self.peer.addr.sin_addr.s_addr = ip_addr.addr;
            }

            try self.openSocket();
            errdefer self.close() catch {};

            self.local = @TypeOf(self.local).create(0, local_port orelse 0);
            if (local_port) |_| {
                if (c.lwip_bind(self.sd, self.local.asAddr(), self.local.sockLen()) != 0) {
                    return conn_error.connect;
                }
            }

            try self.connect();
        }

        fn openSocket(self: *@This()) !void {
            self.sd = c.lwip_socket(settings.family, settings.sock_type, settings.protocol);
            if (self.sd < 0) return conn_error.socket;
        }

        fn connect(self: *@This()) !void {
            if (c.lwip_connect(self.sd, self.peer.asAddr(), self.peer.sockLen()) != 0) {
                return conn_error.connect;
            }
        }

        inline fn send_tcp(self: *@This(), data: []const u8) isize {
            return c.lwip_send(self.sd, data.ptr, data.len, 0);
        }

        inline fn send_udp(self: *@This(), data: []const u8) isize {
            return c.lwip_sendto(self.sd, data.ptr, data.len, 0, self.peer.asAddr(), self.peer.sockLen());
        }

        inline fn recieve_tcp(self: *@This(), data: []u8) isize {
            return c.lwip_recv(self.sd, data.ptr, data.len, 0);
        }

        inline fn recieve_udp(self: *@This(), data: []u8) isize {
            var peer_len: c.socklen_t = self.peer.sockLen();
            return c.lwip_recvfrom(self.sd, data.ptr, data.len, 0, self.peer.asAddr(), &peer_len);
        }

        pub const send_c = if (proto.isTcp()) send_tcp else send_udp;
        pub const recieve_c = if (proto.isTcp()) recieve_tcp else recieve_udp;

        pub fn send(self: *@This(), data: []const u8) !usize {
            const ret = self.send_c(data);
            return if (ret <= 0) conn_error.send_error else @intCast(ret);
        }

        pub fn recieve(self: *@This(), data: []u8) ![]u8 {
            const n: isize = self.recieve_c(data);
            return if (n <= 0)
                conn_error.recieve_error
            else if (@as(usize, @intCast(n)) > data.len)
                conn_error.buffer_owerflow
            else
                data[0..@intCast(n)];
        }

        pub fn close(self: *@This()) !void {
            defer self.sd = INVALID_SOCKET;
            if (c.lwip_close(self.sd) != 0) {
                return conn_error.close_error;
            }
        }

        /// Block until the socket has data to read or the timeout elapses.
        /// Returns true if data is available, false on timeout.
        /// LWIP_SOCKET_OFFSET defaults to 0, so fd_bits indexing is fd/8.
        pub fn waitRx(self: *@This(), timeout_s: u32) !bool {
            var read_fds = std.mem.zeroes(c.fd_set);
            const fd: usize = @intCast(self.sd);
            read_fds.fd_bits[fd / 8] |= @as(u8, 1) << @as(u3, @intCast(fd & 7));

            var tv = c.timeval{
                .tv_sec = @intCast(timeout_s),
                .tv_usec = 0,
            };

            const ret = c.lwip_select(self.sd + 1, &read_fds, null, null, &tv);
            if (ret < 0) return conn_error.recieve_error;
            return ret > 0;
        }

        pub fn getProto(_: *@This()) connection.proto {
            return proto;
        }
    };
}

/// Alias kept for compatibility — prefer LwipConnection directly.
pub const SimpleLinkConnection = LwipConnection;
