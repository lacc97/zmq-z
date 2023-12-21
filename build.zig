const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zeromq_dep = b.dependency("zeromq", .{});

    const lib = b.addStaticLibrary(.{
        .name = "zmq",
        .target = target,
        .optimize = optimize,
    });
    configurePlatform(b, zeromq_dep, lib);
    lib.addIncludePath(zeromq_dep.path("src"));
    lib.addCSourceFiles(.{ .dependency = zeromq_dep, .files = &base_sources, .flags = &.{} });
    lib.linkLibCpp();
    lib.installHeadersDirectoryOptions(.{
        .install_dir = .header,
        .install_subdir = "",
        .source_dir = zeromq_dep.path("include"),
    });
    b.installArtifact(lib);

    const mod = b.addModule("zmq", .{ .source_file = .{ .path = "zmq.zig" } });

    buildExamples(b, lib, mod);
}

fn configurePlatform(b: *std.Build, dep: *std.Build.Dependency, lib: *std.Build.Step.Compile) void {
    const defineIf = struct {
        fn defineIf(cond: bool) ?void {
            return if (cond) {} else null;
        }
    }.defineIf;
    const defineOne = struct {
        fn defineOne(cond: bool) ?i64 {
            return if (cond) 1 else null;
        }
    }.defineOne;

    const CV = enum { none, stl, win32, pthreads };
    const Poller = enum { none, select, poll, pollset, devpoll, epoll, kqueue };

    const target = lib.target.toTarget();

    const cacheline_size: isize = switch (target.cpu.arch) {
        // Stolen from straight from std.atomic.cache_line logic.

        .x86_64, .aarch64, .powerpc64 => 128,
        .arm, .mips, .mips64, .riscv64 => 32,
        .s390x => 256,
        else => 64,
    };

    const cv_impl: CV = switch (target.os.tag) {
        .windows => .win32,
        .linux => .pthreads, // TODO: other pthread
        else => .stl,
    };
    const poller_impl: Poller = if (target.os.tag.isDarwin())
        .kqueue
    else if (target.os.tag.isBSD())
        .poll
    else switch (target.os.tag) {
        .linux => .epoll,
        else => .select,
    };

    const have_ipc = true;
    const have_sockaddr_un = (target.os.tag != .windows);

    const have_eventfd = (target.os.tag == .linux);
    const have_uio = (target.os.tag == .linux);
    const have_ifaddrs = (target.os.tag == .linux);

    const have_o_cloexec = (target.os.tag == .linux);
    const have_sock_cloexec = (target.os.tag == .linux);

    const have_pthread_setname_1 = false;
    const have_pthread_setname_2 = (target.os.tag == .linux);
    const have_pthread_setname_3 = false;
    const have_pthread_set_affinity = (target.os.tag == .linux);

    const have_strnlen = true;

    const platform_hpp = b.addConfigHeader(.{
        .style = .{ .cmake = dep.path("builds/cmake/platform.hpp.in") },
        .include_path = "platform.hpp",
    }, .{
        .ZMQ_USE_CV_IMPL_STL11 = defineIf(cv_impl == .stl),
        .ZMQ_USE_CV_IMPL_WIN32API = defineIf(cv_impl == .win32),
        .ZMQ_USE_CV_IMPL_PTHREADS = defineIf(cv_impl == .pthreads),
        .ZMQ_USE_CV_IMPL_NONE = defineIf(cv_impl == .none),

        .ZMQ_IOTHREAD_POLLER_USE_KQUEUE = defineIf(poller_impl == .kqueue),
        .ZMQ_IOTHREAD_POLLER_USE_EPOLL = defineIf(poller_impl == .epoll),
        .ZMQ_IOTHREAD_POLLER_USE_EPOLL_CLOEXEC = defineIf(poller_impl == .epoll),
        .ZMQ_IOTHREAD_POLLER_USE_DEVPOLL = defineIf(poller_impl == .devpoll),
        .ZMQ_IOTHREAD_POLLER_USE_POLLSET = defineIf(poller_impl == .pollset),
        .ZMQ_IOTHREAD_POLLER_USE_POLL = defineIf(poller_impl == .poll),
        .ZMQ_IOTHREAD_POLLER_USE_SELECT = defineIf(poller_impl == .select),

        .ZMQ_POLL_BASED_ON_SELECT = defineIf(poller_impl == .select),
        .ZMQ_POLL_BASED_ON_POLL = defineIf(poller_impl != .select),

        .ZMQ_CACHELINE_SIZE = cacheline_size,

        .ZMQ_HAVE_WINDOWS = defineIf(target.os.tag == .windows),

        .ZMQ_HAVE_IPC = defineIf(have_ipc),
        .ZMQ_HAVE_SOCKADDR_UN = defineIf(have_sockaddr_un),

        .ZMQ_HAVE_EVENTFD = defineIf(have_eventfd),
        .ZMQ_HAVE_UIO = defineIf(have_uio),
        .ZMQ_HAVE_IFADDRS = defineIf(have_ifaddrs),

        .ZMQ_HAVE_O_CLOEXEC = defineIf(have_o_cloexec),
        .ZMQ_HAVE_SOCK_CLOEXEC = defineIf(have_sock_cloexec),

        .ZMQ_HAVE_PTHREAD_SETNAME_1 = defineIf(have_pthread_setname_1),
        .ZMQ_HAVE_PTHREAD_SETNAME_2 = defineIf(have_pthread_setname_2),
        .ZMQ_HAVE_PTHREAD_SETNAME_3 = defineIf(have_pthread_setname_3),
        .ZMQ_HAVE_PTHREAD_SET_AFFINITY = defineIf(have_pthread_set_affinity),

        .HAVE_POSIX_MEMALIGN = defineOne(target.os.tag != .windows),
        .HAVE_STRNLEN = defineIf(have_strnlen),
    });
    lib.addConfigHeader(platform_hpp);
}

