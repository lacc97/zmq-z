const std = @import("std");

const c = @cImport(@cInclude("zmq.h"));

pub const Context = struct {
    raw: *anyopaque,

    pub fn init() !Context {
        const raw = try okOrErrno(c.zmq_ctx_new());
        return .{ .raw = raw };
    }
    pub fn deinit(ctx: Context) void {
        _ = c.zmq_ctx_destroy(ctx.raw);
    }

    pub fn open(ctx: Context, typ: Socket.Type) !Socket {
        const raw = try okOrErrno(c.zmq_socket(ctx.raw, @intFromEnum(typ)));
        return .{ .raw = raw };
    }
};

pub const Socket = struct {
    raw: *anyopaque,

    pub const SendFlags = packed struct(c_uint) {
        __1: u1 = 0,
        snd_more: bool = false,
        __2: std.meta.Int(.unsigned, @bitSizeOf(c_uint) - 2) = 0,
    };

    pub const RecvFlags = packed struct(c_uint) {
        dont_wait: bool = false,
        __1: std.meta.Int(.unsigned, @bitSizeOf(c_uint) - 1) = 0,
    };

    pub const Type = enum(c_int) {
        pair = c.ZMQ_PAIR,
        @"pub" = c.ZMQ_PUB,
        sub = c.ZMQ_SUB,
        req = c.ZMQ_REQ,
        rep = c.ZMQ_REP,
        dealer = c.ZMQ_DEALER,
        router = c.ZMQ_ROUTER,
        pull = c.ZMQ_PULL,
        push = c.ZMQ_PUSH,
        xpub = c.ZMQ_XPUB,
        xsub = c.ZMQ_XSUB,
        stream = c.ZMQ_STREAM,
    };

    pub fn close(sock: Socket) void {
        _ = c.zmq_close(sock.raw);
    }

    pub fn bind(sock: Socket, addr: [:0]const u8) !void {
        return okOrErrno(c.zmq_bind(sock.raw, addr.ptr));
    }

    pub fn connect(sock: Socket, addr: [:0]const u8) !void {
        return okOrErrno(c.zmq_connect(sock.raw, addr.ptr));
    }

    pub fn send(sock: Socket, buf: []const u8, flags: SendFlags) !void {
        try okOrErrno(c.zmq_send(
            sock.raw,
            @ptrCast(buf.ptr),
            buf.len,
            @bitCast(flags),
        ));
    }

    pub fn recv(sock: Socket, buf: []u8, flags: RecvFlags) ![]u8 {
        const len = c.zmq_recv(
            sock.raw,
            @ptrCast(buf.ptr),
            buf.len,
            @bitCast(flags),
        );
        try okOrErrno(len);
        return buf[0..@intCast(len)];
    }
};

pub fn version() std.SemanticVersion {
    var major: c_int = undefined;
    var minor: c_int = undefined;
    var patch: c_int = undefined;
    c.zmq_version(&major, &minor, &patch);
    return .{ .major = @intCast(major), .minor = @intCast(minor), .patch = @intCast(patch) };
}

fn OkOrErrno(comptime T: type) type {
    return ErrnoError!switch (@typeInfo(T)) {
        .Int => void,
        .Optional => |info| switch (@typeInfo(info.child)) {
            .Pointer => info.child,
            else => @compileError("invalid type: " ++ @typeName(T)),
        },
        else => @compileError("invalid type: " ++ @typeName(T)),
    };
}

fn okOrErrno(ret: anytype) OkOrErrno(@TypeOf(ret)) {
    return switch (@typeInfo(@TypeOf(ret))) {
        .Int => if (ret != -1) {} else return errno(),
        .Optional => |info| switch (@typeInfo(info.child)) {
            .Pointer => ret orelse return errno(),
            else => unreachable,
        },
        else => unreachable,
    };
}

const ErrnoError = error{Unexpected};

fn errno() ErrnoError {
    // TODO: other errors
    return error.Unexpected;
}
