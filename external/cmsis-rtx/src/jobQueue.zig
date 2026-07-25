const core = @import("core.zig");
const thread = @import("thread.zig");
const messageQueue = @import("messageQueue.zig");

const osThreadPriority = thread.osThreadPriority;

pub const default_task_attr: u32 = 0;
pub const default_mq_attr: u32 = 0;

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
    comptime priority: osThreadPriority,
    comptime queue_size: usize,
    comptime queue_attr: u32,
    comptime thread_attr: u32,
) type {
    return struct {
        const staticThreadType = thread.StaticThread(
            @This(),
            stack_size,
            name ++ "_thread",
            queueRunner,
        );

        const staticMessageQueueType = messageQueue.StaticMessageQueue(
            jobMsgType,
            queue_size,
            name ++ "_mq",
        );

        thread: staticThreadType,
        queue: staticMessageQueueType,

        pub fn default() @This() {
            return .{
                .thread = staticThreadType.default(),
                .queue = staticMessageQueueType.default(),
            };
        }

        pub fn initialize(self: *@This()) core.osError!void {
            try self.queue.new(
                queue_attr,
            );
            try self.thread.new(
                self,
                thread_attr,
                priority,
            );
        }

        fn queueRunner(self: ?*@This()) void {
            while (true) {
                const job = self.?.queue.getMsg(core.osWaitForever) catch {
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
