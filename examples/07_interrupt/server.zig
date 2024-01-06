const std = @import("std");

const zmq = @import("zmq");

pub const std_options = struct {
    pub usingnamespace @import("log_options");
};

const info = std.log.info;

pub fn main() !void {
    const ctx = try zmq.Context.init();
    defer ctx.deinit();

    const pipes = try std.os.pipe2(std.os.O.NONBLOCK);
    defer for (pipes) |p| std.os.close(p);

    try initSigHandler(pipes[1]);

    const sock = try ctx.open(.rep);
    defer sock.close();
    try sock.bind("tcp://*:5555");

    var items = [_]zmq.PollItem{
        .{ .socket = null, .fd = pipes[0], .events = .{ .in = true } },
        .{ .socket = sock.raw, .fd = 0, .events = .{ .in = true } },
    };

    runloop: while (true) {
        _ = zmq.poll(&items, -1) catch |err| {
            if (err == error.Interrupted) continue :runloop;
            return err;
        };

        if (items[0].revents.in) {
            break :runloop;
        }

        if (items[1].revents.in) {
            var buf: [32]u8 = undefined;

            const task = try sock.recv(&buf, .{});
            info("received `{s}`.", .{task});
            std.time.sleep(1 * std.time.ns_per_s);
            try sock.send("World", .{});
        }
    }
}

var sig_fd: std.os.fd_t = undefined;

fn initSigHandler(fd: std.os.fd_t) !void {
    sig_fd = fd;

    var sa = std.mem.zeroes(std.os.Sigaction);
    sa.handler.handler = &sighandler;
    try std.os.sigaction(std.os.SIG.INT, &sa, null);
    try std.os.sigaction(std.os.SIG.TERM, &sa, null);
}

fn sighandler(_: c_int) callconv(.C) void {
    const msg = " ";
    _ = std.os.write(sig_fd, msg) catch |err| {
        std.debug.print("Error while writing to self-pipe: {}\n", .{err});
        std.process.exit(1);
    };
}
