pub const c = @cImport({
    @cInclude("cimport.h");
    @cInclude("fsl_gpio.h");
    @cInclude("fsl_phy.h");
    @cInclude("fsl_phylan8741.h");
    @cInclude("fsl_silicon_id.h");
    @cInclude("fsl_enet.h");
    @cInclude("fsl_rtc.h");
    @cInclude("ethernetif.h");
    @cInclude("lwip/init.h");
    @cInclude("lwip/dhcp.h");
    @cInclude("lwip/timeouts.h");
    @cInclude("lwip/ip_addr.h");
    @cInclude("lwip/tcpip.h");
    @cInclude("netif/ethernet.h");
    @cInclude("lwip/netifapi.h");
});
