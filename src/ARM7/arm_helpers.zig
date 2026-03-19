const std = @import("std");
const types = @import("arm_types.zig");
const Cpu = @import("ARM7TDMI.zig").ARM7TDMI;
const decoder = @import("arm_decoder.zig");

pub const ShiftResult = struct {
    value: u32,
    carry: u1,
};

pub fn getShiftResult(
    cpu: *Cpu,
    register_shifted_register: bool,
    type_code: u2,
    imm5: u5,
    current: u32,
) ShiftResult {
    if (register_shifted_register) {
        cpu.tick();
        const shift_params = decoder.decodeRegShift(type_code);
        const Rs: u4 = @truncate(imm5 >> 1);
        return getShifted(
            current,
            shift_params.shift_t,
            @truncate(cpu.r[Rs].get()),
            @bitCast(cpu.CPSR.C),
        );
    } else {
        const shift_params = decoder.decodeImmShift(type_code, imm5);
        return getShifted(
            current,
            shift_params.shift_t,
            shift_params.shift_n,
            @bitCast(cpu.CPSR.C),
        );
    }
}

pub fn getShifted(current: u32, shift_t: types.ShiftType, shift_n: u8, carry_in: u1) ShiftResult {
    if (shift_n == 0 or (shift_n == 32 and shift_t == .ROR))
        return .{ .value = current, .carry = carry_in };
    return switch (shift_t) {
        .LSL => {
            return .{
                .value = if (shift_n < 32) current << @intCast(shift_n) else 0,
                .carry = if (shift_n <= 32) @truncate(current >> @intCast(32 - shift_n)) else 0,
            };
        },
        .LSR => {
            return .{
                .value = if (shift_n < 32) current >> @intCast(shift_n) else 0,
                .carry = if (shift_n <= 32) @truncate(current >> @intCast(shift_n - 1)) else 0,
            };
        },
        .ASR => {
            const msb: u1 = @truncate(current >> 31);
            if (shift_n >= 32) return .{ .value = if (msb == 0) 0x0 else 0xFFFFFFFF, .carry = msb };
            return .{
                .value = if (msb == 0)
                    current >> @intCast(shift_n)
                else
                    (current >> @intCast(shift_n)) | (@as(u32, 0xFFFFFFFF) << @intCast(32 - shift_n)),
                .carry = @truncate(current >> @intCast(shift_n - 1)),
            };
        },
        .RRX => {
            std.debug.assert(shift_n == 1);
            return .{
                .value = (current >> 1) | (@as(u32, carry_in) << 31),
                .carry = @truncate(current),
            };
        },
        .ROR => {
            if (shift_n % 32 == 0) return .{
                .value = current,
                .carry = @truncate(current >> 31),
            };
            return .{
                .value = std.math.rotr(u32, current, @as(u32, shift_n)),
                .carry = @truncate(current >> @intCast(shift_n % 32 - 1)),
            };
        },
    };
}

// === TESTS ===

// getShifted
test "Shifting by 0 preserves value" {
    const r = getShifted(0xFF, .LSL, 0, 0);
    try std.testing.expectEqual(@as(u32, 0xFF), r.value);
    try std.testing.expectEqual(@as(u1, 0), r.carry);
}

test "LSL by 1" {
    const r = getShifted(0x80000001, .LSL, 1, 0);
    try std.testing.expectEqual(@as(u32, 0x00000002), r.value);
    try std.testing.expectEqual(@as(u1, 1), r.carry);
}

test "LSL by 32" {
    const r = getShifted(0x00000001, .LSL, 32, 0);
    try std.testing.expectEqual(@as(u32, 0), r.value);
}

test "LSR by 1" {
    const r = getShifted(0x80000001, .LSR, 1, 0);
    try std.testing.expectEqual(@as(u32, 0x40000000), r.value);
    try std.testing.expectEqual(@as(u1, 1), r.carry);
}

test "LSR by 32" {
    const r = getShifted(0x80000000, .LSR, 32, 0);
    try std.testing.expectEqual(@as(u32, 0), r.value);
}

test "ASR by 1" {
    const r = getShifted(0x80000001, .ASR, 1, 0);
    try std.testing.expectEqual(@as(u32, 0xC0000000), r.value);
    try std.testing.expectEqual(@as(u1, 1), r.carry);
}

test "ASR by 32" {
    const r = getShifted(0x80000000, .ASR, 32, 0);
    try std.testing.expectEqual(@as(u32, 0xFFFFFFFF), r.value);
    try std.testing.expectEqual(@as(u1, 1), r.carry);
}

test "ASR by > 32" {
    const r1 = getShifted(0x80000000, .ASR, 33, 0);
    try std.testing.expectEqual(@as(u32, 0xFFFFFFFF), r1.value);
    try std.testing.expectEqual(@as(u1, 1), r1.carry);

    const r2 = getShifted(0x00000001, .ASR, 33, 0);
    try std.testing.expectEqual(@as(u32, 0x0), r2.value);
    try std.testing.expectEqual(@as(u1, 0), r2.carry);
}

test "RRX" {
    const r1 = getShifted(0x80000001, .RRX, 1, 0);
    try std.testing.expectEqual(@as(u32, 0x40000000), r1.value);
    try std.testing.expectEqual(@as(u1, 1), r1.carry);

    const r2 = getShifted(0x80000000, .RRX, 1, 1);
    try std.testing.expectEqual(@as(u32, 0xC0000000), r2.value);
    try std.testing.expectEqual(@as(u1, 0), r2.carry);
}

test "ROR by 1" {
    const r = getShifted(0x40000001, .ROR, 1, 0);
    try std.testing.expectEqual(@as(u32, 0xA0000000), r.value);
}

test "ROR by > 32" {
    const r = getShifted(0x40000001, .ROR, 33, 0);
    try std.testing.expectEqual(@as(u32, 0xA0000000), r.value);
}
