//
//  AsynTcpSocketManager.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/8/18.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "AsynSocketManager.h"



@protocol TcpSocketCallBackDelegate <NSObject>

- (void)asyncTcpSocket:(GCDAsyncSocket *)sock didReadData:(NSData *)data;

- (void)asyncTcpSocket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength;

@end

@protocol TcpSocketConnectStatus <NSObject>

-(void)asyncTcpSocketConnectStatus:(SocketConnectStatus)status;

@end

@interface AsynTcpSocketManager : AsynSocketManager<GCDAsyncSocketDelegate>
//tcp socket
@property (nonatomic, strong)GCDAsyncSocket *socket;
//连接IP地址
@property (nonatomic, strong)NSString *connectHost;
//连接端口号
@property (nonatomic, assign)uint16_t connectPort;
//连接超时时间
@property (nonatomic, assign)NSTimeInterval connectTimeout;
//读超时时间
@property (nonatomic, assign)NSTimeInterval readTimeout;
//写超时时间
@property (nonatomic, assign)NSTimeInterval writeTimeout;
//写超时延迟时间
@property (nonatomic, assign)NSTimeInterval wTimeContinue;
//读超时延迟时间
@property (nonatomic, assign)NSTimeInterval rTimeContinue;
//回调代理
@property (nonatomic, weak)id<TcpSocketCallBackDelegate> delegate;
//连接状态回调
@property (nonatomic, weak)id<TcpSocketConnectStatus> socketConnectStatusDelegate;


//初始化 AsyncTcpSocketManager对象
+(instancetype)shareTcpSocketManager;

//连接
-(BOOL)connect;

//断开连接
-(void)disConnect;

/**
 连接
 
 @param host 连接ip
 @param port 连接端口
 @param timeout 超时时间
 @return success on Yes otherwise return No
 */
-(BOOL)connectToHost:(NSString *)host onPort:(uint64_t)port withTimeout:(NSTimeInterval)timeout connectStatusDelegate:(id)delagte;

/**
 发送

 @param msgData 发送的数据
 @param timeout 超时时间
 */
-(void)sendMsg:(NSData *)msgData withTimeout:(NSTimeInterval)timeout withCallBackDelegate:(id)delegate;

//手动关闭tcp socket连接
-(void)close;


@end
