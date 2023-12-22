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

    const frontend = try ctx.open(.router);
    defer frontend.close();

    const backend = try ctx.open(.dealer);
    defer backend.close();

    try frontend.bind("tcp://*:5559");
    try backend.bind("tcp://*:5560");

    var items = [_]zmq.PollItem{
        .{ .socket = frontend.raw, .fd = 0, .events = .{ .in = true } },
        .{ .socket = backend.raw, .fd = 0, .events = .{ .in = true } },
    };

    while (true) {
        _ = try zmq.poll(&items, -1);
        if (items[0].revents.in) {
            inner: while (true) {
                var msg: zmq.Message = undefined;
                msg.init();
                defer msg.close();

                try msg.recv(frontend, .{});
                const has_more = msg.hasMore();
                try msg.send(backend, .{ .snd_more = has_more });

                if (!has_more) break :inner;
            }
        }
        if (items[1].revents.in) {
            inner: while (true) {
                var msg: zmq.Message = undefined;
                msg.init();
                defer msg.close();

                try msg.recv(backend, .{});
                const has_more = msg.hasMore();
                try msg.send(frontend, .{ .snd_more = has_more });

                if (!has_more) break :inner;
            }
        }
    }
}
