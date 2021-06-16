const std = @import("std");

pub fn readFileFull(name: []const u8, alloc: *std.mem.Allocator ) ![]u8 {
    const file = try std.fs.cwd().openFile(name, .{ .read = true });
    defer file.close();

    const stat = try file.stat();
    var buf = try file.readToEndAlloc(alloc, stat.size);
    return buf;
}
