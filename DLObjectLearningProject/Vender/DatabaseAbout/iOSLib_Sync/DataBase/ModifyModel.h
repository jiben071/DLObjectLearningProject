//
//  ModifyModel.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//  需要修改的实体


#import "BaseModel.h"
#import "SyncFiles.pbobjc.h"
#import "Protocol.h"


@interface ModifyModel : BaseModel

@property (nonatomic, strong) NSString *thumbnail;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *action;
@property (nonatomic, assign) long timestamp;
@property (nonatomic, strong) NSString *path_new;
@property (nonatomic, strong) NSString *clientVersion;
@property (nonatomic, strong) NSString *deviceId;
@property (nonatomic, assign) int cloudType;
@property (nonatomic, assign) long createTime;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSArray *location;
@property (nonatomic, strong) NSString *fileName_new;
@property (nonatomic, strong) NSString *projectName;
@property (nonatomic, assign) int storageType;


+(ModifyModel *)read:(ModifyData *)item;


-(BOOL)isEqualToMode:(ModifyModel *)modifyModel;


@end


