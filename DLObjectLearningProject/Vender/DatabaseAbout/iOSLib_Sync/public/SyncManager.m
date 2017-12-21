//
//  SyncManager.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/11.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "SyncManager.h"

#import "SyncCloudClient.h"
#import "SyncRobotClient.h"
#import "SyncModifyClient.h"

#import "BatchTask.h"

#import "RobotPullTask.h"
#import "RobotPushTask.h"
#import "CloudPullTask.h"
#import "CloudPushTask.h"


@implementation SyncManager

+(instancetype)shareSyncManager {
    static SyncManager *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[SyncManager alloc] init];
    });
    return shareInstance;
}

-(id)init {
    self = [super init];
    if(self) {
        
    }
    return self;
}


-(void)pull:(Pull_Operation)operation withCallback:(void(^)(NSArray<Result *> *resultList, int code))callBack {
    switch (operation) {
        case PULL_CLOUD:
        {
            CloudPullTask *cloudPullTask = [[CloudPullTask alloc] init];
            [[BatchTask shareBatchTask] startTask:@[cloudPullTask] withCallback:callBack];
        }
            break;
        case PULL_ROBOT:
        {
            RobotPullTask *robotPullTask = [[RobotPullTask alloc] init];
             [[BatchTask shareBatchTask] startTask:@[robotPullTask] withCallback:callBack];
        }
            break;
        case PULL_ALL:
        {
            RobotPullTask *robotPullTask = [[RobotPullTask alloc] init];
            CloudPullTask *cloudPullTask = [[CloudPullTask alloc] init];
             [[BatchTask shareBatchTask] startTask:@[robotPullTask, cloudPullTask] withCallback:callBack];
        }
            break;
        default:
            break;
    }
    
}


-(void)push:(Push_Operation)operation withCallback:(void(^)(NSArray<Result *> *resultList, int code))callBack {
    switch (operation) {
        case PUSH_CLOUD:
        {
            CloudPushTask *cloudPushTask = [[CloudPushTask alloc] init];
            [[BatchTask shareBatchTask] startTask:@[cloudPushTask] withCallback:callBack];
        }
            break;
        case PUSH_ROBOT:
        {
            RobotPushTask *robotPushTask = [[RobotPushTask alloc] init];
            [[BatchTask shareBatchTask] startTask:@[robotPushTask] withCallback:callBack];
        }
            break;
        case PUSH_ALL:
        {
            RobotPushTask *robotPushTask = [[RobotPushTask alloc] init];
            CloudPushTask *cloudPushTask = [[CloudPushTask alloc] init];
            [[BatchTask shareBatchTask] startTask:@[robotPushTask, cloudPushTask] withCallback:callBack];

        }
            break;
        default:
            break;
    }
}


-(void)addModify:(ModifyModel *)modifyModel {
    SyncModifyClient *client = [SyncModifyClient shareSyncModifyClient];
    [client add:modifyModel];
}

-(NSArray <FileModel *> *)getRobotFiles {
    SyncRobotClient *client = [SyncRobotClient shareSyncRobotClient];
    NSArray *array = [[client getData] sortedArrayUsingComparator:^NSComparisonResult(FileModel * _Nonnull obj1, FileModel *_Nonnull obj2) {
        if(obj1.timestamp < obj2.timestamp) {
            return NSOrderedDescending;
        }else {
            return NSOrderedAscending;
        }
    }];
    return array;
}

-(NSArray <ModifyModel *> *)getModifyFiles {
    SyncModifyClient *client = [SyncModifyClient shareSyncModifyClient];
    NSArray *array = [[client getData] sortedArrayUsingComparator:^NSComparisonResult(FileModel * _Nonnull obj1, FileModel *_Nonnull obj2) {
        if(obj1.timestamp < obj2.timestamp) {
            return NSOrderedDescending;
        }else {
            return NSOrderedAscending;
        }
    }];
    return array;
}

-(NSArray <FileModel *> *)getCloudFiles {
    SyncCloudClient *client = [SyncCloudClient shareSyncCloudClient];
    NSArray *array = [[client getData] sortedArrayUsingComparator:^NSComparisonResult(FileModel * _Nonnull obj1, FileModel *_Nonnull obj2) {
        if(obj1.timestamp < obj2.timestamp) {
            return NSOrderedDescending;
        }else {
            return NSOrderedAscending;
        }
    }];
    return array;
}

-(NSArray <FileModel *> *)getFiles {
    NSMutableArray *allArray = [NSMutableArray array];
    NSArray *cloudArray = [self getCloudFiles];
    NSArray *robotArray = [self getRobotFiles];
    if(cloudArray) {
        [allArray addObject:cloudArray];
    }
    if(robotArray) {
        [allArray addObject:robotArray];
    }
    
   NSArray *result = [allArray sortedArrayUsingComparator:^NSComparisonResult(FileModel * _Nonnull obj1, FileModel * _Nonnull obj2) {
       if(obj1.timestamp < obj2.timestamp) {
           return NSOrderedDescending;
       }else {
           return NSOrderedAscending;
       }
   }];
    return result;
}





@end
