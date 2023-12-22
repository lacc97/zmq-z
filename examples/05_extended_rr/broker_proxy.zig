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

    try zmq.proxy(frontend, backend, null);
}
