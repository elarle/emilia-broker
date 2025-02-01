const std = @import("std");

pub const Config = struct {
    port: ?u16 = null,
    address: ?[]const u8 = null
};

pub const DefaultConfig = Config{
    .port = @as(u16, @intCast(2025)),
    .address = "127.0.0.1"
};

pub fn createWriteFile(file_name: []const u8, data: []u8) !void{
    const file = try std.fs.cwd().createFile(file_name, .{});
    defer file.close();

    try file.writeAll(data);
}

pub fn loadFile(file_name: []const u8, allocator: std.mem.Allocator) ?[]u8{
    
    const file = std.fs.cwd().openFile(file_name, .{}) catch {
        return null;
    };
    
    //Max reading size: 128MB
    const content = file.reader().readAllAlloc(allocator, 128 * 1000 * 1000) catch {
        return null;
    };

    return content;
    
}

pub fn loadJSON(file_name: []const u8, T: anytype, allocator: std.mem.Allocator) ?std.json.Parsed(T) {
    //Max reading size: 128MB
    const content = loadFile(file_name, allocator);
    if(content == null){
        return null;
    }

    defer allocator.free(content.?);

    return std.json.parseFromSlice(T, allocator, content.?, .{}) catch {
        return null;
    };

}

