//
//  RobotPushTask.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/13.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "RobotPushTask.h"
#import "SyncParams.pbobjc.h"
#import "SyncFiles.pbobjc.h"


#import "SyncModifyClient.h"
#import "SyncRobotClient.h"

#import "ModifyModel.h"
#import "FileModel.h"




@implementation RobotPushTask

-(void)start:(void(^)(Result *result, int code))callback {
    PushRequest *pushRequest = [[PushRequest alloc] init];
    pushRequest.seqId = [[NSDate date] timeIntervalSince1970];
    pushRequest.operateArray = [self obtainOperates].mutableCopy;
    [[PacketHub sharePacketHub] getUri:[NSString stringWithFormat:@"%@%@",PATH_HOST,REQUEST_PUSH_META_DATA] param:pushRequest success:^(Response *responseObj) {
        if(responseObj.status == Response_Status_StatusOk) {
            PushResponse *pushResponse = (PushResponse *)[responseObj.param unpackMessageClass:[PushResponse class] error:nil];
            Result *result = [self newResult:pushResponse.code];
            callback(result, result.code);
        }else {
            Result *result = [self newResult:FAILED];
            callback(result, result.code);
        }
    
    } failure:^(NSError *error) {
        Result *result = [self newResult:FAILED];
        callback(result, result.code);
    }];
}


-(Result *)newResult:(Code)code {
    Result *result = [[Result alloc] init];
    result.obj = OBJ_ROBOT;
    result.code = code;
    return result;
}



-(NSArray <ModifyData *> *)obtainOperates {
    NSMutableArray *modifyDataArray = [NSMutableArray array];
    SyncRobotClient *robotClient = [SyncRobotClient shareSyncRobotClient];
    SyncModifyClient *modifyClient = [SyncModifyClient shareSyncModifyClient];
    NSArray *robotModels = [robotClient getData];
    NSArray *modifyModels = [modifyClient getData];
    if(robotModels == nil || modifyModels == nil) {
        return nil;
    }

    for (ModifyModel *modifyMode in modifyModels) {
        if(modifyMode == nil || [Sync_Utils isEmptyString:modifyMode.path]) {
            continue;
        }
        for (FileModel *fileMode in robotModels) {
            if(fileMode == nil) {
                continue;
            }
            if([modifyMode.path hasSuffix:fileMode.path]) {
                ModifyData *item = [[ModifyData alloc] init];
                item.path = modifyMode.path;
                item.action = modifyMode.action;
                if(![Sync_Utils isEmptyString:modifyMode.path_new]) {
                    item.newPath = modifyMode.path_new;
                }
                item.createTime = modifyMode.timestamp;
                [modifyDataArray addObject:item];
                break;
            }
        }
    }
    return modifyDataArray;
}
@end
