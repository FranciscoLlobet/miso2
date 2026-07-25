const c = @import("c.zig").c;
const rtx = @import("cmsis_rtx");

const JobMsg = rtx.JobMsg;
const JobQueue = rtx.JobQueue;

pub var hwJobQueue = JobQueue(
    JobMsg(anyopaque),
    "HwJobQueue",
    2048,
    .osPriorityAboveNormal,
    10,
    rtx.jobQueue.default_mq_attr,
    rtx.jobQueue.default_task_attr,
).default();
