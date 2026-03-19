const Arm7 = @import("ARM7/ARM7TDMI.zig");
const std = @import("std");

pub const Nds = @This();

cpu: *Arm7,

pub fn init(cpu: *Arm7) Nds {
    return .{ .cpu = cpu };
}

pub fn stepPipeline(self: *Nds) void {
    debugPrint(self.cpu);
    self.cpu.step();
    debugPrint(self.cpu);
}

// Only for debugging

fn debugPrint(cpu: *Arm7) void {
    std.debug.print("Registers:\n", .{});
    for (0..16) |i| {
        std.debug.print("  r{d:<2} = 0x{x:0>8}\n", .{ i, cpu.r[i].get() });
    }
    std.debug.print("CPSR: 0x{x:0>8} [N={d} Z={d} C={d} V={d} T={d} M=0b{b:0>5}]\n", .{
        @as(u32, @bitCast(cpu.CPSR)),
        @intFromBool(cpu.CPSR.N),
        @intFromBool(cpu.CPSR.Z),
        @intFromBool(cpu.CPSR.C),
        @intFromBool(cpu.CPSR.V),
        @intFromBool(cpu.CPSR.thumb),
        cpu.CPSR.mode,
    });
    std.debug.print("Cycle counter: {any}\n", .{cpu.cycle_counter});
}
