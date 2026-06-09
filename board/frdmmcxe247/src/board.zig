const rtx = @import("cmsis_rtx");

pub const c = @import("c.zig").c;
const uart = @import("uart.zig");
const led = @import("led.zig");
const button = @import("button.zig");
const runtime = @import("runtime.zig");
const stdio = @import("stdio.zig");
const sys_arch = @import("sys_arch.zig");

pub const ethernet = @import("ethernet.zig");

pub fn initPreKernel() void {
    c.BOARD_InitBootPins();
    c.BOARD_InitBootClocks();
    c.BOARD_InitBootPeripherals();
    c.BOARD_InitLEDsPins();
    c.BOARD_InitBUTTONsPins();

    // Disable the System MPU so the ENET DMA bus master can access SRAM.
    // By default the SYSMPU restricts non-CPU bus masters (including ENET DMA),
    // which silently prevents both TX buffer reads and RX buffer writes.
    c.SYSMPU.*.CESR &= ~c.SYSMPU_CESR_VLD_MASK;

    c.GPIO_PinWrite(
        c.BOARD_INITENET_MII_RMII_PHY_RST_GPIO,
        c.BOARD_INITENET_MII_RMII_PHY_RST_PIN,
        0,
    );

    c.SDK_DelayAtLeastUs(
        25000,
        c.CLOCK_GetFreq(c.kCLOCK_CoreSysClk),
    );

    c.GPIO_PinWrite(
        c.BOARD_INITENET_MII_RMII_PHY_RST_GPIO,
        c.BOARD_INITENET_MII_RMII_PHY_RST_PIN,
        1,
    );
}

pub fn initialize() void {
    button_sw2.init(null) catch unreachable;
    button_sw3.init(null) catch unreachable;

    led_blue.clear();
    led_green.clear();
    led_red.clear();

    ethernet.mdio.init();

    runtime.hwJobQueue.initialize() catch unreachable;
}

export fn LPUART2_IRQHandler() callconv(.c) void {
    c.LPUART_TransferHandleIRQ(c.LPUART2_PERIPHERAL, &lpuart2.handle);
}

export fn PORTA_IRQHandler() callconv(.c) void {
    const isr_flags = c.GPIO_PortGetInterruptFlags(c.BOARD_INITBUTTONSPINS_SW2_GPIO);

    button_sw2.handleIsr();

    c.GPIO_PortClearInterruptFlags(c.BOARD_INITBUTTONSPINS_SW2_GPIO, isr_flags);
}

export fn PORTC_IRQHandler() callconv(.c) void {
    const isr_flags = c.GPIO_PortGetInterruptFlags(c.BOARD_INITBUTTONSPINS_SW3_GPIO);

    button_sw3.handleIsr();

    c.GPIO_PortClearInterruptFlags(c.BOARD_INITBUTTONSPINS_SW3_GPIO, isr_flags);
}

pub var lpuart2 = uart.uart_if(
    "LPUART2",
    c.LPUART2_PERIPHERAL,
    null,
).default();

pub var led_red = led.Led(
    c.BOARD_INITLEDSPINS_LED_RED_GPIO,
    c.BOARD_INITLEDSPINS_LED_RED_PIN,
    false,
).default();

pub var led_green = led.Led(
    c.BOARD_INITLEDSPINS_LED_GREEN_GPIO,
    c.BOARD_INITLEDSPINS_LED_GREEN_PIN,
    false,
).default();

pub var led_blue = led.Led(
    c.BOARD_INITLEDSPINS_LED_BLUE_GPIO,
    c.BOARD_INITLEDSPINS_LED_BLUE_PIN,
    false,
).default();

pub var button_sw2 = button.Button(
    "SW2",
    .sw2,
    c.BOARD_INITBUTTONSPINS_SW2_GPIO,
    c.BOARD_INITBUTTONSPINS_SW2_PIN,
    false,
    10,
).default();

pub var button_sw3 = button.Button(
    "SW3",
    .sw3,
    c.BOARD_INITBUTTONSPINS_SW3_GPIO,
    c.BOARD_INITBUTTONSPINS_SW3_PIN,
    false,
    10,
).default();

pub var netif = ethernet.Netif().default();

const __stdio = stdio.SerialStdio(
    @TypeOf(lpuart2),
    &lpuart2,
).default();

export const stdout = &__stdio;
export const stdin = &__stdio;

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
    return rtx.kernel.getTickCount();
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
    const start_time = rtx.kernel.getTickCount();

    var dummy: ?*anyopaque = undefined;
    const msg: *?*anyopaque = ppvBuffer orelse &dummy;

    const status = rtx.messageQueue.osMessageQueueGet(
        mbox.?.*,
        @ptrCast(msg),
        null,
        if (ulTimeout == 0) rtx.osWaitForever else ulTimeout,
    );

    return if (status == rtx.osOk) (rtx.kernel.getTickCount() - start_time) else SYS_TIMEOUT;
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
    const start_time = rtx.kernel.getTickCount();
    const status = rtx.semaphore.osSemaphoreAcquire(
        sem.?.*,
        if (ulTimeout == 0) rtx.osWaitForever else ulTimeout,
    );
    return if (status == rtx.osOk) rtx.kernel.getTickCount() - start_time else SYS_TIMEOUT;
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
