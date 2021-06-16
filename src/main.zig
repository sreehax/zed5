const std = @import("std");
const clap = @import("clap");
const stderr = std.io.getStdErr().writer();
const util = @import("util.zig");
const Cpu = @import("Cpu.zig");

pub fn main() anyerror!void {
    const params = comptime [_]clap.Param(clap.Help){
        clap.parseParam("-h, --help           Display this help and exit.") catch unreachable,
        clap.parseParam("-b, --bin <STR>   Read instructions from a flat binary") catch unreachable,
        clap.parseParam("-e, --elf <STR>      Read instructions from an ELF object") catch unreachable
    };

    var diag = clap.Diagnostic{};
    var args = clap.parse(clap.Help, &params, .{ .diagnostic = &diag }) catch |err| {
        diag.report(stderr, err) catch {};
        return err;
    };
    defer args.deinit();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    if(args.option("--elf")) |elf| {
        const buf = try util.readFileFull(elf, &gpa.allocator);
        defer gpa.allocator.free(buf);

        try stderr.print("Read {} bytes\n", .{ buf.len });
        return;
    } else if(args.option("--bin")) |bin| {
        const buf = try util.readFileFull(bin, &gpa.allocator);
        defer gpa.allocator.free(buf);

        const cpu = try Cpu.fromElfBlob(buf, &gpa.allocator);
        defer cpu.mem.deinit();

        try stderr.print("Read {} bytes\n", .{ buf.len });
        return;
    }
    try stderr.print(
        \\zed5 by Sreehari Sreedev
        \\Usage:
        \\
        , .{}
    );
    try clap.help(
        stderr,
        &params
    );
}
