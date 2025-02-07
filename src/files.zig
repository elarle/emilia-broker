const std = @import("std");
const log = std.log;

pub const Config = struct {
    port: ?u16 = null,
    address: ?[]const u8 = null,
    database_file: ?[:0]const u8 = null
};

pub const DefaultConfig = Config{
    .port = @as(u16, @intCast(2025)),
    .address = "127.0.0.1",
    .database_file = "data.db"
};

pub fn createWriteFile(file_name: []const u8, data: []u8) !void{
    const file = try std.fs.cwd().createFile(file_name, .{});
    defer file.close();

    try file.writeAll(data);
}

pub fn loadFile(file_name: []const u8, allocator: std.mem.Allocator) ?[]u8{
    
    const file = std.fs.cwd().openFile(file_name, .{}) catch {
        log.warn("Error opening file: {s}", .{file_name});
        return null;
    };
    
    //Max reading size: 128MB
    const content = file.reader().readAllAlloc(allocator, 128 * 1000 * 1000) catch {
        log.warn("Error reading file", .{});
        return null;
    };

    file.close();

    return content;
    
}

pub fn loadJSON(file_name: []const u8, T: anytype, allocator: std.mem.Allocator) ?std.json.Parsed(T) {
    //Max reading size: 128MB
    const content = loadFile(file_name, allocator);
    if(content == null){
        return null;
    }

    //defer allocator.free(content.?);

    return std.json.parseFromSlice(T, allocator, content.?, .{}) catch {
        return null;
    };

}

// This is a very specific implementation, should not be used without knowing that it does exactly.
pub fn mergeFilesFromFolderAllocatedToFile(folder_path: []const u8, output_file: []const u8, allocator: std.mem.Allocator) !void{
    
    const folder = try std.fs.cwd().openDir(folder_path, .{.iterate=true});
    var it = folder.iterate();

    var file_count: usize = 0;
    var file_index: usize = 0;

    const out_file = try std.fs.cwd().createFile(output_file, .{});
    defer out_file.close();

    try out_file.writeAll("{\"data\":{\n");

    //IDK HOW ELSE TO COUNT FILES
    while(try it.next()) |_|{
        file_count+=1;
    }

    it.reset();

    while(try it.next()) |file|{
        const file_name = file.name;
        log.err("Found: {s}", .{file_name});

        var name_it = std.mem.split(u8, file_name, ".");
        
        const reading_file = try folder.openFile(file_name, .{});

        const content = try reading_file.reader().readAllAlloc(allocator, 128 * 1000 * 1000);
       
        //Dirty but works
        try out_file.writeAll("\"");
        try out_file.writeAll(name_it.first());
        try out_file.writeAll("\":");
        try out_file.writeAll(content);
        if(file_index < file_count-1){
            try out_file.writeAll(",");
        }
        try out_file.writeAll("\n");

        allocator.free(content);
        reading_file.close();

        file_index += 1;
    }

    try out_file.writeAll("}}\n");

    return;
}

test "Testing filesmerging" {
    _ = try mergeFilesFromFolderAllocatedToFile("data/current", "output.json", std.testing.allocator);
}
