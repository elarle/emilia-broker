const std = @import("std");
const log = std.log;


const Months= [12]u8{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 ,31};

pub const Date = struct {

    time_stamp: i64 = 0,

    current_day: i64 = 1,
    //ZERO BASED
    current_month: u8 = 0,
    current_year: i64 = 1970,

    current_hour: i64 = 0,
    current_minute: i64 = 0,
    current_second: i64 = 0,
  
    pub fn update(self: *Date) void{

        self.current_day = 1;
        //ZERO BASED
        self.current_month = 0;
        self.current_year = 1970;

        self.current_hour = 0;
        self.current_minute = 0;
        self.current_second = 0;
        
        const seconds = @divTrunc(@rem(self.time_stamp,86400), 1) + 3600; //Europe/Madrid
 
        self.current_hour = @divTrunc(seconds,3600);
        self.current_minute = @divTrunc(seconds-(self.current_hour*3600),60);
        self.current_second = seconds-(self.current_hour*3600) - (self.current_minute*60);

        self.current_day = @divTrunc(self.time_stamp,86400)+1; 
        var keep_counting = true;

        //Date calc
        while(keep_counting){

            if(self.current_day <= Months[self.current_month]){
                keep_counting = false;
                continue;
            }

            self.current_day -= Months[self.current_month];

            //checkea febrero
            if(self.current_month == 1 and @rem(self.current_year, 4) == 0){
                self.current_day-=1;
                if(@rem(self.current_year,100) == 0 and @rem(self.current_year,400) != 0){
                    //Los lustros solo los divisibles por 400
                    self.current_day += 1;
                }
            }

            //current_month_index = (current_month_index + 1) % 12;
            self.current_month+=1;
            if(self.current_month >= 12){
                self.current_year += 1;
                self.current_month = 0;
            }
            
        }

        //Are zero based here
        self.current_month += 1;
    }

    //Europe/Madrid only
    pub fn dateFromTimestamp(timestamp: i64) Date{
        var self = Date{.time_stamp = timestamp};
        self.update();
        return self;
    }
};

pub fn printDate(date: Date)void{
    log.info("{d}-{d}-{d} {d}:{d}:{d}", .{
        date.current_year, date.current_month, date.current_day,
        date.current_hour, date.current_minute, date.current_second
    });
}

test "Make sure date works"{
    const expect = std.testing.expect;

    const date = Date.dateFromTimestamp(1738540800);
    
    try expect(date.current_day == 3);   
    try expect(date.current_month == 2);
    try expect(date.current_year == 2025);   

    try expect(date.current_hour == 1);   
    try expect(date.current_minute == 0);
    try expect(date.current_second == 0);

    const date2 = Date.dateFromTimestamp(0);
    
    try expect(date2.current_day == 1);   
    try expect(date2.current_month == 1);
    try expect(date2.current_year == 1970);   

    try expect(date2.current_hour == 1);   
    try expect(date2.current_minute == 0);
    try expect(date2.current_second == 0);
}
