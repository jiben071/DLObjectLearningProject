//
//  SQLStringModel.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#define SQLStringModel_isEmptyString(string) ((string == nil || string.length == 0) ? YES : NO)

#import "SQLStringModel.h"

@implementation SQLStringModel

//create table sql
//创建表格
+(NSString *)createTable:(NSString *)tableName columnInfo:(NSDictionary *)columnInfo {
    if(SQLStringModel_isEmptyString(tableName) || columnInfo == nil) return nil;
    NSMutableArray *columnList = [NSMutableArray array];
    [columnInfo enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSString *  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *safeColumnName = key;
        NSString *safeDescription = obj;
        
        if(SQLStringModel_isEmptyString(safeDescription)) {
            [columnList addObject:[NSString stringWithFormat:@"'%@'", safeColumnName]];
        }else {
            [columnList addObject:[NSString stringWithFormat:@"'%@' %@", safeColumnName, safeDescription]];
        }
    }];
    
    NSString *columns = [columnList componentsJoinedByString:@","];
    
    return [[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (%@);", tableName, columns] copy];
}

//移除表格
+(NSString *)dropTable:(NSString *)tableName {
    if(SQLStringModel_isEmptyString(tableName)) return nil;
    return [[NSString stringWithFormat:@"DROP TABLE IF EXISTS '%@';",tableName] copy];
}


//添加列
+(NSString *)addColumn:(NSString *)columnName columnInfo:(NSString *)columnInfo tableName:(NSString *)tableName {
    if(SQLStringModel_isEmptyString(columnName) || SQLStringModel_isEmptyString(columnInfo) || SQLStringModel_isEmptyString(tableName)) {
        return  nil;
    }
    return [NSString stringWithFormat:@"ALTER TABLE '%@' ADD COLUMN '%@' %@;", tableName, columnName, columnInfo];
}


//insert sql
//插入数据
+(NSString *)insertTable:(NSString *)tableName withDataList:(NSArray *)dataList {
    if(SQLStringModel_isEmptyString(tableName) || dataList == nil) return nil;
    NSMutableArray *valueItemList = [NSMutableArray array];
    __block NSString *columString = nil;
    [dataList enumerateObjectsUsingBlock:^(NSDictionary*  _Nonnull description, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableArray *columList = [NSMutableArray array];
        NSMutableArray *valueList = [NSMutableArray array];
        [description enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull colum, id _Nonnull value, BOOL * _Nonnull stop) {
            [columList addObject:[NSString stringWithFormat:@"'%@'", colum]];
            
            if ([value isKindOfClass:[NSNull class]]) {
                [valueList addObject:@"NULL"];
            } else if([value isKindOfClass:[NSString class]]){
                [valueList addObject:[NSString stringWithFormat:@"'%@'", value]];
            } else {
                [valueList addObject:[NSString stringWithFormat:@"%@", value]];
            }
        }];
        if (columString == nil) {
            columString = [columList componentsJoinedByString:@","];
        }
        NSString *valueString = [valueList componentsJoinedByString:@","];
        [valueItemList addObject:[NSString stringWithFormat:@"(%@)", valueString]];
    }];
    
    return [[NSString stringWithFormat:@"INSERT INTO '%@' (%@) VALUES %@;",tableName, columString, [valueItemList componentsJoinedByString:@","]] copy];
}



//update sql
//更新数据
+(NSString *)updateTable:(NSString *)tableName withData:(NSDictionary *)data condition:(NSString *)condition conditionParams:(NSDictionary *)conditionParams {
    NSMutableArray *valueList = [NSMutableArray array];
    [data enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull colum, id  _Nonnull value, BOOL * _Nonnull stop) {
        if([value isKindOfClass:[NSString class]]) {
            [valueList addObject:[NSString stringWithFormat:@"'%@'='%@'", colum, value]];
        }else if ([value isKindOfClass:[NSNull class]]) {
            [valueList addObject:[NSString stringWithFormat:@"'%@'=NULL", colum]];
        } else {
            [valueList addObject:[NSString stringWithFormat:@"'%@'=%@", colum, value]];
        }
    }];
    NSString *valueString = [valueList componentsJoinedByString:@","];

    NSString *sqlString = [NSString stringWithFormat:@"UPDATE '%@' SET %@ ", tableName, valueString];
    
    return [[NSString stringWithFormat:@"%@%@", sqlString,[SQLStringModel where:condition params:conditionParams]] copy];
    
}


//delete sql
//删除数据
+(NSString *)deleteTable:(NSString *)tableName withCondition:(NSString *)condition conditionParams:(NSDictionary *)conditionParams {
    if(SQLStringModel_isEmptyString(tableName)) return nil;
    
    NSString *sqlString = [NSString stringWithFormat:@"DELETE FROM '%@' ",tableName];
    
    return [[NSString stringWithFormat:@"%@%@", sqlString, [SQLStringModel where:condition params:conditionParams]] copy];
}




//fetch sql
//抓取数据
+(NSString *)select:(NSString *)columList isDistinct:(BOOL)isDistinct {
    if (columList == nil) {
        if (isDistinct) {
            return [[NSString stringWithFormat:@"SELECT DISTINCT * "] copy];
        } else {
            return [[NSString stringWithFormat:@"SELECT * "] copy];
        }
    } else {
        if (isDistinct) {
            return [[NSString stringWithFormat:@"SELECT DISTINCT '%@' ", columList] copy];
        } else {
            return [[NSString stringWithFormat:@"SELECT '%@' ",columList] copy];
        }
    }
}

#pragma mark - 条件语句
#pragma mark -- 表格
+(NSString *)from:(NSString *)fromList {
    if (fromList == nil) {
        return nil;
    }
    return [[NSString stringWithFormat:@"FROM '%@' ", fromList] copy];
}

#pragma mark -- where条件
+(NSString *)where:(NSString *)condition params:(NSDictionary *)params {
    if (condition == nil) {
        return @"";
    }
    NSString *whereString = [condition stringWithSQLParams:params];
    return [[NSString stringWithFormat:@"WHERE %@ ",whereString] copy];
}

#pragma mark -- 排序
+(NSString *)orderBy:(NSString *)orderBy isDESC:(BOOL)isDESC {
    if (orderBy == nil) {
        return @"";
    }
    NSMutableString *sqlString = [NSMutableString string];
    [sqlString appendFormat:@"ORDER BY %@ ", orderBy];
    if (isDESC) {
        [sqlString appendString:@"DESC "];
    } else {
        [sqlString appendString:@"ASC "];
    }
    return sqlString.copy;
}

#pragma mark -- 数量限制
+(NSString *)limit:(NSInteger)limit {
    if (limit == -1) {
        return nil;
    }
    return [[NSString stringWithFormat:@"LIMIT %lu ",(unsigned long)limit] copy];
}

#pragma mark --
+(NSString *)offset:(NSInteger)offset {
    if (offset == -1) {
        return nil;
    }
    return [[NSString stringWithFormat:@"OFFSET %lu ",(unsigned long)offset] copy];
}

+(NSString *)limit:(NSInteger)limit offset:(NSInteger)offset {
    NSString *str1 = [SQLStringModel  limit:limit];
    NSString *str2 = [SQLStringModel offset:offset];
    return [[NSString stringWithFormat:@"%@%@", str1, str2] copy];
}

#pragma mark -- 获取所有数据
+(NSString *)countAll {
    return [[NSString stringWithFormat:@"SELECT COUNT(*) "] copy];
}







@end
