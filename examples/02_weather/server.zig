const std = @import("std");

const zmq = @import("zmq");

pub const std_options = struct {
    pub usingnamespace @import("log_options");
};

const info = std.log.info;

pub fn main() !void {
    var rng_state = std.rand.DefaultPrng.init(0);
    const rng = rng_state.random();

    const ctx = try zmq.Context.init();
    defer ctx.deinit();

    const sock = try ctx.open(.@"pub");
    defer sock.close();

    try sock.bind("tcp://*:5556");

    while (true) {
        var buf: [32]u8 = undefined;

        const zip = rng.intRangeLessThan(u32, 0, 100000);
        const temp = rng.intRangeAtMost(i32, -60, 60);
        const relhum = rng.intRangeAtMost(u32, 10, 100);

        const msg_buf = try std.fmt.bufPrint(&buf, "{d:05} {} {}", .{ zip, temp, relhum });
        try sock.send(msg_buf, .{});
    }
}
