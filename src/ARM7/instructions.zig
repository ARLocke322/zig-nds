const std = @import("std");
const Cpu = @import("ARM7TDMI.zig").ARM7TDMI;
const decoder = @import("arm_decoder.zig");
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
        const shift_result = blk: {
            if (self.register_shifted_register) {
                const shift_params = decoder.decodeRegShift(self.type_code);
                const Rs: u4 = @truncate(self.imm5 >> 1);
                break :blk helpers.getShifted(
                    cpu.r[self.Rm].get(),
                    shift_params.shift_t,
                    @truncate(cpu.r[Rs].get()),
                    @bitCast(cpu.CPSR.C),
                );
            } else {
                const shift_params = decoder.decodeImmShift(self.type_code, self.imm5);
                break :blk helpers.getShifted(
                    cpu.r[self.Rm].get(),
                    shift_params.shift_t,
                    shift_params.shift_n,
                    @bitCast(cpu.CPSR.C),
                );
            }
        };

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

test "AND r1, r2, r3" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFF00FF00);
    cpu.r[3].set(0x0F0F0F0F);
    cpu.execute(0xE0021003);
    try std.testing.expectEqual(@as(u32, 0x0F000F00), cpu.r[1].get());
}

test "ANDS sets Z flag on zero result" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFF00FF00);
    cpu.r[3].set(0x00FF00FF);
    cpu.execute(0xE0121003);
    try std.testing.expectEqual(@as(u32, 0), cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.Z);
}

test "ANDS sets C flag on shift carry" {
    var cpu = Cpu.init();
    cpu.r[2].set(0xFF00FF00);
    cpu.r[3].set(0xFF0F0F0F);
    cpu.execute(0xE0121183); // ANDS r1, r2, r3, LSL #3
    try std.testing.expectEqual(@as(u32, 0xF8007800), cpu.r[1].get());
    try std.testing.expect(cpu.CPSR.C);
}
