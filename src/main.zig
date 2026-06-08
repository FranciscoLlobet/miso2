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

const sys_err_t = enum(i32) {
    ERR_OK = 0,
    ERR_MEM = -1,
};

const SYS_TIMEOUT: u32 = 0xffffffff;
const SYS_MBOX_EMPTY = SYS_TIMEOUT;

const sys_mutex_type = ?*rtx.mutex.osMutexId_t;
const sys_mbox_type = ?*rtx.messageQueue.osMessageQueueId_t;
const sys_sem_type = ?*rtx.semaphore.osSemaphoreId_t;

export fn sys_now() callconv(.c) u32 {
    return kernel.getTickCount();
}

export fn sys_init() callconv(.c) void {
    //
}

export fn sys_arch_msleep(
    delay_ms: u32,
) callconv(.c) void {
    return rtx.osDelay(delay_ms) catch unreachable;
}

export fn sys_mutex_new(
    mutex: sys_mutex_type,
) callconv(.c) i32 {
    mutex.?.* = rtx.mutex.osMutexNew(null);
    return 0;
}

export fn sys_mutex_lock(
    mutex: sys_mutex_type,
) callconv(.c) void {
    //while( )
    _ = rtx.mutex.osMutexAcquire(mutex.?.*, rtx.osWaitForever);
}

export fn sys_mutex_unlock(
    mutex: sys_mutex_type,
) callconv(.c) void {
    _ = rtx.mutex.osMutexRelease(mutex.?.*);
}

export fn sys_mbox_new(
    mbox: sys_mbox_type,
    iSize: c_int,
) i32 {
    mbox.?.* = rtx.messageQueue.osMessageQueueNew(@intCast(iSize), @sizeOf(?*anyopaque), null);

    return if (mbox.?.* == null) @intFromEnum(sys_err_t.ERR_MEM) else @intFromEnum(sys_err_t.ERR_OK);
}

export fn sys_mbox_post(
    mbox: sys_mbox_type,
    msg: ?*anyopaque,
) void {
    _ = rtx.messageQueue.osMessageQueuePut(mbox.?.*, @ptrCast(&msg), 0, rtx.osWaitForever);
}

export fn sys_mbox_trypost(
    mbox: sys_mbox_type,
    msg: ?*anyopaque,
) i32 {
    const status = rtx.messageQueue.osMessageQueuePut(mbox.?.*, @ptrCast(&msg), 0, rtx.osWaitNever);

    return if (status == rtx.osOk) @intFromEnum(sys_err_t.ERR_OK) else @intFromEnum(sys_err_t.ERR_MEM);
}

export fn sys_mbox_trypost_fromisr(
    mbox: sys_mbox_type,
    msg: ?*anyopaque,
) i32 {
    return sys_mbox_trypost(mbox, msg);
}

export fn sys_arch_mbox_fetch(
    mbox: sys_mbox_type,
    ppvBuffer: ?*?*anyopaque,
    ulTimeout: u32,
) u32 {
    const start_time = kernel.getTickCount();

    var dummy: ?*anyopaque = undefined;
    const msg: *?*anyopaque = ppvBuffer orelse &dummy;

    const status = rtx.messageQueue.osMessageQueueGet(
        mbox.?.*,
        @ptrCast(msg),
        null,
        if (ulTimeout == 0) rtx.osWaitForever else ulTimeout,
    );

    return if (status == rtx.osOk) (kernel.getTickCount() - start_time) else SYS_TIMEOUT;
}

export fn sys_thread_new(
    name: ?[*:0]const u8,
    thread_fn: ?*const fn (?*anyopaque) callconv(.c) void,
    arg: ?*anyopaque,
    stacksize: c_int,
    prio: c_int,
) ?*anyopaque {
    const attr: rtx.thread.osThreadAttr_t = .{
        .name = name,
        .attr_bits = 0,
        .cb_mem = null,
        .cb_size = 0,
        .stack_mem = null,
        .stack_size = @intCast(stacksize),
        .priority = prio,
        .tz_module = 0,
        .affinity_mask = 0,
    };
    return rtx.thread.osThreadNew(thread_fn, arg, &attr);
}

export fn sys_mutex_free(
    mutex: sys_mutex_type,
) void {
    _ = rtx.mutex.osMutexDelete(mutex.?.*);
}

export fn sys_mutex_valid(
    mutex: sys_mutex_type,
) c_int {
    return if ((mutex != null) and (mutex.?.* != null)) 1 else 0;
}

export fn sys_mutex_set_invalid(
    mutex: sys_mutex_type,
) void {
    if (mutex) |m| m.* = null;
}

export fn sys_sem_new(
    sem: sys_sem_type,
    count: u8,
) i32 {
    sem.?.* = rtx.semaphore.osSemaphoreNew(
        1,
        count,
        null,
    );
    return if (sem.?.* == null) @intFromEnum(sys_err_t.ERR_MEM) else @intFromEnum(sys_err_t.ERR_OK);
}

export fn sys_sem_signal(
    sem: sys_sem_type,
) void {
    _ = rtx.semaphore.osSemaphoreRelease(sem.?.*);
}

export fn sys_arch_sem_wait(
    sem: sys_sem_type,
    ulTimeout: u32,
) u32 {
    const start_time = kernel.getTickCount();
    const status = rtx.semaphore.osSemaphoreAcquire(
        sem.?.*,
        if (ulTimeout == 0) rtx.osWaitForever else ulTimeout,
    );
    return if (status == rtx.osOk) kernel.getTickCount() - start_time else SYS_TIMEOUT;
}

export fn sys_sem_free(
    sem: sys_sem_type,
) void {
    _ = rtx.semaphore.osSemaphoreDelete(sem.?.*);
}

export fn sys_sem_valid(
    sem: sys_sem_type,
) c_int {
    return if ((sem != null) and (sem.?.* != null)) 1 else 0;
}

export fn sys_sem_set_invalid(
    sem: sys_sem_type,
) void {
    if (sem) |s| s.* = null;
}

export fn sys_mbox_free(mbox: sys_mbox_type) void {
    _ = rtx.messageQueue.osMessageQueueDelete(mbox.?.*);
}

export fn sys_arch_mbox_tryfetch(
    mbox: sys_mbox_type,
    ppvBuffer: ?*?*anyopaque,
) u32 {
    var dummy: ?*anyopaque = undefined;
    const msg: *?*anyopaque = ppvBuffer orelse &dummy;
    const status = rtx.messageQueue.osMessageQueueGet(
        mbox.?.*,
        @ptrCast(msg),
        null,
        rtx.osWaitNever,
    );
    return if (status == rtx.osOk) 0 else SYS_MBOX_EMPTY;
}

extern var lock_tcpip_core: rtx.mutex.osMutexId_t;

export fn sys_lock_tcpip_core() callconv(.c) void {
    sys_mutex_lock(&lock_tcpip_core);
}

export fn sys_unlock_tcpip_core() callconv(.c) void {
    sys_mutex_unlock(&lock_tcpip_core);
}

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
        //board.c.lwip_init();

        board.c.tcpip_init(
            null,
            null,
        );

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
            // Get current state

            // state no-linkup
            // ...

            // State dhcp not available
            // ...

            // Process input
            board.netif.input() catch unreachable;

            // Check timeouts
            board.c.sys_check_timeouts();

            // periodic state

            //if (!dhcp_bound and board.c.dhcp_supplied_address(board.netif.getReference()) != 0) {
            //    dhcp_bound = true;
            //    _ = board.c.printf("DHCP bound: %s\r\n", board.c.ipaddr_ntoa(board.netif.getReference().ip_addr));
            //}

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
