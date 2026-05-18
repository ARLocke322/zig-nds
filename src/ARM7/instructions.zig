const std = @import("std");
const Cpu = @import("ARM7TDMI.zig").ARM7TDMI;
const helpers = @import("arm_helpers.zig");

pub const AND = packed struct(u21) {
    Rm: u4,
    register_shifted_register: bool,
    type_code: u2,
    imm5: u5,
    Rd: u4,
    Rn: u4,
    S: bool,

    pub fn execute(self: AND, cpu: *Cpu) void {
        const shift_result = helpers.getShiftResult(
            cpu,
            self.register_shifted_register,
            self.type_code,
            self.imm5,
            cpu.r[self.Rm].get(),
        );

        const result = cpu.r[self.Rn].get() & shift_result.value;
        cpu.r[self.Rd].set(result);

        if (self.S) {
            cpu.setFlags(.{
                .C = shift_result.carry == 1,
                .Z = result == 0,
            });
        }
    }
};

pub const EOR = packed struct(u21) {
    Rm: u4,
    register_shifted_register: bool,
    type_code: u2,
    imm5: u5,
    Rd: u4,
    Rn: u4,
    S: bool,

    pub fn execute(self: EOR, cpu: *Cpu) void {
        const shift_result = helpers.getShiftResult(
            cpu,
            self.register_shifted_register,
            self.type_code,
            self.imm5,
            cpu.r[self.Rm].get(),
        );

        const result = cpu.r[self.Rn].get() ^ shift_result.value;
        cpu.r[self.Rd].set(result);

        if (self.S) {
            cpu.setFlags(.{
                .C = shift_result.carry == 1,
                .Z = result == 0,
            });
        }
    }
};

pub const SUB = packed struct(u21) {
    Rm: u4,
    register_shifted_register: bool,
    type_code: u2,
    imm5: u5,
    Rd: u4,
    Rn: u4,
    S: bool,

    pub fn execute(self: SUB, cpu: *Cpu) void {
        const shift_result = helpers.getShiftResult(
            cpu,
            self.register_shifted_register,
            self.type_code,
            self.imm5,
            cpu.r[self.Rm].get(),
        );

        const rn = cpu.r[self.Rn].get();
        const op2 = shift_result.value;
        const result = rn -% op2;
        cpu.r[self.Rd].set(result);

        if (self.S) {
            cpu.setFlags(.{
                // operands have different signs, result has different sign to op1
                .V = (rn ^ op2) & (rn ^ result) >> 31 & 1 == 1,
                .C = rn >= op2,
                .Z = result == 0,
                .N = result >> 31 == 1,
            });
        }
    }
};

pub const RSB = packed struct(u21) {
    Rm: u4,
    register_shifted_register: bool,
    type_code: u2,
    imm5: u5,
    Rd: u4,
    Rn: u4,
    S: bool,

    pub fn execute(self: RSB, cpu: *Cpu) void {
        const shift_result = helpers.getShiftResult(
            cpu,
            self.register_shifted_register,
            self.type_code,
            self.imm5,
            cpu.r[self.Rm].get(),
        );

        const rn = cpu.r[self.Rn].get();
        const op1 = shift_result.value;
        const result = op1 -% rn;
        cpu.r[self.Rd].set(result);

        if (self.S) {
            cpu.setFlags(.{
                // operands have different signs, result has different sign to op1
                .V = (op1 ^ rn) & (op1 ^ result) >> 31 & 1 == 1,
                .C = op1 >= rn,
                .Z = result == 0,
                .N = result >> 31 == 1,
            });
        }
    }
};

pub const ADD = packed struct(u21) {
    Rm: u4,
    register_shifted_register: bool,
    type_code: u2,
    imm5: u5,
    Rd: u4,
    Rn: u4,
    S: bool,

    pub fn execute(self: ADD, cpu: *Cpu) void {
        const shift_result = helpers.getShiftResult(
            cpu,
            self.register_shifted_register,
            self.type_code,
            self.imm5,
            cpu.r[self.Rm].get(),
        );

        const rn = cpu.r[self.Rn].get();
        const op2 = shift_result.value;
        const result = @addWithOverflow(rn, op2);
        cpu.r[self.Rd].set(result[0]);

        if (self.S) {
            cpu.setFlags(.{
                // operands have same signs, result has different sign
                .V = ((rn ^ result[0]) & (op2 ^ result[0])) >> 31 == 1,
                .C = result[1] == 1,
                .Z = result[0] == 0,
                .N = result[0] >> 31 == 1,
            });
        }
    }
};

