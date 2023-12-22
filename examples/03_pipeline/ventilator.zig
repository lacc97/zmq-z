const std = @import("std");

const zmq = @import("zmq");

pub const std_options = struct {
    pub usingnamespace @import("log_options");
};

const info = std.log.info;

pub fn main() !void {
    const ctx = try zmq.Context.init();
    defer ctx.deinit();

    const sender = try ctx.open(.push);
    defer sender.close();
    try sender.bind("tcp://*:5557");

    const sink = try ctx.open(.push);
    defer sink.close();
    try sink.connect("tcp://localhost:5558");

    info("Press Enter when the workers are ready: ", .{});
    _ = try std.io.getStdIn().reader().readByte();
    info("Sending tasks to workers...", .{});

    try sink.send("", .{});

    var rng_state = std.rand.DefaultPrng.init(0);
    const rng = rng_state.random();

    var total_msec: u64 = 0;
    for (0..100) |_| {
        var buf: [10]u8 = undefined;

        const msec = rng.intRangeAtMost(u8, 1, 100);
        const msg = std.fmt.bufPrint(&buf, "{}", .{msec}) catch unreachable;
        total_msec += msec;
        try sender.send(msg, .{});
    }
    info("Total expected cost: {} msec", .{total_msec});
}
