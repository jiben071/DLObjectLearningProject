//
//  Utils.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/8/23.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface packethub_utils : NSObject

//大端模式 int转Byte 再转为NSData返回
+(NSData *)int2Bytes:(int)num;

//Bytes转int
+(int)bytes2Int:(Byte[])byteNum;

+(NSData *)long2Bytes:(long)num;

+(long)bytes2Long:(Byte[])byteNum;

//获取唯一标识符
+(NSString *)getUniqueId;

@end