pub const ADC = packed struct(u21) {
    Rm: u4,
    register_shifted_register: bool,
    type_code: u2,
    imm5: u5,
    Rd: u4,
    Rn: u4,
    S: bool,

    pub fn execute(self: ADC, cpu: *Cpu) void {
        const shift_result = helpers.getShiftResult(
            cpu,
            self.register_shifted_register,
            self.type_code,
            self.imm5,
            cpu.r[self.Rm].get(),
        );

        const rn = cpu.r[self.Rn].get();
        const op2 = shift_result.value;
        const result1 = @addWithOverflow(rn, op2);
        const result2 = @addWithOverflow(result1[0], @intFromBool(cpu.CPSR.C));
        cpu.r[self.Rd].set(result2[0]);

        if (self.S) {
            cpu.setFlags(.{
                // operands have same signs, result has different sign
                .V = ((rn ^ result2[0]) & (op2 ^ result2[0])) >> 31 == 1,
                .C = result1[1] == 1 or result2[1] == 1,
                .Z = result2[0] == 0,
                .N = result2[0] >> 31 == 1,
            });
        }
    }
};
// === TESTS ===

// AND(S)
test "AND r1, r2, r3" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFF00FF00);
    cpu.r[3].set(0x0F0F0F0F);
    cpu.execute(0xE0021003);
    try std.testing.expectEqual(0x0F000F00, cpu.r[1].get());
}
test "ANDS sets Z flag on zero result" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFF00FF00);
    cpu.r[3].set(0x00FF00FF);
    cpu.execute(0xE0121003);
    try std.testing.expectEqual(0, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.Z);
}
test "ANDS sets C flag on shift carry" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFF00FF00);
    cpu.r[3].set(0xFF0F0F0F);
    cpu.execute(0xE0121183); // ANDS r1, r2, r3, LSL #3
    try std.testing.expectEqual(0xF8007800, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.C);
}

// EOR(S)
test "EOR r1, r2, r3" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFF00FF00);
    cpu.r[3].set(0x0F0F0F0F);
    cpu.execute(0xE0221003);
    try std.testing.expectEqual(0xF00FF00F, cpu.r[1].get());
}
test "EORS sets Z flag on zero result" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFFFFFFFF);
    cpu.r[3].set(0xFFFFFFFF);
    cpu.execute(0xE0321003);
    try std.testing.expectEqual(0, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.Z);
}
test "EORS sets C flag on shift carry" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFF00FF00);
    cpu.r[3].set(0xFF0F0F0F);
    cpu.execute(0xE0321183);
    try std.testing.expectEqual(0x07788778, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.C);
}

// SUB(S)
test "SUB r1, r2, r3" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFF00FF00);
    cpu.r[3].set(0xFF000000);
    cpu.execute(0xE0421003);
    try std.testing.expectEqual(0x0000FF00, cpu.r[1].get());
}
test "SUBS sets V flag on overflow" {
    var cpu = Cpu.init();
    cpu.r[2].set(0x80000000);
    cpu.r[3].set(0x00000001);
    cpu.execute(0xE0521003);
    try std.testing.expectEqual(0x7FFFFFFF, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.V);
}
test "SUBS sets C flag to 0 on borrow" {
    var cpu = Cpu.init();
    cpu.r[2].set(0x00000001);
    cpu.r[3].set(0x00000002);
    cpu.execute(0xE0521003);
    try std.testing.expectEqual(0xFFFFFFFF, cpu.r[1].get());
    try std.testing.expect(!cpu.CPSR.C);
}
test "SUBS sets Z flag on zero result" {
    var cpu = Cpu.init();
    cpu.r[2].set(0x00000001);
    cpu.r[3].set(0x00000001);
    cpu.execute(0xE0521003);
    try std.testing.expectEqual(0x00000000, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.Z);
}
test "SUBS sets N flag on negative result" {
    var cpu = Cpu.init();
    cpu.r[2].set(0x00000000);
    cpu.r[3].set(0x00000001);
    cpu.execute(0xE0521003);
    try std.testing.expectEqual(0xFFFFFFFF, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.N);
}

