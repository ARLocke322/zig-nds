const std = @import("std");
const Io = std.Io;

const zig_ds = @import("zig_ds");
const Cpu = @import("ARM7/ARM7TDMI.zig").ARM7TDMI;

pub fn main() !void {
    var cpu: Cpu = .init();
    cpu.r[2].set(0xFF00FF00);
    cpu.r[3].set(0x0F0F0F0F);
    cpu.execute(0xE0021003);
}
