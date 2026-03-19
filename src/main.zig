const std = @import("std");
const Io = std.Io;

const zig_ds = @import("zig_ds");
const Cpu = @import("ARM7/ARM7TDMI.zig").ARM7TDMI;
const Console = @import("nds.zig").Nds;

pub fn main() !void {
    var cpu: Cpu = .init();
    var console: Console = .init(&cpu);
    cpu.r[2].set(0xFF00FF00);
    cpu.r[3].set(0x0F0F0F0F);
    cpu.r[4].set(4); // shift r3 left by 4
    console.stepPipeline();
}

test {
    _ = @import("ARM7/arm_decoder.zig");
    _ = @import("ARM7/arm_helpers.zig");
    _ = @import("ARM7/instructions.zig");
    _ = @import("ARM7/ARM7TDMI.zig");
    _ = @import("ARM7/register.zig");
}
