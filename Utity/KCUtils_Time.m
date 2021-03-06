//
//  KCUtils_Time.m
//  KX3
//
//  Created by peng zhi on 12-8-20.
//  Copyright (c) 2012年 kaixin001. All rights reserved.
//

#import "KCUtils_Time.h"

#import <sys/sysctl.h>
@interface KCUtils_Time()
+ (NSDate *)getCurrentDate;
@end
@implementation KCUtils_Time
static NSTimeInterval timeoffset = 0;

+ (void)setRealTime:(NSTimeInterval)time
{
    
    timeoffset = time - [[NSDate date]timeIntervalSince1970];
}
+ (NSDate *)getNSDataBySecondsFrom1970:(NSTimeInterval)secs
{
    return [self.class getNSDataBySecondsFrom1970:secs withGTM:0];
}
+ (NSDate *)getNSDataBySecondsFrom1970:(NSTimeInterval)secs withGTM:(int)GTM
{
    NSTimeInterval offsetOfGTMsecs = GTM * 60 * 60;
    NSDate * date = [NSDate dateWithTimeIntervalSince1970:secs + offsetOfGTMsecs];
    
    return date;
}

+ (NSTimeInterval)getCurrentTime
{
    //    @autoreleasepool {
    return [[[self class]getCurrentDate]timeIntervalSince1970] + timeoffset;
    //    }
    
}

+ (time_t)getSystemUptime
{
    struct timeval boottime;
    int mib[2] = {CTL_KERN,KERN_BOOTTIME};
    size_t size = sizeof(boottime);
    
    time_t now;
    time_t uptime = -1;
    
    (void)time(&now);
    
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0) {
        uptime = now - boottime.tv_sec;
    }
    return uptime;
}

//timeString:2012-02-22 02:02:19
+ (NSDate *)getDateByString:(NSString *)timeString
{
    if (timeString) { 
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];  
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        //        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        return [dateFormatter dateFromString:timeString];
    } else{
        return nil;
    }
}

+ (NSDate *)getCurrentDate
{
    return [NSDate date];
}

+ (NSTimeInterval)getTodayStartTime
{
    NSTimeInterval nowInterval = [KCUtils_Time getCurrentTime];
    NSTimeInterval todayStartInterval = nowInterval - (int)nowInterval % (3600 * 24);
    return todayStartInterval;
}


+ (NSMutableArray *)daysInCurrrentWeek
{
    NSMutableArray *days = [NSMutableArray array];
    
    NSDate *now = [NSDate dateWithTimeIntervalSince1970:[KCUtils_Time getCurrentTime]];
    NSCalendar *cal = [NSCalendar currentCalendar];
    
    NSDateComponents *components = [cal components:NSDayCalendarUnit fromDate:now];
    
    //<-找到weekday=2
    int chgDay = 0;
    NSDateComponents *checkCom = nil;
    while (YES) 
    {
        components.day = -chgDay;
        NSDate *pickDate = [cal dateByAddingComponents:components toDate:now options:0];
        checkCom = [cal components:NSWeekdayCalendarUnit fromDate:pickDate];
        [days addObject:pickDate];
        
        if (checkCom.weekday == 2) 
        {
            break;
        }
        chgDay ++;
    }
    
    if (days.count) 
    {
        
//        [days reverseArr];
        [days reverseObjectEnumerator]; // ??? cn
        
        [days removeObjectAtIndex:days.count-1];
    }
    
    //->找到weekday=1
    chgDay = 0;
    while (YES) 
    {
        components.day = chgDay;
        NSDate *pickDate = [cal dateByAddingComponents:components toDate:now options:0];
        checkCom = [cal components:NSWeekdayCalendarUnit fromDate:pickDate];
        [days addObject:pickDate];
        if (checkCom.weekday == 1) 
        {
            break;
        }
        chgDay ++;
    }
    
    return days;
}

+ (NSTimeInterval)getDayStartTimeByDate:(NSDate*)date
{
    NSTimeInterval nowInterval = [date timeIntervalSince1970];
    NSTimeInterval todayStartInterval = nowInterval - (int)nowInterval % (3600 * 24);
    return todayStartInterval;
}

