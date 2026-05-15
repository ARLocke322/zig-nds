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
    blank: u21,

    pub fn execute(self: RSB, cpu: *Cpu) void {
        _ = self;
        _ = cpu;
    }
};

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