// RSB(S)
test "RSB r1, r2, r3" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFF000000);
    cpu.r[3].set(0xFF00FF00);
    cpu.execute(0xE0621003);
    try std.testing.expectEqual(0x0000FF00, cpu.r[1].get());
}
test "RSBS sets V flag on overflow" {
    var cpu = Cpu.init();
    cpu.r[2].set(0x00000001);
    cpu.r[3].set(0x80000000);
    cpu.execute(0xE0721003);
    try std.testing.expectEqual(0x7FFFFFFF, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.V);
}
test "RSBS sets C flag to 0 on borrow" {
    var cpu = Cpu.init();
    cpu.r[2].set(0x00000002);
    cpu.r[3].set(0x00000001);
    cpu.execute(0xE0721003);
    try std.testing.expectEqual(0xFFFFFFFF, cpu.r[1].get());
    try std.testing.expect(!cpu.CPSR.C);
}
test "RSBS sets Z flag on zero result" {
    var cpu = Cpu.init();
    cpu.r[2].set(0x00000001);
    cpu.r[3].set(0x00000001);
    cpu.execute(0xE0721003);
    try std.testing.expectEqual(0x00000000, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.Z);
}
test "RSBS sets N flag on negative result" {
    var cpu = Cpu.init();
    cpu.r[2].set(0x00000001);
    cpu.r[3].set(0x00000000);
    cpu.execute(0xE0721003);
    try std.testing.expectEqual(0xFFFFFFFF, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.N);
}

// ADD(S)
test "ADD r1, r2, r3" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFF000000);
    cpu.r[3].set(0x0000FF00);
    cpu.execute(0xE0821003);
    try std.testing.expectEqual(0xFF00FF00, cpu.r[1].get());
}
test "ADDS sets V flag on signed overflow" {
    var cpu = Cpu.init();
    cpu.r[2].set(0x00000001);
    cpu.r[3].set(0x7FFFFFFF);
    cpu.execute(0xE0921003);
    try std.testing.expectEqual(0x80000000, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.V);
}
test "ADDS sets C flag on unsigned overflow" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFFFFFFFF);
    cpu.r[3].set(0x00000001);
    cpu.execute(0xE0921003);
    try std.testing.expectEqual(0x0, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.C);
}
test "ADDS sets Z flag on zero result" {
    var cpu = Cpu.init();
    cpu.r[2].set(0x00000000);
    cpu.r[3].set(0x00000000);
    cpu.execute(0xE0921003);
    try std.testing.expectEqual(0x00000000, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.Z);
}
test "ADDS sets N flag on negative result" {
    var cpu = Cpu.init();
    cpu.r[2].set(0x00000001);
    cpu.r[3].set(0xFFFFFFFE);
    cpu.execute(0xE0921003);
    try std.testing.expectEqual(0xFFFFFFFF, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.N);
}

// ADC(S)
test "ADC r1, r2, r3 (no carry)" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFF000000);
    cpu.r[3].set(0x0000FF00);
    cpu.execute(0xE0A21003);
    try std.testing.expectEqual(0xFF00FF00, cpu.r[1].get());
}
test "ADC r1, r2, r3 (with carry)" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFF000000);
    cpu.r[3].set(0x0000FF00);
    cpu.CPSR.C = true;
    cpu.execute(0xE0A21003);
    try std.testing.expectEqual(0xFF00FF01, cpu.r[1].get());
}
test "ADCS sets V flag on signed overflow via carry" {
    var cpu = Cpu.init();
    cpu.r[2].set(0x7FFFFFFF);
    cpu.r[3].set(0x00000000);
    cpu.CPSR.C = true;
    cpu.execute(0xE0B21003);
    try std.testing.expectEqual(0x80000000, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.V);
}
test "ADCS sets C flag on unsigned overflow via carry" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFFFFFFFF);
    cpu.r[3].set(0x00000000);
    cpu.CPSR.C = true;
    cpu.execute(0xE0B21003);
    try std.testing.expectEqual(0x00000000, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.C);
}
test "ADCS sets Z flag on zero result" {
    var cpu = Cpu.init();
    cpu.r[2].set(0x00000000);
    cpu.r[3].set(0x00000000);
    cpu.execute(0xE0B21003);
    try std.testing.expectEqual(0x00000000, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.Z);
}
test "ADCS sets N flag on negative result" {
    var cpu = Cpu.init();
    cpu.r[2].set(0x00000001);
    cpu.r[3].set(0xFFFFFFFE);
    cpu.execute(0xE0B21003);
    try std.testing.expectEqual(0xFFFFFFFF, cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.N);
}
