const Register = @import("register.zig");
const Cpu = @import("ARM7TDMI.zig").ARM7TDMI;

pub const Instruction = union(enum) {
    AND: AND,
};

pub fn decode(raw_instruction: u28) AND {
    const opcode: u7 = @truncate(raw_instruction >> 21);
    const operand: u21 = @truncate(raw_instruction);
    return switch (opcode) {
        0x00 => @bitCast(operand),
        else => unreachable,
    };
}

pub const AND = packed struct(u21) {
    Rm: u4,
    register_shifted_register: bool,
    type_code: u2,
    imm5: u5,
    Rd: u4,
    Rn: u4,
    S: bool,

    pub fn execute(self: AND, cpu: *Cpu) void {
        const shift_params = decodeImmShift(self.type_code, self.imm5);
        const shift_result = getShifted(cpu.r[self.Rm].get(), shift_params.shift_t, shift_params.shift_n);

        const result = cpu.r[self.Rn].get() & shift_result.value;
        cpu.r[self.Rd].set(result);

        if (self.S) updateFlags(cpu, result, shift_result.carry);
    }

    fn updateFlags(cpu: *Cpu, result: u32, carry: ?u1) void {
        cpu.setFlags(.{
            .C = if (carry != null) carry == 1 else null,
            .Z = result == 0,
        });
    }
};

fn decodeImmShift(type_code: u2, imm5: u5) struct {
    shift_t: shift_type,
    shift_n: u8,
} {
    return switch (type_code) {
        0b00 => .{ .shift_t = .LSL, .shift_n = @as(u8, imm5) },
        0b01 => .{ .shift_t = .LSR, .shift_n = if (imm5 == 0) 32 else @as(u8, imm5) },
        0b10 => .{ .shift_t = .ASR, .shift_n = if (imm5 == 0) 32 else @as(u8, imm5) },
        0b11 => if (imm5 == 0)
            .{ .shift_t = .RRX, .shift_n = 1 }
        else
            .{ .shift_t = .ROR, .shift_n = @as(u8, imm5) },
    };
}

fn getShifted(current: u32, shift_t: shift_type, shift_n: u8) struct {
    value: u32,
    carry: ?u1,
} {
    return switch (shift_t) {
        .LSL => {
            if (shift_n == 0) return .{ .value = current, .carry = null };
            return .{
                .value = if (shift_n < 32) current << @intCast(shift_n) else 0,
                .carry = @truncate(current >> @intCast(32 - shift_n)),
            };
        },
        // .LSR => execLSR(register, shift_n),
        // .ASR => execASR(register, shift_n),
        // .RRX => execRRX(register, shift_n),
        // .ROR => execROR(register, shift_n),
        else => unreachable,
    };
}

pub const shift_type = enum { LSL, LSR, ASR, RRX, ROR };
