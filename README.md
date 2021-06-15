# zed5
A simple 64-bit risc-v emulator written in Zig.
**Work in progress**

## Building
Just issue `zig build` to build the project, and `zig build run` to also run the project. To pass flags to the program, issue `zig build -- --flag1 --flag2` etc. You can also specify an optimization level to the `zig build` as a flag, `-Drelease-fast` is recommended.

## Example
A risc-v assembly example is already compiled in-tree, and you can just point the emulator to `zig-out/bin/add.elf`.

To build your own example that you can run in the emulator, you can either build assembly or C, assuming no unsupported instructions are emitted. For now, compressed instructions are not supported, so we must manually disable them. `zig cc` helps massively by dealing with all the target flags and stuff to build a freestanding binary easily. Since we're already using zig, we might as well use zig cc too!

To build anything for the emulator, issue this command: `zig cc -target riscv64-freestanding source.{c,S} -o code.elf -mcpu=baseline_rv64-c`. To break it down, this command instructs zig cc to build your source assembly or C files but disable the generation of compressed instructions. This is necessary as of now because compressed instructions are not a priority to be implemented. Assembly is recommended, because the whole riscv64gc (base integer, mult/div, atomics, single and double precision float, CSRs, and fences) is very distant from being supported, and assembly lets you choose instructions that are currently supported.

An example of some assembly file you can run soon is:
```asm
.global _start
_start:
addi t3, zero, 3
addi t4, t3, 12
add t6, t3, t4
```
