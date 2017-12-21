//
//  SyncRobotClient.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "SyncRobotClient.h"



@implementation SyncRobotClient
@synthesize isAlreadyGetAllData = _isAlreadyGetAllData;

+(instancetype)shareSyncRobotClient {
    static SyncRobotClient *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[SyncRobotClient alloc] init];
    });
    return shareInstance;
}

-(id)init {
    self = [super init];
    if(self) {
        [self newRobotTable];
    }
    return self;
}

-(void)newRobotTable {
    self.table = [[RobotTable alloc] init];
}

- (void)setIsAlreadyGetAllData:(BOOL)isAlreadyGetAllData{
    _isAlreadyGetAllData = isAlreadyGetAllData;
    
    // 1. 创建NSUserDefaults单例:
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 2. 数据写入:
    // 通过 key 值 来存入 和 读取数据
    [defaults setInteger:isAlreadyGetAllData forKey:@"isAlreadyGetAllData"];
    // 注意：对相同的Key赋值约等于一次覆盖，要保证每一个Key的唯一性
    
    // 3. 将数据 立即存入到 磁盘:
    [defaults synchronize];
}

- (BOOL)isAlreadyGetAllData{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // 4. 通过key值 按照写入对应类型 读取数据 有返回值
    BOOL isAlreadyGetAllData = [defaults boolForKey:@"isAlreadyGetAllData"];
    return isAlreadyGetAllData;

}


-(NSArray *)getData {
    if(self.table) {
        return [self.table findAllWithWhereCondition:nil orderBy:@"timestamp" error:nil];
    }else {
        return nil;
    }
}


/*
 - (NSArray <BaseModel <SQLModelRecordProtocol> *> *)findAllWithWhereCondition:(NSString *)condition conditionParams:(NSDictionary *)conditionParams isDistinct:(BOOL)isDistinct error:(NSError **)error;
 */
- (NSArray *)findModelOrderBy:(NSString *)orderKey whereCondition:(NSString *)condition{
    NSError *error = nil;
    if (condition == nil) {
        condition = @"";
    }
    
    if (orderKey == nil) {
        orderKey = @"";
    }
    if(self.table) {
        NSArray *array = [self.table findAllWithWhereCondition:condition orderBy:orderKey error:&error];
        if (error) {
            return nil;
        }
        return array;
    }else {
        return nil;
    }
}

- (BOOL)isExistInDataBaseWithPathKey:(NSString *)path{
//    NSArray *array = [self findModelOrderBy:@"timestamp" condictionParams:@{@"path":path}];
    NSArray *array = [self findModelOrderBy:@"timestamp" whereCondition:[NSString stringWithFormat:@"path = '%@'",path]];
    return (array.count > 0);
}

@end
