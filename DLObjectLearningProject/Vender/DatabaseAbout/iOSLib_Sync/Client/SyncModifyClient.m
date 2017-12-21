//
//  SyncModifyClient.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "SyncModifyClient.h"

@implementation SyncModifyClient


+(instancetype)shareSyncModifyClient {
    static SyncModifyClient *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[SyncModifyClient alloc] init];
    });
    return shareInstance;
}


-(id)init {
    self = [super init];
    if(self) {
        [self newModifyTable];
    }
    return self;
}

-(void)newModifyTable {
    self.table = [[ModifyTable alloc] init];
}

-(void)deleteObjWithFileModel:(FileModel *)fileModel{
    if(fileModel == nil) return;
    ModifyModel *mode = [[ModifyModel alloc] init];
    mode.action = Consts_FILE_ACTION_DELETE;
    mode.path = fileModel.path;
    mode.timestamp = fileModel.timestamp;
    [self add:mode];
}

@end
