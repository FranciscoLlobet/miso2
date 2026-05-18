const c = @import("c.zig").c;

const rtx = @import("cmsis_rtx");

const mcuc_sdk_error_map = error{
    lpuart_error,
};

inline fn lpuart_map_error(ret: c.status_t) mcuc_sdk_error_map!void {
    return if (@as(c.status_t, @intCast(c.kStatus_Success)) != ret) mcuc_sdk_error_map.lpuart_error;
}

const UART_EVENT_FLAG_ERROR: u32 = 0x1;
const UART_EVENT_FLAG_TX_COMPLETE: u32 = 0x2;
const UART_EVENT_FLAG_RX_COMPLETE: u32 = 0x4;
const UART_EVENT_FLAG_MASK: u32 = 0xFF;

const UART_LPUART_TX_IDLE: c.status_t = @intCast(c.kStatus_LPUART_TxIdle);

const error_handler_fn = *fn (err: mcuc_sdk_error_map) void;

pub fn uart_if(
    comptime name: []const u8,
    comptime lpuart_instance: [*c]c.LPUART_Type,
    comptime error_handler: ?error_handler_fn,
) type {
    return struct {
        handle: c.lpuart_handle_t = undefined,

        tx_flags: rtx.eventFlags.StaticEventFlags(name ++ "_ef"),

        tx_mutex: rtx.StaticMutex(name ++ "_mtx"),

        pub fn initialize(self: *@This()) !void {
            try self.tx_flags.new(0);
            try self.tx_mutex.new(rtx.mutex.osMutexPrioInherit);

            c.LPUART_TransferCreateHandle(lpuart_instance, &self.handle, onTxDone, @ptrCast(self));
        }

        // Registered with LPUART_TransferCreateHandle; called by LPUART_TransferHandleIRQ
        // from the ISR when the TX state machine reaches kStatus_LPUART_TxIdle.
        fn onTxDone(
            base: [*c]c.LPUART_Type,
            handle: [*c]c.lpuart_handle_t,
            status: c.status_t,
            user_data: ?*anyopaque,
        ) callconv(.c) void {
            _ = base;
            _ = handle;

            var ef: u32 = 0;

            const self: *@This() = @ptrCast(@alignCast(user_data));

            if (status == UART_LPUART_TX_IDLE) {
                ef |= UART_EVENT_FLAG_TX_COMPLETE;
            }

            _ = self.tx_flags.set(ef) catch |err| {
                error_handler.?(err);
            };
        }

        pub fn write(self: *@This(), data: []const u8) !void {
            try self.tx_mutex.acquire(rtx.osWaitForever);
            defer self.tx_mutex.release() catch {};

            _ = self.tx_flags.clear(UART_EVENT_FLAG_MASK) catch {};

            var xfer: c.lpuart_transfer_t = .{
                .unnamed_0 = .{
                    .txData = data.ptr,
                },
                .dataSize = data.len,
            };

            try lpuart_map_error(c.LPUART_TransferSendNonBlocking(lpuart_instance, &self.handle, &xfer));

            _ = try self.tx_flags.wait(UART_EVENT_FLAG_MASK, rtx.eventFlags.osFlagsWaitAny, rtx.osWaitForever);
        }

        pub fn read(self: *@This(), data: []u8) []u8 {
            _ = self;
            _ = data;
        }

        pub fn deinitialize(self: *@This()) !void {
            _ = self;
            //
        }
    };
}
