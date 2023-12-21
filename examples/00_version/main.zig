const std = @import("std");

const zmq = @import("zmq");

pub fn main() void {
    std.io.getStdOut().writer().print("{}\n", .{zmq.version()}) catch {};
}
