const std = @import("std");
const board = @import("board");
const rtx = @import("cmsis_rtx");
const connection = @import("connection.zig");
const simpleConnection = @import("simpleConnection.zig");
const ntp = @import("ntp.zig");

var jobQueue = rtx.JobQueue(
    rtx.JobMsg(anyopaque),
    "main executor",
    4096,
    .osPriorityAboveNormal,
    10,
).default();

const mainRunType = struct {
    thread: rtx.StaticThread(
        @This(),
        24000,
        "main",
        runner,
    ),

    //    ntpResponse: ntp.ntp_response,
    ntpSyncTime: u32,
    ntpSyncCount: u32,

    ntpTimer: rtx.StaticTimer(
        @This(),
        "ntpTimer",
        ntp_trigger,
    ),

    pub const mainEvents = enum(u32) {
        trigger_ntp = 1 << 1,
        ntp_aquired = 1 << 2,
    };

    pub fn ntp_trigger(self: *@This()) void {
        _ = self.thread.flagsSet(@intFromEnum(mainEvents.trigger_ntp)) catch {};
    }

    pub fn new(self: *@This()) rtx.osError!void {
        try board.lpuart2.initialize();

        try self.thread.new(
            self,
            0,
            .osPriorityNormal,
        );

        try self.ntpTimer.new(
            .osTimerPeriodic,
            self,
            0,
        );
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
        self.?.ntpSyncTime = 0;
        self.?.ntpSyncCount = 0;

        board.lpuart2.write("MISO2 starting\r\n") catch {};

        const ntp_uri: std.Uri = std.Uri.parse("ntp://pool.ntp.org:123") catch unreachable;

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
        self.?.ntpTimer.start(16000) catch unreachable;

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

            if (self.?.thread.flagsWait(rtx.osFlagsValidAll, .osFlagsWaitAny, rtx.osWaitNever) catch null) |flags| {

                // Get the NTP trigger
                if (0 != (flags & @intFromEnum(mainEvents.trigger_ntp))) {
                    self.?.ntpTimer.stop() catch {};

                    if (ntp.getTimeFromServer(
                        ntp_uri,
                        board.rtc.unix_to_ntp(
                            board.system_rtc.get_timestamp(),
                        ),
                        kernel.getTickCount(),
                    )) |ntpResponse| {
                        const time_diff = board.system_rtc.set_timestamp(
                            board.rtc.ntp_to_unix(ntpResponse.timestamp_s),
                        );

                        if (time_diff > 4) {
                            self.?.ntpSyncCount = 0;
                        } else if (time_diff <= 1) {
                            self.?.ntpSyncCount += 1;
                        } else {
                            // nothing
                        }

                        if (self.?.ntpSyncCount > 3) {
                            self.?.ntpSyncCount = 0;
                            _ = self.?.thread.flagsSet(@intFromEnum(mainEvents.ntp_aquired)) catch unreachable;
                        } else {
                            const nextSyncTime: u32 = if (ntpResponse.poll_interval > 60 * 60) @as(u32, 60 * 60 * 1000) else ntpResponse.poll_interval * 1000;
                            self.?.ntpTimer.start(nextSyncTime) catch unreachable;
                        }
                        //_ = board.c.printf("NTP Sync: %u, %d\r\n", ntpResponse.timestamp_s, time_diff);
                    } else |_| {
                        self.?.ntpSyncCount = 0;
                        self.?.ntpTimer.start(16000) catch unreachable;
                    }
                }
                // NTP time acquisition stopped
                if (0 != (flags & @intFromEnum(mainEvents.ntp_aquired))) {
                    // Set to resync in 15mins
                    self.?.ntpSyncTime = board.system_rtc.get_timestamp();
                    self.?.ntpSyncCount = 0;
                    self.?.ntpTimer.start(@as(u32, 15 * 60 * 1000)) catch unreachable;

                    _ = board.c.printf("NTP Acquired: %u\r\n", self.?.ntpSyncTime);
                }
            } else {
                //
            }

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
