pub const Register = @This();
value: u32,

pub fn init(value: u32) Register {
    return .{ .value = value };
}
pub fn get(self: Register) u32 {
    return self.value;
}

pub fn set(self: *Register, value: u32) void {
    self.value = value;
}

pub fn setBit(self: *Register, bit_n: u5, val: u1) void {
    self.value |= (@as(u32, val) << bit_n);
}
