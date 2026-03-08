const std = @import("std");

// entry
pub fn main() !void {
    // stdout
    var stdout_buf: [4096]u8 = undefined; // setup a buffer
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;

    // let's inspect types
    const myint: u8 = 37;
    try stdout.print("myint: {any}\n", .{myint});
    try stdout.flush();
}
