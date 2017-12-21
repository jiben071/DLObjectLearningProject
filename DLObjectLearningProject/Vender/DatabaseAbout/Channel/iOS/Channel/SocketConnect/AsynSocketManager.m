//
//  SocketManager.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/8/18.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "AsynSocketManager.h"

#import <arpa/inet.h>
#import <fcntl.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <net/if.h>
#import <sys/socket.h>
#import <sys/types.h>

#import <CFNetwork/CFNetwork.h>

#define INET_ADDRSTRLEN     16
#define	INET6_ADDRSTRLEN	46

@implementation AsynSocketManager

+ (NSDictionary *)localIPAddress
{
    NSString *address = nil;
    NSString *addressMask = nil;
    NSString *addressBroadcast = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    
    if (success == 0)
    {
        temp_addr = interfaces;
        
        while(temp_addr != NULL)
        {
            // check if interface is en0 which is the wifi connection on the iPhone
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    addressMask = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)];
                    addressBroadcast = [AsynSocketManager getBroadcastAddressWithaddress:address addressmask:addressMask];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    
    if(address && addressMask && addressBroadcast) {
        return [NSDictionary dictionaryWithObjectsAndKeys:address,@"HOST", addressMask, @"NETMASK", addressBroadcast, @"BROADCASTHOST", nil];
    }
    
    return nil;
}

+(NSString *)getBroadcastAddressWithaddress:(NSString *)address addressmask:(NSString *)addressMask {
    if(address && addressMask) {
        NSArray *addressArray = [address componentsSeparatedByString:@"."];
        NSArray *addressmaskArray = [addressMask componentsSeparatedByString:@"."];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:4];
        for (int i = 0; i < addressArray.count; i++) {
            int addressNum = [[addressArray objectAtIndex:i] intValue];
            int addressmaskNum = [[addressmaskArray objectAtIndex:i] intValue];
            int broadcastNum = addressNum & addressmaskNum;
            if(broadcastNum == 0 && addressmaskNum == 0) broadcastNum = 255;
            [array addObject:@(broadcastNum)];
        }
        return [array componentsJoinedByString:@"."];
        
    }else return nil;
}

@end
