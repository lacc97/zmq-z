const std = @import("std");

const zmq = @import("zmq");

pub const std_options = struct {
    pub usingnamespace @import("log_options");
};

const info = std.log.info;

pub fn main() !void {
    const ctx = try zmq.Context.init();
    defer ctx.deinit();

    const clients = try ctx.open(.router);
    defer clients.close();
    try clients.bind("tcp://*:5555");

    const workers = try ctx.open(.dealer);
    defer workers.close();
    try workers.bind("inproc://workers");

    for (0..4) |_| {
        (try std.Thread.spawn(.{}, worker, .{ctx})).detach();
    }

    try zmq.proxy(clients, workers, null);
}

fn worker(ctx: zmq.Context) !void {
    const sock = try ctx.open(.rep);
    defer sock.close();
    try sock.connect("inproc://workers");

    while (true) {
        var buf: [10]u8 = undefined;
        const value = try sock.recv(&buf, .{});
        info("Received {s}", .{value});
        std.time.sleep(1 * std.time.ns_per_s);
        try sock.send("World", .{});
    }
}
