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
    try receiver.bind("tcp://*:5558");

    const controller = try ctx.open(.@"pub");
    defer controller.close();
    try controller.bind("tcp://*:5559");

    _ = try receiver.recv(&.{}, .{});

    const start = std.time.Instant.now() catch unreachable;
    for (0..100) |_| {
        _ = try receiver.recv(&.{}, .{});
    }
    const end = std.time.Instant.now() catch unreachable;

    try controller.send("KILL", .{});

    info("took: {d} msec", .{@as(f64, @floatFromInt(end.since(start))) / std.time.ns_per_ms});
}
