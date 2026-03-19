const types = @import("arm_types.zig");

pub fn getShifted(current: u32, shift_t: types.ShiftType, shift_n: u8) struct {
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
