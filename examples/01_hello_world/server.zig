const std = @import("std");

const zmq = @import("zmq");

pub const std_options = struct {
    pub usingnamespace @import("log_options");
};

const info = std.log.info;

pub fn main() !void {
    const ctx = try zmq.Context.init();
    defer ctx.deinit();

    const sock = try ctx.open(.rep);
    defer sock.close();

    try sock.bind("tcp://*:5555");

    while (true) {
        var buf: [10]u8 = undefined;
        _ = try sock.recv(&buf, .{});
        info("Received Hello", .{});
        std.time.sleep(1 * std.time.ns_per_s);
        try sock.send("World", .{});
    }
}
