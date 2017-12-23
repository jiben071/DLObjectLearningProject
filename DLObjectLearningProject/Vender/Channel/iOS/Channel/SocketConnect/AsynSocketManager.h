//
//  SocketManager.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/8/18.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "GCDAsyncUdpSocket.h"

typedef NS_ENUM(NSUInteger, SocketConnectStatus) {
    Disconnect,
    Connecting,
    Connected,
};


@interface AsynSocketManager : NSObject

+ (NSDictionary *)localIPAddress;

+(NSString *)getBroadcastAddressWithaddress:(NSString *)address addressmask:(NSString *)addressMask;


@end
