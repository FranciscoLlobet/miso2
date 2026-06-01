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

const mainRunType = struct {
    thread: rtx.StaticThread(@This(), 2048, "main", runner),

    pub fn new(self: *@This()) rtx.osError!void {
        try self.thread.new(self, 0, .osPriorityNormal);

        try board.lpuart2.initialize();
    }

    fn runner(self: ?*@This()) void {
        board.lpuart2.write("...Starting MISO2...\n") catch {};

        _ = board.c.printf("Hello World: %d", @as(i32, 1));

        while (true) {
            rtx.osDelay(1000) catch {};
            board.lpuart2.write("Test! \n") catch {};
            board.led_red.toggle();
            board.led_blue.clear();
            board.led_green.clear();
            jobQueue.send(job, self, null) catch {};
        }

        unreachable;
    }

    pub fn job(_: ?*anyopaque) void {
        //;
    }
};

var main_task: mainRunType = undefined;

var kernel: rtx.Kernel(
    idleThread,
    errorNotify,
) = undefined;

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

    while (true) {
        //
    }
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
