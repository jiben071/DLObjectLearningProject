//
//  Utils.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/8/23.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "packethub_utils.h"

@implementation packethub_utils

+(NSData *)int2Bytes:(int)num {
    Byte byteNum[4];
    for (int ix = 0; ix < 4; ++ix) {
        int offset = 32 - (ix + 1) * 8;
        byteNum[ix] = (Byte) ((num >> offset) & 0xff);
    }
    return [NSData dataWithBytes:byteNum length:4];
}


+(int)bytes2Int:(Byte[])byteNum {
    int num = 0;
    for (int ix = 0; ix < 4; ++ix) {
        num <<= 8;
        num |= (byteNum[ix] & 0xff);
    }
    return num;
}

+(NSData *)long2Bytes:(long)num {
    Byte byteNum[8];
    for (int ix = 0; ix < 8; ++ix) {
        int offset = 64 - (ix + 1) * 8;
        byteNum[ix] = (Byte) ((num >> offset) & 0xff);
    }
    return [NSData dataWithBytes:byteNum length:8];
}

+(long)bytes2Long:(Byte[])byteNum {
    long num = 0;
    for (int ix = 0; ix < 8; ++ix) {
        num <<= 8;
        num |= (byteNum[ix] & 0xff);
    }
    return num;
}


+(NSString *)getUniqueId {
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    return [formatter stringFromDate:currentDate];
}



@end
