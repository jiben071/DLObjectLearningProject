//
//  HeartBeat.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/8/23.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "HeartBeat.h"
#import "packethub_utils.h"
#import "PacketHub.h"
#import "AsyncUdpSocketManager.h"
#import "AsynTcpSocketManager.h"

NSString *const HeatBeatQueueName = @"com.heatBeatQueue";

//断线超时时间
static NSTimeInterval const breakTimeOut = 60;

//心跳检测频率
static NSTimeInterval const heatRate = 2;

//无数据心跳检测时间
static NSTimeInterval const keep_alive = 8;



static int const cmd_ping = -1;

static int const cmd_pong = -2;

@interface HeartBeat()
{
    NSTimer *heartBeat;
    void *IsOnHeatBeatQueueOrTargetQueueKey;
    NSDate *sendTimer;
    NSDate *receiveTimer;
}

@property (nonatomic, assign) long netWorkInterval;

@property (nonatomic, assign) long robotTimerStamp;

@property (nonatomic, strong) dispatch_queue_t heatBeatQueue;

@property (atomic, strong) NSDate *receiveTime;

@end

@implementation HeartBeat

-(id)init {
    self = [super init];
    if(self) {
        if(!self.heatBeatQueue) {
            self.heatBeatQueue = dispatch_queue_create([HeatBeatQueueName UTF8String], NULL);
            IsOnHeatBeatQueueOrTargetQueueKey = &IsOnHeatBeatQueueOrTargetQueueKey;
            void *nonNullUnusedPointer = (__bridge void *)self;
            dispatch_queue_set_specific(self.heatBeatQueue, IsOnHeatBeatQueueOrTargetQueueKey, nonNullUnusedPointer, NULL);
        }
    }
    return self;
}

//     探测超时时间                     最小时间2s，建议5s+
//     广播包发送间隔时间                暂定400ms
//     发送的广播包数                   默认2s/400ms = 5
//    机器人收到广播包后回复多少个包       暂定1个
-(void)startHeartBeat {
    dispatch_block_t block = ^{
        if(heartBeat) return;
        [self updateReceiveTime];
        heartBeat = [NSTimer scheduledTimerWithTimeInterval:heatRate target:self selector:@selector(heatBeatAction) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:heartBeat forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
    };
    
    if (dispatch_get_specific(IsOnHeatBeatQueueOrTargetQueueKey)) {
        block();
    }else {
        dispatch_async(self.heatBeatQueue, block);
    }
    
}

-(void)heatBeatAction {
    __weak HeartBeat *weakSelf = self;
    dispatch_block_t block = ^{
        if([weakSelf isSocketConnectBreak]) {
            [weakSelf destoryHeartBeat];
            [[AsynTcpSocketManager shareTcpSocketManager] disConnect];
        } else {
            if([weakSelf isHeartBeatTimeOut]) {
                [[AsynTcpSocketManager shareTcpSocketManager] sendMsg:[self ping] withTimeout:-1 withCallBackDelegate:[PacketHub sharePacketHub]];
                sendTimer = [NSDate date];
            }
        }
    };
    if (dispatch_get_specific(IsOnHeatBeatQueueOrTargetQueueKey)) {
        block();
    }else {
        dispatch_async(self.heatBeatQueue, block);
    }
}


-(NSData *)ping {
    NSData *len = [packethub_utils int2Bytes:4];
    NSData *cmd = [packethub_utils int2Bytes:cmd_ping];
    NSMutableData *pingData = [[NSMutableData alloc] init];
    [pingData appendData:len];
    [pingData appendData:cmd];
    return pingData;
}


-(BOOL)isRecvedPong:(NSData *)data {
//    if(data.length == 4) {
//        NSData *len = [data subdataWithRange:NSMakeRange(0, 4)];
//        NSData *cmd = [data subdataWithRange:NSMakeRange(4, 4)];
//        Byte *lenByte = (Byte *)malloc(4);
//        Byte *cmdByte = (Byte *)malloc(4);
//        memcpy(lenByte, [len bytes], 4);
//        memcpy(cmdByte, [cmd bytes], 4);
//        if([Utils bytes2Int:lenByte] == 4) {
//            if([Utils bytes2Int:cmdByte] == cmd_pong) {
//                return YES;
//            }
//        }
//    }
//    return NO;
    
    if(data.length == 12) {
        NSData *cmd = [data subdataWithRange:NSMakeRange(0, 4)];
        NSLog(@"cmd = %@", cmd);
        if([packethub_utils bytes2Int:[cmd bytes]] == cmd_pong) {
            NSData *timeData = [data subdataWithRange:NSMakeRange(4,8)];
            self.robotTimerStamp = [packethub_utils bytes2Long:[timeData bytes]];
            [self caculateNetworkInerval];
            return YES;
        }else {
            return NO;
        }
    }
    return NO;
}


-(void)destoryHeartBeat {
    [heartBeat invalidate];
    heartBeat = nil;
}

-(BOOL)isSocketConnectBreak {
    NSDate *currentDate = [NSDate date];
    //发送接收包时间超时则发送心跳
    if([currentDate timeIntervalSinceDate:self.receiveTime] > breakTimeOut) {
        return YES;
    } else {
        return NO;
    }
}


-(BOOL)isHeartBeatTimeOut {
    NSDate *currentDate = [NSDate date];
    //发送接收包时间超时则发送心跳
    if([currentDate timeIntervalSinceDate:self.receiveTime] > keep_alive) {
        return YES;
    } else {
        return NO;
    }
}

-(void)caculateNetworkInerval {
    receiveTimer = [NSDate date];
    self.netWorkInterval = (long)([receiveTimer timeIntervalSinceDate:sendTimer] * 1000) / 2;
    long currentTimeInterval = (long)([receiveTimer timeIntervalSince1970] * 1000);
    self.differInterval = currentTimeInterval  - (self.robotTimerStamp + self.netWorkInterval);
}

-(void)updateReceiveTime {
    self.receiveTime = [NSDate date];
}





@end
