//
//  RobotTable.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "RobotTable.h"
#import "FileModel.h"

@implementation RobotTable
- (NSString *)tableName {
    return @"robot";
}

- (NSDictionary *)columnInfo {
    return @{@"id_q":@"integer primary key autoincrement",  //NSUInteger
             @"path":@"text unique",  //NSString
             @"thumbnail":@"text",  //NSString
             @"preview":@"text",     //NSString
             @"type":@"text",       //NSString
             @"tags":@"text",       //NSArray
             @"location":@"text",   //NSArray
             @"timestamp":@"bigint",  //long
             @"size":@"bigint",       //long
             @"uploaderId":@"bigint", //long
             @"from":@"text",       //NSString
             @"len":@"bigint",       //long
             @"orinalImageURL":@"text",//NSString
             @"bigImageURL":@"text",//NSString
             @"thumnailImageURL":@"text",//NSString
             };
}

-(Class)recordClass {
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
