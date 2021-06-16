const std = @import("std");
const Self = @This();
const MyError = error {
    ElfTooSmall,
    CompressedInstruction,
    InvalidInstruction
};
// imports are structs, so this whole file is a struct

// integer registers
iregs: [32]u64,
// program counter
pc: u64,
// memory is a flat blob
mem: std.ArrayList(u8),

// instruction cycle
pub fn mainloop(self: *Self) anyerror!void {
    // set the stack pointer (sp = x2) to the end of memory, since it grows downwards
    // https://riscv.org/wp-content/uploads/2015/01/riscv-calling.pdf
    self.iregs[2] = self.mem.capacity;

    while (self.pc < self.mem.capacity) {
        // https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf
        // each cycle be sure to zero out the zero register to make sure its hardwired 0
        self.iregs[0] = 0;

        // fetch the current instruction or die if it's not possible to fetch anymore
        // this is a u32 because screw compressed instructions for now
        const inst = self.fetch();
        self.pc += 4;
        // we dont do compressed instructions here yet
        if (inst & 0b11 != 0b11) {
            std.log.warn("We dont do compressed instructions here...", .{});
            return MyError.CompressedInstruction;
        }
        try self.execute(inst);
    }
}

// get the current instruction
fn fetch(self: *Self) u32 {
    // little endian moment
    const i = self.pc;
    const ram = self.mem.items;
    return (@intCast(u32, ram[i + 3]) << 24) 
         | (@intCast(u32, ram[i + 2]) << 16) 
         | (@intCast(u32, ram[i + 1]) << 8) 
         | ram[i];
}
// execute a given instruction
fn execute(self: *Self, inst: u32) !void {
    const opcode = @truncate(u7, inst);
    std.debug.print("0b{b}\n", .{opcode});
    switch (opcode) {
        0b0010011 => {
            std.debug.print("addi instruction detected\n", .{});
        },
        0b0110011 => {
            std.debug.print("add instruction detected\n", .{});
        },
        else => {
            std.debug.print("unknown instruction detected\n", .{});
        }
    }
}
// load the blob straight to the beginning of the memory and instantiate the CPU
pub fn fromFlatBlob(blob: []const u8, alloc: *std.mem.Allocator) !Self {
    // zeroed registers and pc
    var cpu = Self {
        .iregs = std.mem.zeroes([32]u64),
        .pc = 0,
        .mem = std.ArrayList(u8).init(alloc)
    };
    // reserve 64M of memory
    try cpu.mem.resize(64 * 1024 * 1024);
    // fill the beginning with the blob starting at address 0
    try cpu.mem.replaceRange(0, blob.len, blob);
    return cpu;
}

// load an ELF binary and actually map it properly to memory
pub fn fromElfBlob(blob: []const u8, alloc: *std.mem.Allocator) !Self {
    // make sure the slice can actually fit an ELF header
    if(blob.len < @sizeOf(std.elf.Elf64_Ehdr)) {
        return MyError.ElfTooSmall;
    }
    // get a FixedBufferStream
    var bufstream = std.io.fixedBufferStream(blob);
    // get an ELF header object
    var ehdr = try std.elf.Header.read(&bufstream);
    // zeroed registers, set PC to the entry point
    var cpu = Self {
        .iregs = std.mem.zeroes([32]u64),
        .pc = ehdr.entry,
        .mem = std.ArrayList(u8).init(alloc)
    };
    // get a program header iterator
    var it = ehdr.program_header_iterator(&bufstream);
    // reserve 64M of memory
    try cpu.mem.resize(64 * 1024 * 1024);
    // load all the sections into memory!
    while(it.next() catch unreachable) |phdr| {
        if(phdr.p_type == std.elf.PT_LOAD) {
            std.debug.print("load {} bytes at 0x{x} from offset {}\n", .{phdr.p_filesz, phdr.p_vaddr, phdr.p_offset});
            try cpu.mem.replaceRange(phdr.p_vaddr, phdr.p_filesz, blob[phdr.p_offset..(phdr.p_offset+phdr.p_filesz)]);
        }
    }
    return cpu;
}
