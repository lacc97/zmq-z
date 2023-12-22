const std = @import("std");
const print = std.debug.print;

const zmq = @import("zmq");

pub const std_options = struct {
    pub usingnamespace @import("log_options");
};

const info = std.log.info;

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    const ctx = try zmq.Context.init();
    defer ctx.deinit();

    const sock = try ctx.open(.sub);
    defer sock.close();

    info("Collecting updates from weather server...", .{});
    try sock.connect("tcp://localhost:5556");

    const filter = if (args.len > 1) args[1] else "10001";
    try sock.setOpt(.subscribe, filter);

    const num_updates = 100;
    var total_temp: i64 = 0;
    for (0..num_updates) |_| {
        var buf: [64]u8 = undefined;

        const update = try sock.recv(&buf, .{});
        var tokens = std.mem.tokenizeScalar(u8, update, ' ');
        const zip: u32 = try std.fmt.parseInt(u32, tokens.next() orelse return error.MalformedUpdate, 10);
        _ = zip;
        const temp: i32 = try std.fmt.parseInt(i32, tokens.next() orelse return error.MalformedUpdate, 10);
        const relhum: u32 = try std.fmt.parseInt(u32, tokens.next() orelse return error.MalformedUpdate, 10);
        _ = relhum;
        if (tokens.next() != null) return error.MalformedUpdate;
        total_temp += temp;
    }

    info(
        "Average temperature for zipcode '{s}' was {d}",
        .{
            filter,
            @as(f64, @floatFromInt(total_temp)) / @as(f64, @floatFromInt(num_updates)),
        },
    );
}
