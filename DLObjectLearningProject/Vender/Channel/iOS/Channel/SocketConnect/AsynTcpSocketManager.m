//
//  AsynTcpSocketManager.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/8/18.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "AsynTcpSocketManager.h"

static NSString *const AsyncSocketDelegateQueue = @"com.asyncTcpSocket.DelegateQueue";

static long const defaultTag = 0;

@interface AsynTcpSocketManager()

@property (nonatomic, strong) dispatch_queue_t delegaeQueue;

@end

@implementation AsynTcpSocketManager
@synthesize connectTimeout = _connectTimeout;
@synthesize readTimeout = _readTimeout;
@synthesize writeTimeout = _writeTimeout;


+(instancetype)shareTcpSocketManager {
    static AsynTcpSocketManager *shareTcpManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareTcpManager = [[AsynTcpSocketManager alloc] init];
    });
    return shareTcpManager;
}

-(id)init {
    self = [super init];
    if(self) {
        [self resetParma];
    }
    return self;
}


-(void)setConnectTimeout:(NSTimeInterval)connectTimeout {
    if(connectTimeout == 0) {
        _connectTimeout = -1;
    }else {
        _connectTimeout = connectTimeout;
    }
}

-(void)setReadTimeout:(NSTimeInterval)readTimeout {
    if(readTimeout == 0) {
        _readTimeout = -1;
    }else {
        _readTimeout = readTimeout;
    }
}

-(void)setWriteTimeout:(NSTimeInterval)writeTimeout {
    if(writeTimeout == 0) {
        _writeTimeout = -1;
    }else {
        _writeTimeout = writeTimeout;
    }
}


-(void)initSocket {
    if(!self.socket) {
        if(!self.delegaeQueue) {
            self.delegaeQueue = dispatch_queue_create([AsyncSocketDelegateQueue UTF8String], NULL);
        }
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.delegaeQueue];
    }
}

-(void)disConnect {
    if([self.socket isConnected]) {
        [self.socket disconnect];
    }
}

-(BOOL)connect {
    if(!self.socket) {
        return NO;
    };
    if(self.connectHost && self.connectPort) {
        if(self.socketConnectStatusDelegate && [self.socketConnectStatusDelegate respondsToSelector:@selector(asyncTcpSocketConnectStatus:)]) {
            [self.socketConnectStatusDelegate asyncTcpSocketConnectStatus:Connecting];
        }
        return [self.socket connectToHost:self.connectHost onPort:self.connectPort withTimeout:self.connectTimeout error:nil];
    }else return NO;
}




-(BOOL)connectToHost:(NSString *)host onPort:(uint64_t)port withTimeout:(NSTimeInterval)timeout connectStatusDelegate:(id)delagte{
    [self close];
    [self initSocket];
    self.socketConnectStatusDelegate = delagte;
    self.connectHost = [host copy];
    self.connectPort = port;
    self.connectTimeout = timeout;
    return [self connect];
}

-(void)sendMsg:(NSData *)msgData withTimeout:(NSTimeInterval)timeout withCallBackDelegate:(id)delegate {
    self.writeTimeout = timeout;
    self.delegate = delegate;
    if([self.socket isConnected]) {
        [self.socket writeData:msgData withTimeout:self.writeTimeout tag:defaultTag];
    }
}


-(void)resetParma {
    self.connectPort = 0;
    self.connectHost = nil;
    self.connectTimeout = -1;
    self.readTimeout = -1;
    self.writeTimeout = -1;
    self.wTimeContinue = 0;
    self.rTimeContinue = 0;
    
}


-(void)close {
    self.socket.delegate = nil;
    [self.socket disconnect];
    self.socket = nil;
    self.delegaeQueue = nil;
    
    [self resetParma];
}


-(void)pullTheMsg {
    [self.socket readDataWithTimeout:self.readTimeout tag:defaultTag];
}


#pragma mark --GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    
}


- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
      [self pullTheMsg];
    if(self.socketConnectStatusDelegate && [self.socketConnectStatusDelegate respondsToSelector:@selector(asyncTcpSocketConnectStatus:)]) {
        [self.socketConnectStatusDelegate asyncTcpSocketConnectStatus:Connected];
    }
    NSLog(@"Tcp did Connect to host");
}


- (void)socket:(GCDAsyncSocket *)sock didConnectToUrl:(NSURL *)url {
     [self pullTheMsg];
    if(self.socketConnectStatusDelegate && [self.socketConnectStatusDelegate respondsToSelector:@selector(asyncTcpSocketConnectStatus:)]) {
        [self.socketConnectStatusDelegate asyncTcpSocketConnectStatus:Connected];
    }
    NSLog(@"Tcp did Connect to url");
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
     [self pullTheMsg];
    NSLog(@"=====tcp read data: %@", data);
    if(self.delegate && [self.delegate respondsToSelector:@selector(asyncTcpSocket:didReadData:)]) {
        [self.delegate asyncTcpSocket:sock didReadData:data];
    }
}


- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    if(self.delegate && [self.delegate respondsToSelector:@selector(asyncTcpSocket:didReadPartialDataOfLength:)]) {
        [self.delegate asyncTcpSocket:sock didReadPartialDataOfLength:partialLength];
    }
}


- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"tcp socket send data");
}

- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {

}


- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length {
    return self.rTimeContinue;
}


- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length {
    
    return self.wTimeContinue;
}


- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {

}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err {
    if(self.socketConnectStatusDelegate && [self.socketConnectStatusDelegate respondsToSelector:@selector(asyncTcpSocketConnectStatus:)]) {
        [self.socketConnectStatusDelegate asyncTcpSocketConnectStatus:Disconnect];
    }
    NSLog(@"Tcp socket disconnect");
}


- (void)socketDidSecure:(GCDAsyncSocket *)sock {
    
}




@end
