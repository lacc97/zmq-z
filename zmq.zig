const std = @import("std");
const assert = std.debug.assert;

const c = @cImport(@cInclude("zmq.h"));

pub const Context = struct {
    raw: *anyopaque,

    pub const GetOption = enum(c_int) {
        io_threads = c.ZMQ_IO_THREADS,
        max_sockets = c.ZMQ_MAX_SOCKETS,
        socket_limit = c.ZMQ_SOCKET_LIMIT,
        thread_sched_policy = c.ZMQ_THREAD_SCHED_POLICY,
        max_msgsz = c.ZMQ_MAX_MSGSZ,
        msg_t_size = c.ZMQ_MSG_T_SIZE,
        thread_affinity_cpu_add = c.ZMQ_THREAD_AFFINITY_CPU_ADD,
        thread_affinity_cpu_remove = c.ZMQ_THREAD_AFFINITY_CPU_REMOVE,
        thread_name_prefix = c.ZMQ_THREAD_NAME_PREFIX,
    };

    pub const SetOption = enum(c_int) {
        io_threads = c.ZMQ_IO_THREADS,
        max_sockets = c.ZMQ_MAX_SOCKETS,
        thread_priority = c.ZMQ_THREAD_PRIORITY,
        thread_sched_policy = c.ZMQ_THREAD_SCHED_POLICY,
        max_msgsz = c.ZMQ_MAX_MSGSZ,
        msg_t_size = c.ZMQ_MSG_T_SIZE,
        thread_affinity_cpu_add = c.ZMQ_THREAD_AFFINITY_CPU_ADD,
        thread_affinity_cpu_remove = c.ZMQ_THREAD_AFFINITY_CPU_REMOVE,
        thread_name_prefix = c.ZMQ_THREAD_NAME_PREFIX,
    };

    pub fn init() !Context {
        const raw = try okOrErrno(c.zmq_ctx_new());
        return .{ .raw = raw };
    }
    pub fn deinit(ctx: Context) void {
        _ = c.zmq_ctx_term(ctx.raw);
    }

    pub fn getExt(ctx: Context, option: GetOption, buf: []u8) ![]u8 {
        // TODO: use zmq_ctx_get_ext() once it is available

        const value_len = @sizeOf(c_int);
        if (buf.len < value_len) return error.TooSmallBuffer;

        const value_ptr = std.mem.bytesAsValue(c_int, buf[0..value_len]);
        const value = c.zmq_ctx_get(ctx.raw, @intFromEnum(option));
        try okOrErrno(value);
        value_ptr.* = value;
        return buf[0..value_len];
    }

    pub fn get(ctx: Context, option: GetOption) !c_int {
        var value: c_int = undefined;
        _ = try ctx.getExt(option, std.mem.asBytes(&value));
        return value;
    }

    pub fn setExt(ctx: Context, option: SetOption, value_buf: []const u8) !void {
        // TODO: use zmq_ctx_set_ext() once it is available

        const value_len = @sizeOf(c_int);
        if (value_buf.len != value_len) return error.WrongSizeBuffer;

        const value = std.mem.bytesToValue(c_int, value_buf[0..value_len]);
        try okOrErrno(c.zmq_ctx_set(ctx.raw, @intFromEnum(option), value));
    }

    pub fn set(ctx: Context, option: SetOption, value: c_int) !void {
        try ctx.setExt(option, std.mem.asBytes(&value));
    }

    pub fn open(ctx: Context, typ: Socket.Type) !Socket {
        const raw = try okOrErrno(c.zmq_socket(ctx.raw, @intFromEnum(typ)));
        return .{ .raw = raw };
    }
};

