pub const c = @cImport({
    @cInclude("cimport.h");
    @cInclude("fsl_gpio.h");
    @cInclude("fsl_phy.h");
    @cInclude("fsl_phylan8741.h");
    @cInclude("fsl_silicon_id.h");
    // fsl_enet.h: ENET_SetSMI, ENET_MDIORead/Write, s_enetClock, ENET_GetInstance
    @cInclude("fsl_enet.h");
    // ethernetif includes lwip/netif.h and lwip/err.h
    @cInclude("ethernetif.h");
    // Additional lwIP headers — included after ethernetif so netif type is shared
    @cInclude("lwip/init.h");
    @cInclude("lwip/dhcp.h");
    @cInclude("lwip/timeouts.h");
    @cInclude("lwip/ip_addr.h");
    @cInclude("lwip/tcpip.h");
    @cInclude("netif/ethernet.h");
});
