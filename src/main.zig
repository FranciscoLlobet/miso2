const std = @import("std");
const board = @import("board");
const rtx = @import("cmsis_rtx");
const connection = @import("connection.zig");
const simpleConnection = @import("simpleConnection.zig");
const ntp = @import("ntp.zig");

var jobQueue = rtx.JobQueue(
    rtx.JobMsg(anyopaque),
    "MainJobQueue",
    4096,
    .osPriorityAboveNormal,
    10,
    rtx.jobQueue.default_mq_attr,
    rtx.jobQueue.default_task_attr,
).default();

var ntpService: ntp.Ntp(
    connection.Connection(
        simpleConnection.LwipConnection(.udp_ip4),
    ),
) = undefined;

const mainRunType = struct {
    const main_event_wait_period: u32 = 1000;

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

    mainState: struct {
        dhcp_up: bool,
        ntp_acquired: bool,
    } = .{
        .dhcp_up = false,
        .ntp_acquired = false,
    },

    pub const mainEvents = enum(u32) {
        trigger_ntp = 1 << 1,
        ntp_aquired = 1 << 2,
        dhcp_up = 1 << 3,
        dhcp_down = 1 << 4,
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
            .osTimerOnce,
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

    fn dhcp_up_down(arg: ?*anyopaque, up_down: bool) void {
        const tread = rtx.thread.create(arg) catch unreachable;

        _ = tread.flagsSet(
            @intFromEnum(if (up_down) mainEvents.dhcp_up else mainEvents.dhcp_down),
        ) catch unreachable;
    }

    fn runner(self: ?*@This()) void {
        //_ = self;
        self.?.ntpSyncTime = 0;
        self.?.ntpSyncCount = 0;
        self.?.mainState = .{
            .dhcp_up = false,
            .ntp_acquired = false,
        };

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

        board.netif.set_callbacks(
            dhcp_up_down,
            self.?.thread.thread.id,
        );

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
        //var last_print_ms: u32 = 0;
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

            // Process events
            if (self.?.thread.flagsWait(
                rtx.osFlagsValidAll,
                .osFlagsWaitAny,
                main_event_wait_period,
            ) catch null) |flags| {

                // NTP time acquisition stopped
                if (0 != (flags & @intFromEnum(mainEvents.ntp_aquired))) {
                    self.?.ntpSyncTime = board.system_rtc.get_timestamp();
                    self.?.ntpSyncCount = 0;

                    // Re-sync in 15minutes
                    self.?.ntpTimer.start(@as(u32, 15 * 60 * 1000)) catch unreachable;

                    _ = board.c.printf("NTP Acquired: %u\r\n", self.?.ntpSyncTime);

                    self.?.mainState.dhcp_up = true;
                }

                // NTP Timer trigger
                if (0 != (flags & @intFromEnum(mainEvents.trigger_ntp))) {
                    self.?.process_ntp_trigger(ntp_uri) catch unreachable;
                }

                // DHCP is up
                if (0 != (flags & @intFromEnum(mainEvents.dhcp_up))) {
                    _ = board.c.printf("DHCP up \n\r");
                    self.?.ntpTimer.start(1000) catch unreachable;
                    self.?.mainState.dhcp_up = true;
                }

                // DHCP is down
                if (0 != (flags & @intFromEnum(mainEvents.dhcp_down))) {
                    self.?.ntpTimer.stop() catch unreachable;
                    self.?.mainState.dhcp_up = false;
                }
            } else {
                // No event during time loop
            }

            // Process state

            _ = board.c.printf("Loop \n\r");
        }

        unreachable;
    }

    inline fn process_ntp_trigger(
        self: *@This(),
        ntp_uri: std.Uri,
    ) rtx.osError!void {
        self.ntpTimer.stop() catch {};

        if (ntpService.getTimeFromServer(
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
                self.ntpSyncCount = 0;
            } else if (time_diff <= 2) {
                self.ntpSyncCount += 1;
            } else {
                // nothing
            }

            if (self.ntpSyncCount >= 3) {
                _ = try self.thread.flagsSet(@intFromEnum(mainEvents.ntp_aquired));
            } else {
                const nextSyncTime: u32 = if (ntpResponse.poll_interval > (60 * 60))
                    @as(u32, 60 * 60 * 1000)
                else
                    (ntpResponse.poll_interval * 1000);

                try self.ntpTimer.start(nextSyncTime);
            }
            //_ = board.c.printf("NTP Sync: %u, %d\r\n", ntpResponse.timestamp_s, time_diff);
        } else |_| {
            self.ntpSyncCount = 0;
            try self.ntpTimer.start(16000);
        }
    }

    pub fn job(_: ?*anyopaque) void {
        //
    }
};

var main_task: mainRunType = undefined;
var kernel = rtx.Kernel(idleThread, errorNotify).default();

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
