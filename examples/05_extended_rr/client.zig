const std = @import("std");
const print = std.debug.print;

const zmq = @import("zmq");

pub const std_options = struct {
    pub const log_level = .info;
};

const info = std.log.info;

pub fn main() !void {
    const ctx = try zmq.Context.init();
    defer ctx.deinit();

    const sock = try ctx.open(.req);
    defer sock.close();

    info("Connecting to hello world server...", .{});

    try sock.connect("tcp://localhost:5559");

    for (0..10) |i| {
        var buf: [10]u8 = undefined;
        try sock.send("Hello", .{});
        const reply = try sock.recv(&buf, .{});
        info("Received reply {}: [{s}]", .{ i, reply });
    }
}
