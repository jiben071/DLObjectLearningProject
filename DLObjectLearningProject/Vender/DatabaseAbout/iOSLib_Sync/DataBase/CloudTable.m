//
//  CloudTable.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "CloudTable.h"
#import "FileModel.h"

@implementation CloudTable

- (NSString *)tableName {
    return @"cloud";
}

- (NSDictionary *)columnInfo {
    return @{@"id_q":@"integer primary key autoincrement",
             @"state":@"text",
             @"fileKey":@"text",
             @"hash_":@"text",
             @"filename":@"text",
             @"uploadedTime":@"text",
             @"originRobotId":@"text",
             @"uploaderId":@"text",
             @"cloudId":@"integer",
             @"storageType":@"integer",
             @"isCollected":@"integer",
             @"fileDescription":@"text",
             @"path":@"text unique",
             @"type":@"text",
             @"tags":@"text",
             @"location":@"text",
             @"timestamp":@"text",
             @"size":@"text",
             @"preview":@"text",
             @"thumbnail":@"text",
             @"from":@"text default 'cloud'",
             @"len":@"text",
             };
}

- (Class)recordClass {
    return [FileModel class];
}

- (NSString *)primaryKeyName {
    return @"id_q";
}

-(instancetype)init {
    self = [super init];
    if(self) {
        
    }
    return self;
}

@end
