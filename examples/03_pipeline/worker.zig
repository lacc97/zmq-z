const std = @import("std");

const zmq = @import("zmq");

pub const std_options = struct {
    pub usingnamespace @import("log_options");
};

const info = std.log.info;

pub fn main() !void {
    const ctx = try zmq.Context.init();
    defer ctx.deinit();

    const receiver = try ctx.open(.pull);
    defer receiver.close();
    try receiver.connect("tcp://localhost:5557");

    const sender = try ctx.open(.push);
    defer sender.close();
    try sender.connect("tcp://localhost:5558");

    while (true) {
        var buf: [32]u8 = undefined;

        const task = try receiver.recv(&buf, .{});
        info("{s}.", .{task});
        const msec = try std.fmt.parseInt(u16, task, 10);
        std.time.sleep(@as(u64, msec) * (std.time.ns_per_ms));
        try sender.send("", .{});
    }
}
