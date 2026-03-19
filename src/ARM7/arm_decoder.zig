const instructions = @import("instructions.zig");
const types = @import("arm_types.zig");

pub fn decodeInstruction(opcode: u7, operand: u21) types.Instruction {
    return switch (opcode) {
        0x00 => .{ .AND = @bitCast(operand) },
        else => unreachable,
    };
}

pub fn decodeRegShift(type_code: u2) struct { shift_t: types.ShiftType } {
    return switch (type_code) {
        0b00 => .{ .shift_t = .LSL },
        0b01 => .{ .shift_t = .LSR },
        0b10 => .{ .shift_t = .ASR },
        0b11 => .{ .shift_t = .ROR },
    };
}
pub fn decodeImmShift(type_code: u2, imm5: u5) struct {
    shift_t: types.ShiftType,
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
