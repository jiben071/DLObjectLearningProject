//
//  AsyncUdpSocketManager.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/8/18.
//  Copyright © 2017年 UBTECH. All rights reserved.
//



#import "AsynSocketManager.h"

typedef void(^UdpSocketBroadCastResponse)(NSData *receiveData);

@interface AsyncUdpSocketManager : AsynSocketManager<GCDAsyncUdpSocketDelegate>

//广播反馈block
@property (nonatomic, copy) UdpSocketBroadCastResponse broadCastResponseBlock;
//GCDAsyncUdpSocket对象
@property (nonatomic, strong) GCDAsyncUdpSocket *socket;
//连接的ip
@property (nonatomic, strong) NSString *connectHost;
//连接的port
@property (nonatomic, assign) uint16_t connectPort;



//初始化 AsyncUdpSocketManager对象
+(instancetype)shareUdpSocketManager;



/**
 广播
 @param data 广播的数据包
 @param host 广播的子网地址
 @param port 广播的port
 @param timeOut 广播超时时间
 @param responseBlock 广播得到的反馈
 @return success on yes, otherwise on no
 */
-(BOOL)broadcastData:(NSData *)data
              toHost:(NSString *)host
                port:(uint16_t)port
             timeOut:(NSTimeInterval)timeOut
       responseBlock:(UdpSocketBroadCastResponse)responseBlock;


@end
