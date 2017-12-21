//
//  RobotPullTask.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/13.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "RobotPullTask.h"
#import "FileModel.h"
#import "SyncParams.pbobjc.h"
#import "SyncFiles.pbobjc.h"
#import "SyncRobotClient.h"

@interface RobotPullTask() {
    NSData *_context;
}

@end

@implementation RobotPullTask

-(void)start:(void(^)(Result *result, int code))callback {
    PullRequest *pullRequest = [[PullRequest alloc] init];
    pullRequest.seqId = [[NSDate date] timeIntervalSince1970];
    pullRequest.lastServerUuid = [[UIDevice currentDevice].identifierForVendor UUIDString];
    pullRequest.clientDataVersion = 1;
    
    [[PacketHub sharePacketHub] getUri:[NSString stringWithFormat:@"%@%@",PATH_HOST,REQUEST_PULL_META_DATA] param:pullRequest success:^(Response *responseObj) {
        if(responseObj.status == Response_Status_StatusOk) {
            PullResponse *pullResponse = (PullResponse *)[responseObj.param unpackMessageClass:[PullResponse class] error:nil];
            _context = pullResponse.context;
            NSString *mode = pullResponse.mode;
            Result *result = [[Result alloc] init];
            if([Consts_MODE_REPLACE isEqualToString:mode]) {
                result.type = TYPE_REPLACE;
                result.count = [self replace:pullResponse.dataArray];
            }else if([Consts_MODE_MERGE isEqualToString:mode]) {
                result.type = TYPE_MERGE;
                result.count = [self merge:pullResponse.dataArray];
            }else if([Consts_MODE_NONE isEqualToString:mode]) {
                
            }else {
                
            }
            result.version = pullResponse.serverDataVersion;
            result.code = SUCCESS;
            callback(result, result.code);

            
        }else {
            Result *result = [[Result alloc] init];
            result.obj = OBJ_ROBOT;
            result.code = FAILED;
            callback(result, result.code);
        }
        
    } failure:^(NSError *error) {
        Result *result = [[Result alloc] init];
        result.obj = OBJ_ROBOT;
        result.code = FAILED;
        callback(result, result.code);
    }];
}


-(int)replace:(NSArray<MetaData *> *)dataList {
    if(dataList == nil) return 0;
    NSMutableArray *modelList = [NSMutableArray array];
    for (MetaData *data in dataList) {
        FileModel *model = [FileModel read:data];
        if(model) {
            [modelList addObject:model];
        }
    }
    SyncRobotClient *client = [SyncRobotClient shareSyncRobotClient];
    [client removeAllItem];
    [client addList:modelList];
    return (int)modelList.count;
    
}


-(int)merge:(NSArray<MetaData *> *)dataList {
    if(dataList == nil) return 0;
    SyncRobotClient *client = [SyncRobotClient shareSyncRobotClient];
    for (MetaData *data in dataList) {
        if(data == nil) continue;
        FileModel *model = [FileModel read:data];
        if(model == nil) continue;
        if([Consts_FILE_ACTION_ADD isEqualToString:data.action]) {
            [client add:model];
        }else if([Consts_FILE_ACTION_DELETE isEqualToString:data.action]) {
            [client remove:model];
        }else if([Consts_FILE_ACTION_RENAME isEqualToString:data.action]) {
            
        }
    }
    return (int)dataList.count;
}


@end
