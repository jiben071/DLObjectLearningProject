//
//  ModifyTable.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "ModifyTable.h"
#import "ModifyModel.h"

@implementation ModifyTable

- (NSString *)tableName {
    return @"modify";
}

- (NSDictionary *)columnInfo {
    return @{@"id_q": @"integer primary key autoincrement",  //NSUInteger
             @"thumbnail":@"text",
             @"path":@"text unique",  //NSString
             @"path_new":@"text",     //NSString
             @"action":@"text",       //NSString
             @"clientVersion":@"text", //NSString
             @"deviceId":@"text",      //NSString
             @"projectName":@"text",   //NSString
             @"storageType":@"integer",  //int
             @"cloudType":@"integer",    //int
             @"createTime":@"bigint",     //long
             @"fileName":@"text",      //NSString
             @"key":@"text",           //NSString
             @"location":@"text",     //NSArray
             @"fileName_new":@"text",  //NSString
             @"timestamp":@"bigint"  //long
             };
}

- (Class)recordClass {
    return [ModifyModel class];
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
