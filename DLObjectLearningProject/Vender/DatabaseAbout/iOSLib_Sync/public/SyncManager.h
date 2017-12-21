//
//  SyncManager.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/11.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileModel.h"
#import "ModifyModel.h"
#import "Result.h"


typedef NS_ENUM(NSUInteger, Pull_Operation) {
    PULL_CLOUD = 1,
    PULL_ROBOT,
    PULL_PHOTOALBUM,/**< 拉取相册列表 */
    PULL_PHOTO,/**< 拉取图片 */
    PULL_ALL,
};

typedef NS_ENUM(NSUInteger, Push_Operation) {
    PUSH_CLOUD = 1,
    PUSH_ROBOT,
    PUSH_DELETE_PHOTO,/**< 删除图片 */
    PUSH_ALL,
};


@interface SyncManager : NSObject

+(instancetype)shareSyncManager;

-(void)pull:(Pull_Operation)operation withCallback:(void(^)(NSArray<Result *> *resultList, int code))callBack;

-(void)push:(Push_Operation)operation withCallback:(void(^)(NSArray<Result *> *resultList, int code))callBack;

-(void)addModify:(ModifyModel *)modifyModel;

-(NSArray <FileModel *> *)getRobotFiles;

-(NSArray <ModifyModel *> *)getModifyFiles;

-(NSArray <FileModel *> *)getCloudFiles;

-(NSArray <FileModel *> *)getFiles;
@end
