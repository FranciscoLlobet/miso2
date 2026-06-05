const board = @import("board");
const rtx = @import("cmsis_rtx");

const JobQueue = rtx.JobQueue;
const JobMsg = rtx.JobMsg;

var jobQueue = JobQueue(
    JobMsg(anyopaque),
    "main executor",
    4096,
    .osPriorityAboveNormal,
    10,
).default();

// =========================================================================
// lwIP sys_now() — millisecond clock for timeout management (NO_SYS=1).
// Incremented by POLL_MS on each polling iteration.
// =========================================================================
const POLL_MS: u32 = 10;
export fn sys_now() callconv(.c) u32 {
    return kernel.getTickCount();
}

// =========================================================================
// MDIO wrappers — bridge phy_lan8741_resource_t callback signatures to the
// ENET driver (which requires the peripheral base address as first arg).
// =========================================================================

// =========================================================================
// PHY and ENET config — passed as state to netif_add.
// =========================================================================
//var phy_handle: board.c.phy_handle_t = undefined;

//var enet_config = board.c.ethernetif_config_t{
//    .phyHandle = &phy_handle,
//    .phyAddr = 0,
//    .phyOps = &board.c.phylan8741_ops,
//    .phyResource = @constCast(&board.mdio.g_phy_resource),
//    .srcClockHz = undefined,
//    .macAddress = undefined,
//};

// netif must outlive all lwIP usage; netif_add initialises it fully.
export var dhcp: board.c.dhcp = undefined;

//fn
const mainRunType = struct {
    thread: rtx.StaticThread(
        @This(),
        16000,
        "main",
        runner,
    ),

    pub fn new(self: *@This()) rtx.osError!void {
        try self.thread.new(self, 0, .osPriorityNormal);
        try board.lpuart2.initialize();
    }

    fn runner(self: ?*@This()) void {
        _ = self;
        board.lpuart2.write("MISO2 starting\r\n") catch {};

        // ---------------------------------------------------------------
        // ENET hardware setup — must happen before ethernetif0_init calls
        // PHY_Init() which requires MDIO to be operational.
        // ENET uses the bus clock (48 MHz) directly; no CLOCK_SetIpSrc needed.
        // ---------------------------------------------------------------

        // Use unique per-device MAC address derived from silicon ID.
        board.ethernet.enetConfig.init();

        // ---------------------------------------------------------------
        // lwIP init
        // ---------------------------------------------------------------
        board.c.lwip_init();

        board.netif.add() catch unreachable;

        board.netif.set_callbacks();
        board.c.dhcp_set_struct(board.netif.getReference(), &dhcp);

        board.netif.set_default() catch unreachable;

        board.netif.set_up();

        while (board.c.ERR_OK != board.c.ethernetif_wait_linkup(board.netif.getReference(), 5000)) {}

        _ = board.c.dhcp_start(board.netif.getReference());

        board.lpuart2.write("DHCP started\r\n") catch {};

        // ---------------------------------------------------------------
        // Polling loop — drives lwIP at POLL_MS intervals
        // ---------------------------------------------------------------
        var last_print_ms: u32 = 0;
        //var dhcp_bound = false;

        while (true) {

            // state no-linkup
            // ...

            // State dhcp not available
            // ...

            board.netif.input() catch unreachable;
            board.c.sys_check_timeouts();

            //if (!dhcp_bound and board.c.dhcp_supplied_address(board.netif.getReference()) != 0) {
            //    dhcp_bound = true;
            //    _ = board.c.printf("DHCP bound: %s\r\n", board.c.ipaddr_ntoa(board.netif.getReference().ip_addr));
            //}

            const now = kernel.getTickCount();
            if (now -% last_print_ms >= 1000) {
                last_print_ms = now;
                const link_up: u32 = @intFromBool(board.netif.is_link_up());
                const dhcp_data = board.c.netif_dhcp_data(board.netif.getReference());
                if (dhcp_data != null) {
                    _ = board.c.printf("link=%d dhcp_state=%d tries=%d\r\n", link_up, dhcp_data.*.state, dhcp_data.*.tries);
                } else {
                    _ = board.c.printf("link=%d dhcp=null\r\n", link_up);
                }
            }
        }

        unreachable;
    }

    pub fn job(_: ?*anyopaque) void {}
};

var main_task: mainRunType = undefined;
var kernel: rtx.Kernel(idleThread, errorNotify) = undefined;

export fn zmain() noreturn {
    board.initPreKernel();
    kernel.initialize() catch unreachable;
    board.initialize();
    main_task.new() catch unreachable;
    jobQueue.initialize() catch unreachable;
    kernel.start() catch unreachable;
    unreachable;
}

fn errorNotify(code: rtx.osError, object_id: ?*anyopaque) noreturn {
    _ = object_id;
    _ = code catch {};
    while (true) {}
    unreachable;
}

fn idleThread(_: ?*anyopaque) noreturn {
    while (true) {
        _ = kernel.kernelSuspend();
        kernel.kernelResume(0);
    }
    unreachable;
}

export fn _start() linksection(".init") callconv(.naked) void {
    asm volatile ("b Reset_Handler");
}

export fn malloc(_: usize) callconv(.c) ?*anyopaque {
    unreachable;
}
