// External C functions from NXP MCUXpresso SDK board support
extern fn BOARD_InitBootPins() void;
extern fn BOARD_InitBootClocks() void;
extern fn BOARD_InitBootPeripherals() void;

/// Initialize board hardware (clocks, pins, peripherals)
/// This should be called early in main() before using any peripherals
pub fn initialize() void {
    BOARD_InitBootPins();
    BOARD_InitBootClocks();
    BOARD_InitBootPeripherals();
}
