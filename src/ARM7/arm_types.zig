const instructions = @import("instructions.zig");

pub const ShiftType = enum { LSL, LSR, ASR, RRX, ROR };

pub const Instruction = union(enum) {
    AND: instructions.AND,
};
