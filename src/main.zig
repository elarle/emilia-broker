const std = @import("std");
const cfg = @import("files.zig");
const DefaultConfig = cfg.DefaultConfig;
const loadJSON = cfg.loadJSON;
const httpz = @import("httpz");
const sql = @import("zqlite");

const routes = @import("api.zig");

const log = std.log;

pub fn main() !void {

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
   
    // === Config Loading === //

    const config_p = loadJSON("config.json", cfg.Config, allocator);
    var config = DefaultConfig;

    var Global = routes.Global{
        .allocator = allocator,
        .db = undefined
    };

    if(config_p) |config_d| {
        config = config_d.value;
        log.info("Loaded config", .{});
    }

    // === Init database === //
    Global.db = sql.open(config.database_file.?, sql.OpenFlags.Create | sql.OpenFlags.EXResCode) catch {
        log.err("Couldn't open database", .{});
        return;
    };

    try Global.db.exec("CREATE TABLE IF NOT EXISTS data (timestamp INTEGER PRIMARY KEY, data_type INTEGER NOT NULL, value REAL NOT NULL) WITHOUT ROWID;", .{});

    defer Global.db.close();

    // === Server Config === //
    
    var server = httpz.ServerApp(*routes.Global).init(allocator, .{
        .port = config.port.?,
        .address = config.address.?
    }, &Global) catch {
        log.err("Error during server initialization", .{});
        return;
    };

    defer {
        server.stop();
        server.deinit();
    }

    var router = server.router();
    router.get("/broker/api/v1/hello", routes.hello);
    router.post("/broker/api/v1/log/:kind/:value", routes.log_data);
    
    router.get("/broker/api/v1/data", routes.get_data);
    router.get("/broker/api/v1/data/:start_time", routes.get_data);
    router.get("/broker/api/v1/data/:start_time/:end_time", routes.get_data);

    // === Server Starting === //

    log.info("Listening requests ( {s}:{d} )", .{config.address.?, config.port.?});
    try server.listen();

}


