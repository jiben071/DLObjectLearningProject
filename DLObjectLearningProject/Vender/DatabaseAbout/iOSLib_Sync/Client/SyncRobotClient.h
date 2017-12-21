//
//  SyncRobotClient.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "SyncClient.h"
#import "RobotTable.h"

@interface SyncRobotClient : SyncClient

+(instancetype)shareSyncRobotClient;
@property (nonatomic,assign) BOOL isAlreadyGetAllData;/**< 判断是否已经获取到所有的数据 */
/**< 查询是否需要插入数据 */
//- (NSArray *)findModelOrderBy:(NSString *)orderCondition condictionParams:(NSDictionary *)conditionParams;
- (NSArray *)findModelOrderBy:(NSString *)orderKey whereCondition:(NSString *)condition;
/**< 根据路径判断是否存在该数据 */
- (BOOL)isExistInDataBaseWithPathKey:(NSString *)path;
@end
