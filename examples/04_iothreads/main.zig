const std = @import("std");

const zmq = @import("zmq");

pub const std_options = struct {
    pub const log_level = .info;
};

const info = std.log.info;

pub fn main() !void {
    const ctx = try zmq.Context.init();
    defer ctx.deinit();

    info("iothreads is initially set to {}", .{try ctx.get(.io_threads)});
    try ctx.set(.io_threads, 4);
    info("iothreads now set to {}", .{try ctx.get(.io_threads)});
}
