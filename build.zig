const std = @import("std");
const baseline_rv64 = std.Target.riscv.cpu.baseline_rv64;
const FeatureSet = std.Target.Cpu.Feature.Set;

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // the main emulator executable
    const exe = b.addExecutable("zed5", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackage(.{
        .name = "clap",
        .path = .{ .path = "libs/zig-clap/clap.zig" }
    });
    exe.install();

    // the add/addi asm example
    const add = b.addExecutable("add.elf", null);
    var f = FeatureSet.empty;
    const comp: std.Target.riscv.Feature = .c;
    f.addFeature(@enumToInt(comp));
    add.setTarget(.{
        .cpu_arch = .riscv64,
        .os_tag = .freestanding,
        .cpu_model = .{ .explicit = &baseline_rv64 },
        .cpu_features_sub = f
    });
    add.addAssemblyFile("src/add.S");
    add.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
