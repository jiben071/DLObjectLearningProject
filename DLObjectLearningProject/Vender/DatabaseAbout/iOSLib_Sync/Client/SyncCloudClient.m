//
//  SyncCloudClient.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "SyncCloudClient.h"

@implementation SyncCloudClient



+(instancetype)shareSyncCloudClient {
    static SyncCloudClient *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[SyncCloudClient alloc] init];
    });
    return shareInstance;
}

-(id)init {
    self = [super init];
    if(self) {
        [self newCloudTable];
    }
    return self;
}

-(void)newCloudTable {
    self.table = [[CloudTable alloc] init];
}



@end
