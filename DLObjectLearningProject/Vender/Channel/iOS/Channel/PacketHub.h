//
//  PacketHub.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/4.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SubScriber.h"
#import "Contract.pbobjc.h"
#import "Packet.pbobjc.h"
#import "Params.pbobjc.h"

extern NSString * _Nullable const AsyncSocketStatusChangeNotification;

@interface PacketHub : NSObject

+(instancetype)sharePacketHub;

//获取本地ip地址
-(NSString *)getLocalIpAddress;

//广播
-(BOOL)deviceDetectionSuccess:(void (^)(id responseObj))success failure:(void (^)(NSError *error))failure;


//连接
-(BOOL)connectToHost:(NSString *)host onPort:(uint16_t)port withTimeout:(NSTimeInterval)timeout;

//重连
-(BOOL)reConnect;

//关闭
-(void)shotDown;


//发布
-(void)pubilsh:(NSString *)action;

-(void)pubilsh:(NSString *)action subAction:(NSString *)subAction;

-(void)publish:(NSString *)action param:(id)param;

-(void)pubilsh:(NSString *)action subAction:(NSString *)subAction param:(id)param;


//订阅
-(void)subScribe:(SubScriber *)subScriber actions:(NSArray *)actions;

-(void)subScribe:(SubScriber *)subScriber action:(NSString *)action;

//取消订阅
-(void)unSubscribe:(SubScriber *)subScriber;

//get请求
-(void)getUri:(NSString *)uri success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure;

-(Response *)getUri:(NSString *)uri;

-(void)getUri:(NSString *)uri param:(id)param success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure;

-(Response *)getUri:(NSString *)uri param:(id)param;

//post请求
-(void)postUri:(NSString *)uri success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure;

-(Response *)postUri:(NSString *)uri;

-(void)postUri:(NSString *)uri param:(id)param success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure;

-(Response *)postUri:(NSString *)uri param:(id)param;

//put请求
-(void)putUri:(NSString *)uri success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure;

-(Response *)putUri:(NSString *)uri;

-(void)putUri:(NSString *)uri param:(id)param success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure;

-(Response *)putUri:(NSString *)uri param:(id)param;

//patch请求
-(void)patchUri:(NSString *)uri success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure;

-(Response *)patchUri:(NSString *)uri;

-(void)patchUri:(NSString *)uri param:(id)param success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure;

-(Response *)patchUri:(NSString *)uri param:(id)param;

//delete请求
-(void)deleteUri:(NSString *)uri success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure;

-(Response *)deleteUri:(NSString *)uri;

-(void)deleteUri:(NSString *)uri param:(id)param success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure;

-(Response *)deleteUri:(NSString *)uri param:(id)param;



@end
