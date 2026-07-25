pub const c = @import("c.zig").c;
const uart = @import("uart.zig");
const led = @import("led.zig");
const button = @import("button.zig");
const runtime = @import("runtime.zig");
const stdio = @import("stdio.zig");

pub const ethernet = @import("ethernet.zig");

pub const rtc = @import("rtc.zig");

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

    system_rtc.start();

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

export fn RTC_Seconds_IRQHandler() callconv(.c) void {
    system_rtc.handle_isr();
}

export fn RTC_IRQHandler() callconv(.c) void {
    while (true) {}
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

export fn HardFault_Handler() callconv(.naked) void {
    asm volatile (
        \\ tst   lr, #4
        \\ ite   eq
        \\ mrseq r0, msp
        \\ mrsne r0, psp
        \\ mov   r1, lr
        \\ b     hardFaultDispatch
    );
}

const HardFaultInfo = struct {
    // stacked frame
    r0: u32,
    r1: u32,
    r2: u32,
    r3: u32,
    r12: u32,
    lr: u32,
    pc: u32,
    xpsr: u32,
    // fault registers
    cfsr: u32,
    hfsr: u32,
    mmfar: u32,
    bfar: u32,
    exc_return: u32,
};

var fault_info: HardFaultInfo = undefined;

export fn hardFaultDispatch(sp: [*]u32, exc_return: u32) callconv(.c) noreturn {
    fault_info = .{
        .r0 = sp[0],
        .r1 = sp[1],
        .r2 = sp[2],
        .r3 = sp[3],
        .r12 = sp[4],
        .lr = sp[5],
        .pc = sp[6],
        .xpsr = sp[7],
        .cfsr = @as(*u32, @ptrFromInt(0xE000ED28)).*,
        .hfsr = @as(*u32, @ptrFromInt(0xE000ED2C)).*,
        .mmfar = @as(*u32, @ptrFromInt(0xE000ED34)).*,
        .bfar = @as(*u32, @ptrFromInt(0xE000ED38)).*,
        .exc_return = exc_return,
    };

    @breakpoint(); // halts under a debugger, falls through to loop otherwise
    while (true) {}
}

export const stdout = &__stdio;
export const stdin = &__stdio;

//export fn set_errno(_: c_int) callconv(.c) void {
//    unreachable;
//}

pub var system_rtc = rtc.Rtc(
    c.RTC_PERIPHERAL,
    0,
).default();
