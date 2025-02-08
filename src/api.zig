const std = @import("std");
const httpz = @import("httpz");
const sql = @import("zqlite");

const log = std.log;

const io = @import("files.zig");
const Date = @import("time.zig").Date;

pub const Global = struct{
    allocator: std.mem.Allocator,
    db: sql.Conn
};
pub const Context = struct {
    global: *Global,
};

pub const ResponseTemplate = struct{
    status: u16,
    msg: []const u8
};

pub const StoreTemplate = struct{
    timestamp: i64,
    data_type: i64,
    value: f64
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

   const start_time_param = req.param("start_time");
   const end_time_param = req.param("end_time");

   if(start_time_param) |start_time_str| {
      const start_time = std.fmt.parseInt(i64, start_time_str, 10) catch {
         setResponse(Invalid, res);
         return; 
      };

      var end_time = std.time.milliTimestamp();

      if(end_time_param) |end_time_str| {
         end_time = std.fmt.parseInt(i64, end_time_str, 10) catch {
            setResponse(Invalid, res);
            return;
         };
      }

      var rows = ctx.db.rows("SELECT * FROM data WHERE timestamp >= ?1 AND timestamp <= ?2", .{start_time, end_time}) catch {
         setResponse(Invalid, res);
         return; 
      };
    
      var js_writter = std.json.writeStream(res.writer(), .{.whitespace = .indent_3});
      try js_writter.beginObject();
      try js_writter.objectField("data");
      try js_writter.beginArray();
        
      while (rows.next()) |row| {
         try js_writter.write(StoreTemplate{
             .timestamp = row.int(0),
             .data_type = row.int(1),
             .value = row.float(2),
         });
      }

      try js_writter.endArray();
      try js_writter.endObject();

      defer rows.deinit();

      return;
   }

   setResponse(Invalid, res);
   
}

pub fn log_data(ctx: *Global, req: *httpz.Request, res: *httpz.Response) !void{

    const timestamp = std.time.milliTimestamp();

    const data_type = req.param("kind").?;
    const data_value = req.param("value").?;

    const sub_u8 = std.fmt.parseInt(u8, data_type, 10) catch {
        setResponse(Invalid, res);
        return;
    };

    const value = std.fmt.parseFloat(f64, data_value) catch {
        setResponse(Invalid, res);
        return;
    };

    //Check if valid value
    _ = std.meta.intToEnum(Subject, sub_u8) catch {
        setResponse(Invalid, res);
        return;
    };

    try ctx.db.exec("INSERT INTO data (timestamp, data_type, value) VALUES (?1, ?2, ?3)", .{timestamp, sub_u8, value}); 

    setResponse(Authorized, res); 

}

