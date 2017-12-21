//
//  AsyncUdpSocketManager.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/8/18.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "AsyncUdpSocketManager.h"

NSString *const AsyncUdpSocketDelegateQueue = @"com.AsyncUdpSocket.DelegateQueue";

static UInt16 const localPort = 6000;

static long const defaultTag = 1;

@interface AsyncUdpSocketManager()

@property (nonatomic, strong)dispatch_queue_t DelegateQueue;

@end

@implementation AsyncUdpSocketManager

+(instancetype)shareUdpSocketManager {
    static AsyncUdpSocketManager *shareUdpManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareUdpManager = [[AsyncUdpSocketManager alloc] init];
    });
    return shareUdpManager;
}


-(void)initSocket {
    if(!self.socket) {
        if(!self.DelegateQueue) {
            self.DelegateQueue = dispatch_queue_create([AsyncUdpSocketDelegateQueue UTF8String], NULL);
        }
        self.socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:self.DelegateQueue];
    }
}



-(BOOL)broadcastData:(NSData *)data toHost:(NSString *)host port:(uint16_t)port timeOut:(NSTimeInterval)timeOut responseBlock:(UdpSocketBroadCastResponse)responseBlock {
    [self initSocket];
    self.broadCastResponseBlock = responseBlock;
    [self.socket bindToPort:localPort error:nil];
    [self.socket enableBroadcast:YES error:nil];
    [self.socket beginReceiving:nil];
    
    if(timeOut == 0) timeOut = -1;
    if(host == nil) return NO;
    __weak AsyncUdpSocketManager *weakSelf = self;
    __block NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.4 repeats:YES block:^(NSTimer * _Nonnull timer) {
         [weakSelf.socket sendData:data toHost:host port:port withTimeout:timeOut tag:defaultTag];
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeOut * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [timer invalidate]; timer = nil;
        [weakSelf.socket close];
        
    });
    return YES;
}





#pragma mark -GCDAsyncUdpSocketDelegate
/**
 * By design, UDP is a connectionless protocol, and connecting is not needed.
 * However, you may optionally choose to connect to a particular host for reasons
 * outlined in the documentation for the various connect methods listed above.
 *
 * This method is called if one of the connect methods are invoked, and the connection is successful.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address {
    
}

/**
 * By design, UDP is a connectionless protocol, and connecting is not needed.
 * However, you may optionally choose to connect to a particular host for reasons
 * outlined in the documentation for the various connect methods listed above.
 *
 * This method is called if one of the connect methods are invoked, and the connection fails.
 * This may happen, for example, if a domain name is given for the host and the domain name is unable to be resolved.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError * _Nullable)error {
    
}

/**
 * Called when the datagram with the given tag has been sent.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    NSLog(@"Udp data sending");
}

/**
 * Called if an error occurs while trying to send a datagram.
 * This could be due to a timeout, or something more serious such as the data being too large to fit in a sigle packet.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error {
    
}

/**
 * Called when the socket has received the requested datagram.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(nullable id)filterContext {
    NSLog(@"Udp data Receiving");
    self.broadCastResponseBlock(data);
    [self.socket beginReceiving:nil];
    
}

/**
 * Called when the socket is closed.
 **/
- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error {
    NSLog(@"udp Socket closed");
}

@end
