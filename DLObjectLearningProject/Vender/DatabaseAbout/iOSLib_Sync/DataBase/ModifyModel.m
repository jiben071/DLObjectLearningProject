//
//  ModifyModel.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "ModifyModel.h"
#import "SyncModifyClient.h"

@implementation ModifyModel

#pragma mark - SQLModelRecordProtocol
- (NSArray *)availableKeyList
{
    return @[@"id_q",@"thumbnail",@"path", @"action",@"timestamp",@"path_new",@"clientVersion",@"deviceId",@"cloudType",@"createTime",@"fileName",@"key",@"location",@"fileName_new",@"projectName",@"storageType"];
}


+(ModifyModel *)read:(ModifyData *)item {
    if(item == nil) return nil;
    ModifyModel *mode = [[ModifyModel alloc] init];
    mode.action = item.action;
    mode.path = item.path;
    if([Consts_FILE_ACTION_RENAME isEqualToString:mode.action]) {
        mode.path_new = item.newPath;
    }
    mode.timestamp = item.createTime;
    return mode;
}

-(BOOL)isEqualToMode:(ModifyModel *)modifyModel {
    return [self.path isEqualToString:modifyModel.path];
}

@end
