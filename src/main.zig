const std = @import("std");
const clap = @import("clap");
const stderr = std.io.getStdErr().writer();

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

    if(args.option("--elf")) |elf| {
        std.debug.warn("elf: {s}\n", .{elf});
        return;
    } else if(args.option("--bin")) |bin| {
        std.debug.warn("flat binary: {s}\n", .{bin});

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
