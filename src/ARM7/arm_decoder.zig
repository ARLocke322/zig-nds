const std = @import("std");
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

test "decode AND register" {
    const instr = decodeInstruction(0x00, @truncate(@as(u32, 0xE0021003)));
    try std.testing.expectEqual(@as(u4, 3), instr.AND.Rm);
    try std.testing.expectEqual(@as(u4, 1), instr.AND.Rd);
    try std.testing.expectEqual(@as(u4, 2), instr.AND.Rn);
    try std.testing.expectEqual(false, instr.AND.S);
    try std.testing.expectEqual(false, instr.AND.register_shifted_register);
}

// decodeRegShift
test "decodeRegShift LSL" {
    const r = decodeRegShift(0b00);
    try std.testing.expectEqual(types.ShiftType.LSL, r.shift_t);
}
test "decodeRegShift LSR" {
    const r = decodeRegShift(0b01);
    try std.testing.expectEqual(types.ShiftType.LSR, r.shift_t);
}
test "decodeRegShift ASR" {
    const r = decodeRegShift(0b10);
    try std.testing.expectEqual(types.ShiftType.ASR, r.shift_t);
}
test "decodeRegShift ROR" {
    const r = decodeRegShift(0b11);
    try std.testing.expectEqual(types.ShiftType.ROR, r.shift_t);
}

// decodeImmShift  normal values
test "LSL imm5=5 means shift by 5" {
    const r = decodeImmShift(0b00, 5);
    try std.testing.expectEqual(types.ShiftType.LSL, r.shift_t);
    try std.testing.expectEqual(@as(u8, 5), r.shift_n);
}
test "LSL imm5=0 means shift by 0" {
    const r = decodeImmShift(0b00, 0);
    try std.testing.expectEqual(types.ShiftType.LSL, r.shift_t);
    try std.testing.expectEqual(@as(u8, 0), r.shift_n);
}
test "LSR imm5=16 means shift by 16" {
    const r = decodeImmShift(0b01, 16);
    try std.testing.expectEqual(types.ShiftType.LSR, r.shift_t);
    try std.testing.expectEqual(@as(u8, 16), r.shift_n);
}
test "ASR imm5=8 means shift by 8" {
    const r = decodeImmShift(0b10, 8);
    try std.testing.expectEqual(types.ShiftType.ASR, r.shift_t);
    try std.testing.expectEqual(@as(u8, 8), r.shift_n);
}
test "ROR imm5=12 means shift by 12" {
    const r = decodeImmShift(0b11, 12);
    try std.testing.expectEqual(types.ShiftType.ROR, r.shift_t);
    try std.testing.expectEqual(@as(u8, 12), r.shift_n);
}

// decodeImmShift - special cases
test "RRX shift amount is 1" {
    const r = decodeImmShift(0b11, 0);
    try std.testing.expectEqual(types.ShiftType.RRX, r.shift_t);
    try std.testing.expectEqual(@as(u8, 1), r.shift_n);
}
test "LSR imm5=0 means shift by 32" {
    const r = decodeImmShift(0b01, 0);
    try std.testing.expectEqual(types.ShiftType.LSR, r.shift_t);
    try std.testing.expectEqual(@as(u8, 32), r.shift_n);
}
test "ASR imm5=0 means shift by 32" {
    const r = decodeImmShift(0b10, 0);
    try std.testing.expectEqual(types.ShiftType.ASR, r.shift_t);
    try std.testing.expectEqual(@as(u8, 32), r.shift_n);
}
