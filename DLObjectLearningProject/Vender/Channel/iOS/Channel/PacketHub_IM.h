//
//  PacketHub_IM.h
//  AlphaMini
//
//  Created by denglong on 13/11/2017.
//  Copyright © 2017 denglong. All rights reserved.
//  使用IM方式发送请求数据

#import <Foundation/Foundation.h>
#import "SubScriber.h"
#import "Contract.pbobjc.h"
#import "Packet.pbobjc.h"
#import "Params.pbobjc.h"

@interface PacketHub_IM : NSObject
+(instancetype)sharePacketHub;

/**< 发送请求，已改造成使用IM方式 */
#pragma mark -- 核心发送数据方法
-(void)getUri:(NSString *)uri
        param:(id)param
    commandID:(NSInteger)commandID
 commandParamData:(NSData *)commandParamData
      success:(void (^)(id responseObj))success
      failure:(void (^)(NSError *error))failure;
@end
