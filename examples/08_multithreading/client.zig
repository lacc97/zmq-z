const std = @import("std");
const print = std.debug.print;

const zmq = @import("zmq");

pub const std_options = struct {
    pub usingnamespace @import("log_options");
};

const info = std.log.info;

pub fn main() !void {
    const ctx = try zmq.Context.init();
    defer ctx.deinit();

    const sock = try ctx.open(.req);
    defer sock.close();

    info("Connecting to hello world server...", .{});

    try sock.connect("tcp://localhost:5555");

    for (0..10) |i| {
        var buf: [10]u8 = undefined;
        info("Sending Hello {}...", .{i});
        try sock.send("Hello", .{});
        _ = try sock.recv(&buf, .{});
        info("Received World {}", .{i});
    }
}