pub const Socket = struct {
    raw: *anyopaque,

    pub const SendFlags = packed struct(c_uint) {
        dont_wait: bool = false,
        snd_more: bool = false,
        __1: std.meta.Int(.unsigned, @bitSizeOf(c_uint) - 2) = 0,
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

    pub const Option = enum(c_int) {
        affinity = c.ZMQ_AFFINITY,
        routing_id = c.ZMQ_ROUTING_ID,
        subscribe = c.ZMQ_SUBSCRIBE,
        unsubscribe = c.ZMQ_UNSUBSCRIBE,
        rate = c.ZMQ_RATE,
        recovery_ivl = c.ZMQ_RECOVERY_IVL,
        sndbuf = c.ZMQ_SNDBUF,
        rcvbuf = c.ZMQ_RCVBUF,
        rcvmore = c.ZMQ_RCVMORE,
        fd = c.ZMQ_FD,
        events = c.ZMQ_EVENTS,
        type = c.ZMQ_TYPE,
        linger = c.ZMQ_LINGER,
        reconnect_ivl = c.ZMQ_RECONNECT_IVL,
        backlog = c.ZMQ_BACKLOG,
        reconnect_ivl_max = c.ZMQ_RECONNECT_IVL_MAX,
        maxmsgsize = c.ZMQ_MAXMSGSIZE,
        sndhwm = c.ZMQ_SNDHWM,
        rcvhwm = c.ZMQ_RCVHWM,
        multicast_hops = c.ZMQ_MULTICAST_HOPS,
        rcvtimeo = c.ZMQ_RCVTIMEO,
        sndtimeo = c.ZMQ_SNDTIMEO,
        last_endpoint = c.ZMQ_LAST_ENDPOINT,
        router_mandatory = c.ZMQ_ROUTER_MANDATORY,
        tcp_keepalive = c.ZMQ_TCP_KEEPALIVE,
        tcp_keepalive_cnt = c.ZMQ_TCP_KEEPALIVE_CNT,
        tcp_keepalive_idle = c.ZMQ_TCP_KEEPALIVE_IDLE,
        tcp_keepalive_intvl = c.ZMQ_TCP_KEEPALIVE_INTVL,
        immediate = c.ZMQ_IMMEDIATE,
        xpub_verbose = c.ZMQ_XPUB_VERBOSE,
        router_raw = c.ZMQ_ROUTER_RAW,
        ipv6 = c.ZMQ_IPV6,
        mechanism = c.ZMQ_MECHANISM,
        plain_server = c.ZMQ_PLAIN_SERVER,
        plain_username = c.ZMQ_PLAIN_USERNAME,
        plain_password = c.ZMQ_PLAIN_PASSWORD,
        curve_server = c.ZMQ_CURVE_SERVER,
        curve_publickey = c.ZMQ_CURVE_PUBLICKEY,
        curve_secretkey = c.ZMQ_CURVE_SECRETKEY,
        curve_serverkey = c.ZMQ_CURVE_SERVERKEY,
        probe_router = c.ZMQ_PROBE_ROUTER,
        req_correlate = c.ZMQ_REQ_CORRELATE,
        req_relaxed = c.ZMQ_REQ_RELAXED,
        conflate = c.ZMQ_CONFLATE,
        zap_domain = c.ZMQ_ZAP_DOMAIN,
        router_handover = c.ZMQ_ROUTER_HANDOVER,
        tos = c.ZMQ_TOS,
        connect_routing_id = c.ZMQ_CONNECT_ROUTING_ID,
        gssapi_server = c.ZMQ_GSSAPI_SERVER,
        gssapi_principal = c.ZMQ_GSSAPI_PRINCIPAL,
        gssapi_service_principal = c.ZMQ_GSSAPI_SERVICE_PRINCIPAL,
        gssapi_plaintext = c.ZMQ_GSSAPI_PLAINTEXT,
        handshake_ivl = c.ZMQ_HANDSHAKE_IVL,
        socks_proxy = c.ZMQ_SOCKS_PROXY,
        xpub_nodrop = c.ZMQ_XPUB_NODROP,
        blocky = c.ZMQ_BLOCKY,
        xpub_manual = c.ZMQ_XPUB_MANUAL,
        xpub_welcome_msg = c.ZMQ_XPUB_WELCOME_MSG,
        stream_notify = c.ZMQ_STREAM_NOTIFY,
        invert_matching = c.ZMQ_INVERT_MATCHING,
        heartbeat_ivl = c.ZMQ_HEARTBEAT_IVL,
        heartbeat_ttl = c.ZMQ_HEARTBEAT_TTL,
        heartbeat_timeout = c.ZMQ_HEARTBEAT_TIMEOUT,
        xpub_verboser = c.ZMQ_XPUB_VERBOSER,
        connect_timeout = c.ZMQ_CONNECT_TIMEOUT,
        tcp_maxrt = c.ZMQ_TCP_MAXRT,
        thread_safe = c.ZMQ_THREAD_SAFE,
        multicast_maxtpdu = c.ZMQ_MULTICAST_MAXTPDU,
        vmci_buffer_size = c.ZMQ_VMCI_BUFFER_SIZE,
        vmci_buffer_min_size = c.ZMQ_VMCI_BUFFER_MIN_SIZE,
        vmci_buffer_max_size = c.ZMQ_VMCI_BUFFER_MAX_SIZE,
        vmci_connect_timeout = c.ZMQ_VMCI_CONNECT_TIMEOUT,
        use_fd = c.ZMQ_USE_FD,
        gssapi_principal_nametype = c.ZMQ_GSSAPI_PRINCIPAL_NAMETYPE,
        gssapi_service_principal_nametype = c.ZMQ_GSSAPI_SERVICE_PRINCIPAL_NAMETYPE,
        bindtodevice = c.ZMQ_BINDTODEVICE,
    };

    pub fn close(sock: Socket) void {
        _ = c.zmq_close(sock.raw);
    }

    pub fn getOpt(sock: Socket, opt: Option, buf: []u8) ![]u8 {
        var buflen: usize = buf.len;
        try okOrErrno(c.zmq_getsockopt(sock, @intFromEnum(opt), @ptrCast(buf.ptr), &buflen));
        return buf[0..buflen];
    }

    pub fn setOpt(sock: Socket, opt: Option, value: []const u8) !void {
        return okOrErrno(c.zmq_setsockopt(sock.raw, @intFromEnum(opt), @ptrCast(value.ptr), value.len));
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
