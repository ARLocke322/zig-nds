const Register = @import("register.zig").Register;
pub const ARM7TDMI = @This();
const std = @import("std");
const decoder = @import("arm_decoder.zig");
const types = @import("arm_types.zig");

r: [16]Register,

CPSR: packed struct(u32) {
    mode: u5,
    thumb: bool,
    fiq_disable: bool,
    irq_disable: bool,
    _reserved: u20 = 0,
    V: bool,
    C: bool,
    Z: bool,
    N: bool,
},

pub fn init() ARM7TDMI {
    const val: u32 = 0;
    return .{
        .r = .{Register.init(0)} ** 16,
        .CPSR = @bitCast(val),
    };
}

pub fn execute(self: *ARM7TDMI, instruction: u32) void {
    const opcode: u7 = @truncate(instruction >> 21);
    const operand: u21 = @truncate(instruction);
    const instr: types.Instruction = decoder.decodeInstruction(opcode, operand);

    // self.debugPrint();

    switch (instr) {
        inline else => |op| op.execute(self),
    }

    // self.debugPrint();
}

pub fn setFlags(self: *ARM7TDMI, opts: struct {
    V: ?bool = null,
    C: ?bool = null,
    Z: ?bool = null,
    N: ?bool = null,
}) void {
    if (opts.V) |V| self.CPSR.V = V;
    if (opts.C) |C| self.CPSR.C = C;
    if (opts.Z) |Z| self.CPSR.Z = Z;
    if (opts.N) |N| self.CPSR.N = N;
}

// Only for debugging

fn debugPrint(cpu: *ARM7TDMI) void {
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
}

test "setFlags only changes specified flags" {
    var cpu = ARM7TDMI.init();
    cpu.CPSR.V = true;
    cpu.setFlags(.{ .Z = true });
    try std.testing.expect(cpu.CPSR.V);
    try std.testing.expect(cpu.CPSR.Z);
}
