//
//  SimpleTask.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/13.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PacketHub.h"
#import "PacketHub_IM.h"
#import "Sync_Utils.h"
#import "Protocol.h"
#import "Result.h"
#import "SyncParams.pbobjc.h"

@interface SimpleTask : NSObject

-(void)start:(void(^)(Result *result, int code))callback;

@end
