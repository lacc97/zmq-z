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

    try sock.connect("tcp://localhost:5560");

    while (true) {
        var buf: [10]u8 = undefined;
        const request = try sock.recv(&buf, .{});
        info("Received request: [{s}]", .{request});
        std.time.sleep(1 * std.time.ns_per_s);
        try sock.send("World", .{});
    }
}
