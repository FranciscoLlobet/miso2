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

    fn tcpip_init_done(arg: ?*anyopaque) callconv(.c) void {
        const thread = rtx.thread.create(arg) catch unreachable;

        _ = thread.flagsSet(1) catch unreachable;
    }

    fn getHostByName(name: []u8) board.c.ip_addr_t {
        var ipAddr: board.c.ip_addr_t = undefined;

        _ = board.c.netconn_gethostbyname(name.ptr, &ipAddr);

        return ipAddr;
    }

    fn runner(self: ?*@This()) void {
        //_ = self;
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
        board.c.tcpip_init(
            tcpip_init_done,
            self.?.thread.thread.id,
        );

        _ = self.?.thread.flagsWait(
            1,
            .osFlagsWaitAny,
            rtx.osWaitForever,
        ) catch unreachable;

        board.netif.add() catch unreachable;

        board.netif.set_callbacks();

        board.netif.dhcp_set_struct();

        board.netif.set_default() catch unreachable;

        board.netif.set_up();

        while (board.c.ERR_OK != board.c.ethernetif_wait_linkup(
            board.netif.getReference(),
            5000,
        )) {
            //
        }

        board.netif.dhcp_start();

        board.lpuart2.write("DHCP started\r\n") catch {};

        // ---------------------------------------------------------------
        // Polling loop — drives lwIP at POLL_MS intervals
        // ---------------------------------------------------------------
        var last_print_ms: u32 = 0;
        //var dhcp_bound = false;

        //var state: u32 = 0;
        //_ = state;

        while (true) {

            // Get current state

            // state no-linkup
            // ...

            // State dhcp not available
            // ...

            // Process input
            //board.netif.input() catch unreachable;

            // Check timeouts
            //board.c.sys_check_timeouts();

            // periodic state

            //if (!dhcp_bound and board.c.dhcp_supplied_address(board.netif.getReference()) != 0) {
            //    dhcp_bound = true;
            //    _ = board.c.printf("DHCP bound: %s\r\n", board.c.ipaddr_ntoa(board.netif.getReference().ip_addr));
            //}
            _ = getHostByName(@constCast("pool.ntp.org"));

            const now = kernel.getTickCount();
            if (now -% last_print_ms >= 1000) {
                last_print_ms = now;
                const link_up: u32 = @intFromBool(board.netif.is_link_up());
                const dhcp_data = board.netif.get_dhcp_data();
                if (dhcp_data) |data| {
                    _ = board.c.printf("link=%d dhcp_state=%d tries=%d\r\n", link_up, data.*.state, data.*.tries);
                } else {
                    _ = board.c.printf("link=%d dhcp=null\r\n", link_up);
                }
            }
        }

        unreachable;
    }

    pub fn job(_: ?*anyopaque) void {
        //
    }
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

    board.led_red.set();

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
