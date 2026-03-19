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

cycle_counter: u32 = 0,

pub fn init() ARM7TDMI {
    const val: u32 = 0;
    return .{
        .r = .{Register.init(0)} ** 16,
        .CPSR = @bitCast(val),
    };
}

pub fn step(self: *ARM7TDMI) void {
    const instruction = self.fetch();

    const opcode: u7 = @truncate(instruction >> 21);
    const operand: u21 = @truncate(instruction);
    const instr = decoder.decodeInstruction(opcode, operand);

    return switch (instr) {
        inline else => |op| op.execute(self),
    };
}

pub fn tick(self: *ARM7TDMI) void {
    self.cycle_counter +%= 1;
}

pub fn fetch(self: *ARM7TDMI) u32 {
    const pc = self.r[15].get();
    self.cycle_counter +%= 1;
    const instruction = 0xE0021413;
    self.r[15].set(pc + 4);
    return instruction;
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

// === TESTS ===
pub fn execute(self: *ARM7TDMI, instruction: u32) void {
    const opcode: u7 = @truncate(instruction >> 21);
    const operand: u21 = @truncate(instruction);
    const instr = decoder.decodeInstruction(opcode, operand);

    return switch (instr) {
        inline else => |op| op.execute(self),
    };
}

test "setFlags only changes specified flags" {
    var cpu = ARM7TDMI.init();
    cpu.CPSR.V = true;
    cpu.setFlags(.{ .Z = true });
    try std.testing.expect(cpu.CPSR.V);
    try std.testing.expect(cpu.CPSR.Z);
}
