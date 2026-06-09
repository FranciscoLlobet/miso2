const rtx = @import("cmsis_rtx");

const c = @import("c.zig").c;

fn Mdio(
    comptime enet: *const c.ENET_Type,
) type {
    return struct {
        g_phy_resource: c.phy_lan8741_resource_t,

        fn mdio_read(phyAddr: u8, regAddr: u8, pData: [*c]c.u16_t) callconv(.c) c.status_t {
            return c.ENET_MDIORead(@constCast(enet), phyAddr, regAddr, pData);
        }
        fn mdio_write(phyAddr: u8, regAddr: u8, data: c.u16_t) callconv(.c) c.status_t {
            return c.ENET_MDIOWrite(@constCast(enet), phyAddr, regAddr, data);
        }
        pub fn init(_: *const @This()) void {
            c.CLOCK_EnableClock(c.s_enetClock[c.ENET_GetInstance(@ptrCast(@constCast(enet)))]);
            c.ENET_SetSMI(@constCast(enet), c.CLOCK_GetCoreSysClkFreq(), false);
        }
        fn default() @This() {
            return .{
                .g_phy_resource = .{
                    .read = mdio_read,
                    .write = mdio_write,
                },
            };
        }
    };
}

fn EnetConfig(
    phyHandle: *c.phy_handle_t,
    comptime phyResource: *const c.phy_lan8741_resource_t,
) type {
    return struct {
        config: c.ethernetif_config_t,

        fn default() @This() {
            return .{
                .config = .{
                    .phyHandle = phyHandle,
                    .phyAddr = 0,
                    .phyOps = &c.phylan8741_ops,
                    .phyResource = @constCast(phyResource),
                    .srcClockHz = undefined,
                    .macAddress = undefined,
                },
            };
        }
        pub fn init(self: *@This()) void {
            var mac: [6]u8 = undefined;

            _ = c.SILICONID_ConvertToMacAddr(&mac);

            @memcpy(&self.config.macAddress, mac[0..]);

            self.config.srcClockHz = c.CLOCK_GetCoreSysClkFreq();
        }
    };
}

pub const mdio = Mdio(c.ENET).default();

var phy_handle: c.phy_handle_t = undefined;

pub var enetConfig = EnetConfig(
    &phy_handle,
    &mdio.g_phy_resource,
).default();

pub const nsc_reason = enum(u16) {
    nsc_none = c.LWIP_NSC_NONE,
    netif_added = c.LWIP_NSC_NETIF_ADDED,
    netif_removed = c.LWIP_NSC_NETIF_REMOVED,
    link_changed = c.LWIP_NSC_LINK_CHANGED,
    status_changed = c.LWIP_NSC_STATUS_CHANGED,
    ipv4_address_changed = c.LWIP_NSC_IPV4_ADDRESS_CHANGED,
    ipv4_gateway_changed = c.LWIP_NSC_IPV4_GATEWAY_CHANGED,
    ipv4_netmask_changed = c.LWIP_NSC_IPV4_NETMASK_CHANGED,
    ipv4_settings_changed = c.LWIP_NSC_IPV4_SETTINGS_CHANGED,
    ipv6_set = c.LWIP_NSC_IPV6_SET,
    ipv6_addr_state_changed = c.LWIP_NSC_IPV6_ADDR_STATE_CHANGED,
    ipv4_addr_valid = c.LWIP_NSC_IPV4_ADDR_VALID,
};

pub fn Netif() type {
    return struct {
        netIf: c.netif,
        dhcp: c.dhcp,
        speed: u32,
        duplex: bool,

        fn link_status_callback(n: [*c]c.netif) callconv(.c) void {
            var self: *@This() = @fieldParentPtr("netIf", @as(*c.netif, @ptrCast(n)));

            if (self.is_link_up()) {
                self.speed = switch (c.ethernetif_get_link_speed(n)) {
                    c.kPHY_Speed10M => 10,
                    c.kPHY_Speed100M => 100,
                    c.kPHY_Speed1000M => 1000,
                    else => 0,
                };

                self.duplex = switch (c.ethernetif_get_link_duplex(n)) {
                    c.kPHY_HalfDuplex => false,
                    c.kPHY_FullDuplex => true,
                    else => false,
                };

                // Send linkup event

            } else {
                self.speed = 0;
                self.duplex = false;
                // Link is inactive: Event linkdown
            }
        }

        fn status_callback(n: [*c]c.netif) callconv(.c) void {
            const self: *@This() = @fieldParentPtr("netIf", @as(*c.netif, @ptrCast(n)));
            _ = self;
        }

        pub fn default() @This() {
            return .{
                .netIf = undefined,
                .speed = 0,
                .duplex = false,
                .dhcp = undefined,
            };
        }

        pub fn set_default(self: *@This()) !void {
            c.netif.set_default(&self.netIf);
        }

        pub fn set_callbacks(self: *@This()) void {
            c.netif_set_link_callback(&(self.netIf), link_status_callback);
            c.netif_set_status_callback(&(self.netIf), status_callback);
        }

        pub fn add(self: *@This()) !void {
            _ = c.netif_add(
                &(self.netIf),
                null,
                null,
                null,
                &enetConfig.config,
                c.ethernetif0_init,
                c.ethernet_input,
            );
        }

        pub fn set_up(self: *@This()) void {
            c.netif_set_up(&(self.netIf));
        }

        pub fn input(self: *@This()) !void {
            c.ethernetif_input(&(self.netIf));
        }

        pub inline fn is_link_up(self: *@This()) bool {
            return (@as(u8, @intCast(1)) == c.netif_is_link_up(&self.netIf));
        }

        pub fn get_dhcp_data(self: *@This()) ?*c.dhcp {
            return c.netif_dhcp_data(&self.netIf);
        }

        pub fn getReference(self: *@This()) *c.netif {
            return &self.netIf;
        }

        pub fn dhcp_start(self: *@This()) void {
            _ = c.netifapi_netif_common(&self.netIf, null, c.dhcp_start);
        }
        pub fn dhcp_set_struct(self: *@This()) void {
            c.dhcp_set_struct(&self.netIf, &self.dhcp);
        }
    };
}
