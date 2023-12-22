const std = @import("std");

pub const log_level = .info;

pub fn logFn(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    const stderr = std.io.getStdErr().writer();
    var stderr_buffer = std.io.bufferedWriter(stderr);
    std.debug.getStderrMutex().lock();
    defer std.debug.getStderrMutex().unlock();
    defer nosuspend stderr_buffer.flush() catch {};
    nosuspend stderr_buffer.writer().print(level_txt ++ prefix2 ++ format ++ "\n", args) catch return;
}