+ (NSString *)getDateStringByFormat:(NSString *)theFormat
{
    NSDate *date = nil;
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    if ([@"ymd" isEqualToString:theFormat])
    {
        date = [NSDate dateWithTimeIntervalSince1970:[KCUtils_Time getTodayStartTime]];
        [formatter setDateFormat:@"yyyy-MM-dd"];
    }
    else if([@"ymdhis" isEqualToString:theFormat])
    {
        date = [NSDate dateWithTimeIntervalSince1970:[KCUtils_Time getCurrentTime]];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    
    NSString *dateStr = [formatter stringFromDate:date];
    return dateStr;
}


+ (NSString *)convert2ChatTime:(NSTimeInterval)secs
{
    //小于60分钟 显示XX分钟前
    //大于30分钟 小于今天 显示 XX小时前
    //昨天 前天以前 显示昨天 时分/前天时分
    //再往前显示 X月 X日 X 时 X 分
    //跨年 X年 X月 X日 X 时 X 分
    int oneDaySecs = 24 * 60 * 60;
    NSTimeInterval todaytime = [self.class getCurrentTime];
    //修正为东八区时间
    int todaytimeDiff = (int)todaytime  % (oneDaySecs) + 8 * 60 * 60;
    NSTimeInterval realtime = secs;
    
    int difftime = [self.class getCurrentTime] -  realtime;
    //真实聊天时间
    NSDate * chatDate = [self.class getNSDataBySecondsFrom1970:secs];
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    
    if (difftime < 0) {
        [formatter setDateFormat:@"yyyy年MM月dd日 HH时mm分"];
    }
    else if(difftime <= 60)
    {
        return [NSString stringWithFormat:@"刚刚"];
    }
    else if(difftime <= 60 * 60)
    {
        return [NSString stringWithFormat:@"%d分钟前",difftime / 60];
    }
    else if(difftime <= todaytimeDiff)
    {
        return [NSString stringWithFormat:@"%d小时前",difftime / 60 / 60];
    }
    else if(difftime <= todaytimeDiff + oneDaySecs)
    {
        [formatter setDateFormat:@"昨天 HH时mm分"];
    }
    else if(difftime <= todaytimeDiff + oneDaySecs * 2)
    {
        [formatter setDateFormat:@"前天 HH时mm分"];
    }
    else
    {
        [formatter setDateFormat:@"MM月dd日 HH时mm分"];
    }
    NSString *dateStr = [formatter stringFromDate:chatDate];
    return dateStr;
    
}

/**
 * 有些显示时间的地方比较窄，可使用该转换格式(如个人主人的来访)
 *
 * 时间显示规则：
 * 今天：只显示时间，如“9:02”“22:41”
 * 昨天、前天：“昨天 17:24”“前天 3:06”
 * 更早：不显示具体时间，只显示来访的日期：如：9月18日
 *
 */
+ (NSString *)convert2ShortTime:(NSTimeInterval)secs;
{
    int oneDaySecs = 24 * 60 * 60;
    NSTimeInterval todaytime = [self.class getCurrentTime];
    //修正为东八区时间
    int todaytimeDiff = (int)todaytime  % (oneDaySecs) + 8 * 60 * 60;
    NSTimeInterval realtime = secs;
    
    int difftime = [self.class getCurrentTime] -  realtime;
    
    NSDate * chatDate = [self.class getNSDataBySecondsFrom1970:secs];
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    
    if(difftime <= todaytimeDiff)
    {
        [formatter setDateFormat:@"HH:mm"];;
    }
    else if(difftime <= todaytimeDiff + oneDaySecs)
    {
        [formatter setDateFormat:@"昨天 HH:mm"];
    }
    else if(difftime <= todaytimeDiff + oneDaySecs * 2)
    {
        [formatter setDateFormat:@"前天 HH:mm"];
    }
    else
    {
        [formatter setDateFormat:@"MM月dd日"];
    }
    NSString *dateStr = [formatter stringFromDate:chatDate];
    return dateStr;
}

+ (NSString *)convert2MsgTime:(NSTimeInterval)secs
{
    int oneDaySecs = 24 * 60 * 60;
    NSTimeInterval todaytime = [self.class getCurrentTime];
    //修正为东八区时间
    int todaytimeDiff = (int)todaytime  % (oneDaySecs) + 8 * 60 * 60;
    NSTimeInterval realtime = secs;
    
    int difftime = [self.class getCurrentTime] -  realtime;
    
    NSDate * chatDate = [self.class getNSDataBySecondsFrom1970:secs];
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    
    if (difftime < 0) {
        [formatter setDateFormat:@"yyyy年MM月dd日 HH时mm分"];
    }
    else if(difftime <= 60)
    {
        return [NSString stringWithFormat:@"刚刚"];
    }
    else if(difftime <= 60 * 60)
    {
        return [NSString stringWithFormat:@"%d分钟前",difftime / 60];
    }
    else if(difftime <= todaytimeDiff)
    {
        return [NSString stringWithFormat:@"%d小时前",difftime / 60 / 60];
    }
    else
    {
        [formatter setDateFormat:@"MM月dd日"];
    }

    NSString *dateStr = [formatter stringFromDate:chatDate];
    return dateStr;
}

+ (NSString *)convert2VisitorTime:(NSTimeInterval)secs
{
    //小于60分钟 显示XX分钟前
    //大于30分钟 小于今天 显示 XX小时前
    //昨天 前天以前 显示昨天 时分/前天时分
    //再往前显示 X月 X日 X 时 X 分
    //跨年 X年 X月 X日 X 时 X 分
    int oneDaySecs = 24 * 60 * 60;
    NSTimeInterval todaytime = [self.class getCurrentTime];
    //修正为东八区时间
    int todaytimeDiff = (int)todaytime  % (oneDaySecs) + 8 * 60 * 60;
    NSTimeInterval realtime = secs;
    
    int difftime = [self.class getCurrentTime] -  realtime;
    //真实聊天时间
    NSDate * chatDate = [self.class getNSDataBySecondsFrom1970:secs];
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    
    // 年份判断
    NSUInteger unitFlags =
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit;
    NSDateComponents *nowDateComponents = [[NSCalendar currentCalendar] components:unitFlags fromDate:[self.class getCurrentDate]];
    NSDateComponents *chartDateComponents = [[NSCalendar currentCalendar] components:unitFlags fromDate:chatDate];
    
    if (difftime < 0 || nowDateComponents.year != chartDateComponents.year) {
        [formatter setDateFormat:@"yyyy-MM-dd"];
    }
    else if(difftime <= 60)
    {
        return [NSString stringWithFormat:@"刚刚"];
    }
    else if(difftime <= 60 * 60)
    {
        return [NSString stringWithFormat:@"%d分钟前",difftime / 60];
    }
    else if(difftime <= todaytimeDiff)
    {
        [formatter setDateFormat:@"今天HH:mm"];
    }
    else if(difftime <= todaytimeDiff + oneDaySecs)
    {
        [formatter setDateFormat:@"昨天HH:mm"];
    }
    else if(difftime <= todaytimeDiff + oneDaySecs * 2)
    {
        [formatter setDateFormat:@"前天HH:mm"];
    }
    else
    {
        [formatter setDateFormat:@"MM-dd"];
    }
    NSString *dateStr = [formatter stringFromDate:chatDate];
    return dateStr;
}

@end
