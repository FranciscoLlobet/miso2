const rtx = @import("cmsis_rtx");

pub const c = @import("c.zig").c;
const uart = @import("uart.zig");
const led = @import("led.zig");
const button = @import("button.zig");
const runtime = @import("runtime.zig");
const stdio = @import("stdio.zig");

pub fn initPreKernel() void {
    c.BOARD_InitBootPins();
    c.BOARD_InitBootClocks();
    c.BOARD_InitBootPeripherals();
    c.BOARD_InitLEDsPins();
    c.BOARD_InitBUTTONsPins();
}

pub fn initialize() void {
    button_sw2.init(null) catch unreachable;
    button_sw3.init(null) catch unreachable;

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

const __stdio = stdio.SerialStdio(@TypeOf(lpuart2), &lpuart2).default();

export const stdout = &__stdio;
export const stdin = &__stdio;

const macAddr: [6]u8 = undefined;

fn getMacAddr() void {
    c.SILICONID_ConvertToMacAddr(&macAddr);
}
