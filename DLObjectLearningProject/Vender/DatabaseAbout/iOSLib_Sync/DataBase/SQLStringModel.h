//
//  SQLStringModel.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//  SQL语句构造器

#import <Foundation/Foundation.h>
#import "NSString+SQL.h"

@interface SQLStringModel : NSObject

//create table sql
+(NSString *)createTable:(NSString *)tableName columnInfo:(NSDictionary *)columnInfo;

+(NSString *)dropTable:(NSString *)tableName;

+(NSString *)addColumn:(NSString *)columnName columnInfo:(NSString *)columnInfo tableName:(NSString *)tableName;



//insert sql
+(NSString *)insertTable:(NSString *)tableName withDataList:(NSArray *)dataList;

//update sql
+(NSString *)updateTable:(NSString *)tableName withData:(NSDictionary *)data condition:(NSString *)condition conditionParams:(NSDictionary *)conditionParams;

//delete sql
+(NSString *)deleteTable:(NSString *)tableName withCondition:(NSString *)condition conditionParams:(NSDictionary *)conditionParams;



//fetch sql
+(NSString *)select:(NSString *)columList isDistinct:(BOOL)isDistinct;

+(NSString *)from:(NSString *)fromList;

+(NSString *)where:(NSString *)condition params:(NSDictionary *)params;

+(NSString *)orderBy:(NSString *)orderBy isDESC:(BOOL)isDESC;

+(NSString *)limit:(NSInteger)limit;

+(NSString *)offset:(NSInteger)offset;

+(NSString *)limit:(NSInteger)limit offset:(NSInteger)offset;

+(NSString *)countAll;
@end
