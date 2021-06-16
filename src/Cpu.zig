const std = @import("std");
const Self = @This();
const ElfError = error {
    ElfTooSmall
};
// imports are structs, so this whole file is a struct

// integer registers
iregs: [32]u64,
// program counter
pc: u64,
// memory is a flat blob
mem: std.ArrayList(u8),

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
        return ElfError.ElfTooSmall;
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
