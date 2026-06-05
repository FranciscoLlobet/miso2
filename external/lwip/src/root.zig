// lwIP Zig module entry point.
// Import the C headers via @cImport so consumers can do:
//   const lwip = @import("lwip");
//   const c    = lwip.c;
pub const c = @cImport({
    @cInclude("lwip/init.h");
    @cInclude("lwip/netif.h");
    @cInclude("lwip/timeouts.h");
    @cInclude("lwip/dhcp.h");
    @cInclude("lwip/dns.h");
    @cInclude("lwip/icmp.h");
    @cInclude("lwip/tcp.h");
    @cInclude("lwip/udp.h");
    @cInclude("netif/ethernet.h");
    @cInclude("lwip/etharp.h");
});
