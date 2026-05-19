const board = @import("board");
const rtx = @import("cmsis_rtx");

pub fn JobMsg(comptime T: type) type {
    return struct {
        jobFn: *const fn (param: ?*T) void,
        param: ?*T,
    };
}

pub fn JobQueue(
    comptime jobMsgType: type,
    comptime name: []const u8,
    comptime stack_size: usize,
    comptime priority: rtx.thread.osThreadPriority,
    comptime queue_size: usize,
) type {
    return struct {
        thread: rtx.StaticThread(@This(), stack_size, name ++ "_thread", queueRunner),
        //
        queue: rtx.StaticMessageQueue(jobMsgType, queue_size, name ++ "_mq"),

        pub fn initialize(self: *@This()) rtx.osError!void {
            try self.queue.new(0);
            try self.thread.new(self, 0, priority);
        }

        fn queueRunner(self: ?*@This()) void {
            while (true) {
                const job = self.?.queue.getMsg(rtx.osWaitForever) catch {
                    continue;
                };

                if (job) |j| {
                    j.msg.jobFn(j.msg.param);
                }
            }
        }

        pub fn send(
            self: *@This(),
            jobFn: @FieldType(jobMsgType, "jobFn"),
            param: @FieldType(jobMsgType, "param"),
            timeout: ?u32,
        ) !void {
            try self.queue.put(
                &.{
                    .jobFn = jobFn,
                    .param = param,
                },
                0,
                timeout,
            );
        }
    };
}

var jobQueue: JobQueue(
    JobMsg(anyopaque),
    "main executor",
    1024,
    .osPriorityAboveNormal,
    10,
) = undefined;

const mainRunType = struct {
    thread: rtx.StaticThread(@This(), 1024, "main", runner),

    pub fn new(self: *@This()) rtx.osError!void {
        try self.thread.new(self, 0, .osPriorityNormal);

        try board.lpuart2.initialize();
    }

    fn runner(self: ?*@This()) void {
        board.lpuart2.write("...Starting MISO2...\n") catch {};

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
    board.initialize();

    kernel.initialize() catch {};

    main_task.new() catch {};
    jobQueue.initialize() catch {};

    kernel.start() catch {};

    unreachable;
}

fn errorNotify(code: rtx.osError!void, object_id: ?*anyopaque) u32 {
    _ = object_id;
    _ = code catch {};

    while (true) {
        //
    }
    return 0;
}

fn idleThread(_: ?*anyopaque) noreturn {
    while (true) {
        //
    }
    unreachable;
}

export fn _start() linksection(".init") callconv(.naked) void {
    asm volatile ("b Reset_Handler");
}
