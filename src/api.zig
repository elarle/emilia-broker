const std = @import("std");
const httpz = @import("httpz");

const log = std.log;

const io = @import("files.zig");

pub const Global = struct{
    allocator: std.mem.Allocator
};
pub const Context = struct {
    global: *Global,
};

pub const ResponseTemplate = struct{
    status: u16,
    msg: []const u8
};

const Ok: ResponseTemplate = .{.status = 200, .msg = "OK"};
const Invalid: ResponseTemplate = .{.status = 400, .msg = "Invalid Request"};
const Unauthorized: ResponseTemplate = .{.status = 401, .msg = "Unauthorized"};
const Authorized: ResponseTemplate = .{.status = 201, .msg = "Auhtorized"};
const NotImplemented: ResponseTemplate = .{.status = 501, .msg = "Not Implemented :("};

pub fn setResponse(res_t: ResponseTemplate, res: *httpz.Response) void{
    res.status = res_t.status;
    res.body = res_t.msg; 
}

pub fn hello(_: *Global, _: *httpz.Request, res: *httpz.Response) !void{
    res.status = 200;
    res.body = "Hola!";
}

pub const Subject = enum (u8){
    temperature = 0,
    pressure = 1,
    humidity = 2,
    wind = 3,
    rain = 4,
};

pub fn get_data(ctx: *Global, req: *httpz.Request, res: *httpz.Response) !void{
   _ = ctx;
   _ = req;
    setResponse(NotImplemented, res);
}

pub fn log_data(ctx: *Global, req: *httpz.Request, res: *httpz.Response) !void{

    const timestamp = std.time.milliTimestamp();

    const data_type = req.param("kind").?;
    const data_value = req.param("value").?;

    const sub_u8 = std.fmt.parseInt(u8, data_type, 10) catch {
        setResponse(Invalid, res);
        return;
    };

    const value = std.fmt.parseFloat(f128, data_value) catch {
        setResponse(Invalid, res);
        return;
    };

    const sub = std.meta.intToEnum(Subject, sub_u8) catch {
        setResponse(Invalid, res);
        return;
    };

    log.info("REGISTERED ({d}) {s}: {d}", .{timestamp, @tagName(sub), value});
    //try because not storing data means fatal
    const o_filename = try std.fmt.allocPrint(
        ctx.allocator, 
        "data/current/{d}.json", 
        .{timestamp}
    );

    //It may look ugly but works (error when printing { due to format)
    const output_data = try std.fmt.allocPrint(
        ctx.allocator,
        "{c}\"type\": \"{s}\", \"value\": {d}{c}",
        .{'{', @tagName(sub), value, '}'}
    );

    try io.createWriteFile(o_filename, output_data); 

    log.debug("INPUT: {s}, VAL: {s}", .{data_type, data_value});

    setResponse(Authorized, res); 

}