fn buildExamples(b: *std.Build, lib: *std.Build.Step.Compile, mod: *std.Build.Module) void {
    const step = b.step("examples", "Build and install examples");

    {
        const server_exe = b.addExecutable(.{
            .name = "01_hello_world",
            .root_source_file = .{ .path = "examples/01_hello_world/server.zig" },
            .target = lib.target,
            .optimize = lib.optimize,
        });
        server_exe.addModule("zmq", mod);
        server_exe.linkLibrary(lib);

        step.dependOn(&b.addInstallArtifact(server_exe, .{ .dest_sub_path = "01_hello_world/server" }).step);

        const client_exe = b.addExecutable(.{
            .name = "01_hello_world",
            .root_source_file = .{ .path = "examples/01_hello_world/client.zig" },
            .target = lib.target,
            .optimize = lib.optimize,
        });
        client_exe.addModule("zmq", mod);
        client_exe.linkLibrary(lib);

        step.dependOn(&b.addInstallArtifact(client_exe, .{ .dest_sub_path = "01_hello_world/client" }).step);
    }
}

const base_sources = [_][]const u8{
    "src/precompiled.cpp",
    "src/address.cpp",
    "src/channel.cpp",
    "src/client.cpp",
    "src/clock.cpp",
    "src/ctx.cpp",
    "src/curve_mechanism_base.cpp",
    "src/curve_client.cpp",
    "src/curve_server.cpp",
    "src/dealer.cpp",
    "src/devpoll.cpp",
    "src/dgram.cpp",
    "src/dist.cpp",
    "src/endpoint.cpp",
    "src/epoll.cpp",
    "src/err.cpp",
    "src/fq.cpp",
    "src/io_object.cpp",
    "src/io_thread.cpp",
    "src/ip.cpp",
    "src/ipc_address.cpp",
    "src/ipc_connecter.cpp",
    "src/ipc_listener.cpp",
    "src/kqueue.cpp",
    "src/lb.cpp",
    "src/mailbox.cpp",
    "src/mailbox_safe.cpp",
    "src/mechanism.cpp",
    "src/mechanism_base.cpp",
    "src/metadata.cpp",
    "src/msg.cpp",
    "src/mtrie.cpp",
    "src/norm_engine.cpp",
    "src/object.cpp",
    "src/options.cpp",
    "src/own.cpp",
    "src/null_mechanism.cpp",
    "src/pair.cpp",
    "src/peer.cpp",
    "src/pgm_receiver.cpp",
    "src/pgm_sender.cpp",
    "src/pgm_socket.cpp",
    "src/pipe.cpp",
    "src/plain_client.cpp",
    "src/plain_server.cpp",
    "src/poll.cpp",
    "src/poller_base.cpp",
    "src/polling_util.cpp",
    "src/pollset.cpp",
    "src/proxy.cpp",
    "src/pub.cpp",
    "src/pull.cpp",
    "src/push.cpp",
    "src/random.cpp",
    "src/raw_encoder.cpp",
    "src/raw_decoder.cpp",
    "src/raw_engine.cpp",
    "src/reaper.cpp",
    "src/rep.cpp",
    "src/req.cpp",
    "src/router.cpp",
    "src/select.cpp",
    "src/server.cpp",
    "src/session_base.cpp",
    "src/signaler.cpp",
    "src/socket_base.cpp",
    "src/socks.cpp",
    "src/socks_connecter.cpp",
    "src/stream.cpp",
    "src/stream_engine_base.cpp",
    "src/sub.cpp",
    "src/tcp.cpp",
    "src/tcp_address.cpp",
    "src/tcp_connecter.cpp",
    "src/tcp_listener.cpp",
    "src/thread.cpp",
    "src/trie.cpp",
    "src/radix_tree.cpp",
    "src/v1_decoder.cpp",
    "src/v1_encoder.cpp",
    "src/v2_decoder.cpp",
    "src/v2_encoder.cpp",
    "src/v3_1_encoder.cpp",
    "src/xpub.cpp",
    "src/xsub.cpp",
    "src/zmq.cpp",
    "src/zmq_utils.cpp",
    "src/decoder_allocators.cpp",
    "src/socket_poller.cpp",
    "src/timers.cpp",
    "src/radio.cpp",
    "src/dish.cpp",
    "src/udp_engine.cpp",
    "src/udp_address.cpp",
    "src/scatter.cpp",
    "src/gather.cpp",
    "src/ip_resolver.cpp",
    "src/zap_client.cpp",
    "src/zmtp_engine.cpp",
    "src/stream_connecter_base.cpp",
    "src/stream_listener_base.cpp",
};
