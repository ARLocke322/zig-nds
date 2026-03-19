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
                );
            } else {
                const shift_params = decoder.decodeImmShift(self.type_code, self.imm5);
                break :blk helpers.getShifted(
                    cpu.r[self.Rm].get(),
                    shift_params.shift_t,
                    shift_params.shift_n,
                );
            }
        };

        const result = cpu.r[self.Rn].get() & shift_result.value;
        cpu.r[self.Rd].set(result);

        if (self.S) {
            cpu.setFlags(.{
                .C = if (shift_result.carry) |c| c == 1 else null,
                .Z = result == 0,
            });
        }
    }
};
