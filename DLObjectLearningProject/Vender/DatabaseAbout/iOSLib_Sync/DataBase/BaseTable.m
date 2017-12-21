//
//  BaseTable.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "BaseTable.h"
#import "SQLStringModel.h"
#import "NSString+SQL.h"


#import "DataBase.h"



@implementation BaseTable

-(instancetype)init {
    self = [super init];
    if(self) {
        NSString *sqlString = [SQLStringModel createTable:[self tableName] columnInfo:[self columnInfo]];
        BOOL isSuccess = [[DataBase shareDataBase] createTable:sqlString];
        if(!isSuccess) {
            NSLog(@"create table: %@ is fail",[self tableName]);
        }
    }
    return self;
}

//insert
- (BOOL)insertRecordList:(NSArray <BaseModel <SQLModelRecordProtocol> *> *)recordList error:(NSError **)error {
    BOOL isSuccess = NO;
    NSMutableArray *insertList = [NSMutableArray array];
    [recordList enumerateObjectsUsingBlock:^(BaseModel<SQLModelRecordProtocol> * _Nonnull record, NSUInteger idx, BOOL * _Nonnull stop) {
        [insertList addObject:[record dictionaryRepresentationWithTable:self]];
    }];
    NSString *sqlString = [SQLStringModel insertTable:[self tableName] withDataList:insertList];
    isSuccess = [[DataBase shareDataBase] insertData:sqlString];
    if(!isSuccess) {
        if(error) {
            *error = [NSError errorWithDomain:SQLOperationErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Excute sql: '%@' fail", sqlString]}];
        }
    }
    return isSuccess;
}

- (BOOL)insertRecord:(BaseModel <SQLModelRecordProtocol> *)record error:(NSError **)error {
    BOOL isSuccess = NO;
    if(record) {
        NSString *sqlString = [SQLStringModel insertTable:[self tableName] withDataList:@[[record dictionaryRepresentationWithTable:self]]];
        isSuccess = [[DataBase shareDataBase] insertData:sqlString];
        if(!isSuccess) {
            if(error) {
                *error = [NSError errorWithDomain:SQLOperationErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Excute sql: '%@' fail", sqlString]}];
            }
        }
    }
    return isSuccess;
}


//update
- (void)updateRecord:(BaseModel <SQLModelRecordProtocol> *)record error:(NSError **)error {
    [self updateKeyValueList:[record dictionaryRepresentationWithTable:self] primaryKeyValue:[record valueForKey:[self primaryKeyName]] error:error];
}

- (void)updateRecordList:(NSArray <BaseModel <SQLModelRecordProtocol> *> *)recordList error:(NSError **)error {
    [recordList enumerateObjectsUsingBlock:^(BaseModel<SQLModelRecordProtocol> * _Nonnull record, NSUInteger idx, BOOL * _Nonnull stop) {
        [self updateRecord:record error:error];
        if(*error) {
            *stop = YES;
        }
    }];
}

- (void)updateValue:(id)value forKey:(NSString *)key whereCondition:(NSString *)whereCondition whereConditionParams:(NSDictionary *)whereConditionParams error:(NSError **)error {
    if(key && value) {
        [self updateKeyValueList:@{key : value} whereCondition:whereCondition whereConditionParams:whereConditionParams error:error];
    }
}

- (void)updateKeyValueList:(NSDictionary *)keyValueList whereCondition:(NSString *)whereCondition whereConditionParams:(NSDictionary *)whereConditionParams error:(NSError **)error {
    NSString *sqlString = [SQLStringModel updateTable:self.tableName withData:keyValueList condition:whereCondition conditionParams:whereConditionParams];
    NSLog(@"=======>[函数名:%s] sqlString = %@",__FUNCTION__, sqlString);
    [[DataBase shareDataBase] updateData:sqlString];
}

- (void)updateValue:(id)value forKey:(NSString *)key primaryKeyValue:(NSNumber *)primaryKeyValue error:(NSError **)error {
    if(key && value) {
        NSString *whereCondition = [NSString stringWithFormat:@"%@ = :primaryKeyValue",[self primaryKeyName]];
        NSDictionary *whereConditionParams = NSDictionaryOfVariableBindings(primaryKeyValue);
        [self updateKeyValueList:@{key:value} whereCondition:whereCondition whereConditionParams:whereConditionParams error:error];
    }
}

- (void)updateValue:(id)value forKey:(NSString *)key primaryKeyValueList:(NSArray <NSNumber *> *)primaryKeyValueList error:(NSError **)error {
    if(key && value) {
        NSString *primaryKeyValueListString = [primaryKeyValueList componentsJoinedByString:@","];
        NSString *whereCondition = [NSString stringWithFormat:@"%@ IN (:primaryKeyValueListString)",[self primaryKeyName]];
        NSDictionary *whereConditionParams = NSDictionaryOfVariableBindings(primaryKeyValueListString);
        [self updateKeyValueList:@{key:value} whereCondition:whereCondition whereConditionParams:whereConditionParams error:error];
    }
}

- (void)updateValue:(id)value forKey:(NSString *)key whereKey:(NSString *)wherekey inList:(NSArray *)keyList error:(NSError *__autoreleasing *)error {
    if (key && value && wherekey && keyList.count > 0) {
        NSString *keyListString = [keyList componentsJoinedByString:@","];
        NSString *whereCondition = [NSString stringWithFormat:@"%@ IN (:keyListString)", wherekey];
        NSDictionary *whereConditionParams = NSDictionaryOfVariableBindings(keyListString);
        [self updateKeyValueList:@{key:value} whereCondition:whereCondition whereConditionParams:whereConditionParams error:error];
    }
}

- (void)updateKeyValueList:(NSDictionary *)keyValueList primaryKeyValue:(NSNumber *)primaryKeyValue error:(NSError **)error {
    NSString *whereCondition = [NSString stringWithFormat:@"%@ = :primaryKeyValue", [self primaryKeyName]];
    NSDictionary *whereConditionParams = NSDictionaryOfVariableBindings(primaryKeyValue);
    [self updateKeyValueList:keyValueList whereCondition:whereCondition whereConditionParams:whereConditionParams error:error];
}

- (void)updateKeyValueList:(NSDictionary *)keyValueList primaryKeyValueList:(NSArray <NSNumber *> *)primaryKeyValueList error:(NSError **)error {
    NSString *primaryKeyValueListString = [primaryKeyValueList componentsJoinedByString:@","];
    NSString *whereCondition = [NSString stringWithFormat:@"%@ IN (:primaryKeyValueListString)", [self primaryKeyName]];
    NSDictionary *whereConditionParams = NSDictionaryOfVariableBindings(primaryKeyValueListString);
    [self updateKeyValueList:keyValueList whereCondition:whereCondition whereConditionParams:whereConditionParams error:error];
}


//delete
-(void)deleteAllRecordWithError:(NSError **)error {
    NSString *sqlString = [NSString stringWithFormat:@"DELETE FROM '%@'", [self tableName]];
    if(![[DataBase shareDataBase] deleteData:sqlString]) {
         *error = [NSError errorWithDomain:SQLOperationErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Excute sql: '%@' fail", sqlString]}];
    }
}

-(void)deleteRecord:(BaseModel <SQLModelRecordProtocol> *)record error:(NSError **)error {
    [self deleteWithPrimaryKey:[record valueForKey:[self primaryKeyName]] error:error];
}

-(void)deleteRecordList:(NSArray <BaseModel<SQLModelRecordProtocol> *> *)recordList error:(NSError **)error {
    NSMutableArray *primatKeyList = [[NSMutableArray alloc] init];
    [recordList enumerateObjectsUsingBlock:^(BaseModel<SQLModelRecordProtocol> * _Nonnull record, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *primaryKeyValue = [record valueForKey:[self primaryKeyName]];
        if (primaryKeyValue) {
            [primatKeyList addObject:primaryKeyValue];
        }
    }];
    [self deleteWithPrimaryKeyList:primatKeyList error:error];
}

-(void)deleteAllWithKeyName:(NSString *)keyname value:(id)value error:(NSError **)error {
    if(keyname && value) {
        NSString *whereCondition = [NSString stringWithFormat:@"%@ = :value", keyname];
        NSDictionary *whereConditionParams = NSDictionaryOfVariableBindings(value);
        [self deleteWithWhereCondition:whereCondition conditionParams:whereConditionParams error:error];
    }else {
        if(*error) {
            *error = [[NSError alloc] initWithDomain:SQLOperationErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"parameter is nil"}];
        }
    }
}

-(void)deleteWithWhereCondition:(NSString *)whereCondition conditionParams:(NSDictionary *)conditionParams error:(NSError **)error {
    NSString *sqlString = [SQLStringModel deleteTable:self.tableName withCondition:whereCondition conditionParams:conditionParams];
    NSLog(@"=======>[函数名:%s] sqlString = %@",__FUNCTION__,sqlString);
    if(![[DataBase shareDataBase] deleteData:sqlString]) {
        if(error) {
            *error = [NSError errorWithDomain:SQLOperationErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Excute sql: '%@' fail", sqlString]}];
        }
    }
}

- (void)deleteWithPrimaryKey:(NSNumber *)primaryKeyValue error:(NSError **)error {
    if(primaryKeyValue) {
        NSString *whereCondition = [NSString stringWithFormat:@"%@ = :primaryKeyValue",[self primaryKeyName]];
        NSDictionary *whereConditionParams = NSDictionaryOfVariableBindings(primaryKeyValue);
        NSString *sqlString = [SQLStringModel deleteTable:self.tableName withCondition:whereCondition conditionParams:whereConditionParams];
        NSLog(@"=======>[函数名:%s] sqlString = %@",__FUNCTION__,sqlString);
        if(![[DataBase shareDataBase] deleteData:sqlString]) {
            if(error) {
                *error = [NSError errorWithDomain:SQLOperationErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Excute sql: '%@' fail", sqlString]}];
            }
        }
    }
}

- (void)deleteWithPrimaryKeyList:(NSArray <NSNumber *> *)primaryKeyValueList error:(NSError **)error {
    if ([primaryKeyValueList count] > 0) {
        NSString *primaryKeyValueListString = [primaryKeyValueList componentsJoinedByString:@","];
        NSString *whereCondition = [NSString stringWithFormat:@"%@ IN (:primaryKeyValueListString)", [self primaryKeyName]];
        NSDictionary *whereConditionParams = NSDictionaryOfVariableBindings(primaryKeyValueListString);
        NSString *sqlString = [SQLStringModel deleteTable:self.tableName withCondition:whereCondition conditionParams:whereConditionParams];
        NSLog(@"=======>[函数名:%s] sqlString = %@",__FUNCTION__,sqlString);
        if(![[DataBase shareDataBase] deleteData:sqlString]) {
            if(error) {
                *error = [NSError errorWithDomain:SQLOperationErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Excute sql: '%@' fail", sqlString]}];
            }
        }

    }
}


//find
- (NSArray <BaseModel <SQLModelRecordProtocol> *> *)findAllWithError:(NSError **)error {
    NSString *sqlString1 = [SQLStringModel select:nil isDistinct:NO];
    NSString *sqlString2 = [SQLStringModel from:self.tableName];
    NSString *sqlString = [NSString stringWithFormat:@"%@%@",sqlString1, sqlString2];
    NSLog(@"=======>[函数名:%s] sqlString = %@",__FUNCTION__,sqlString);
    NSArray *array = [[DataBase shareDataBase] queryData:sqlString];
    return [self transformSQLItems:array toClass:[self recordClass]];

}

- (NSArray <BaseModel <SQLModelRecordProtocol> *> *)findAllWithWhereCondition:(NSString *)condition conditionParams:(NSDictionary *)conditionParams isDistinct:(BOOL)isDistinct error:(NSError **)error {
    
    NSString *sqlString1 = [SQLStringModel select:nil isDistinct:isDistinct];
    NSString *sqlString2 = [SQLStringModel from:self.tableName];
    NSString *sqlString3 = [SQLStringModel where:condition params:conditionParams];
    
    NSString *sqlString = [NSString stringWithFormat:@"%@%@%@",sqlString1, sqlString2, sqlString3];
    NSLog(@"=======>[函数名:%s] sqlString = %@",__FUNCTION__,sqlString);
    NSArray *array = [[DataBase shareDataBase] queryData:sqlString];
    return [self transformSQLItems:array toClass:[self recordClass]];
}



- (NSArray <BaseModel <SQLModelRecordProtocol> *> *)findAllWithWhereCondition:(NSString *)condition orderBy:(NSString *)orderKey error:(NSError **)error {
    
    NSString *sqlString1 = [SQLStringModel select:nil isDistinct:YES];
    NSString *sqlString2 = [SQLStringModel from:self.tableName];
    NSString *sqlString3 = [SQLStringModel where:condition params:nil];
    NSString *sqlString4 = [SQLStringModel orderBy:orderKey isDESC:YES];
    
    
    NSString *sqlString = [NSString stringWithFormat:@"%@%@%@%@",sqlString1, sqlString2, sqlString3,sqlString4];
    NSLog(@"=======>[函数名:%s] sqlString = %@",__FUNCTION__,sqlString);
    NSArray *array = [[DataBase shareDataBase] queryData:sqlString];
    return [self transformSQLItems:array toClass:[self recordClass]];
}


- (BaseModel <SQLModelRecordProtocol> *)findWithPrimaryKey:(NSNumber *)primaryKeyValue error:(NSError **)error {
    if (primaryKeyValue == nil) {
        if (error) {
            *error = [NSError errorWithDomain:@"primaryKeyValue is nil"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey:@"primaryKeyValue or primaryKeyValue is nil"}];
        }
        return nil;
    }
    
    NSString *whereCondition = [NSString stringWithFormat:@"%@ = :primaryKeyValue", [self primaryKeyName]];
    NSDictionary *whereConditionParams = NSDictionaryOfVariableBindings(primaryKeyValue);
    
    NSString *sqlString1 = [SQLStringModel select:nil isDistinct:NO];
    NSString *sqlString2 = [SQLStringModel from:self.tableName];
    NSString *sqlString3 = [SQLStringModel where:whereCondition params:whereConditionParams];
    NSString *sqlString = [NSString stringWithFormat:@"%@%@%@",sqlString1, sqlString2, sqlString3];
    NSLog(@"=======>[函数名:%s] sqlString = %@",__FUNCTION__,sqlString);
    NSArray *array = [[DataBase shareDataBase] queryData:sqlString];
    return [[self transformSQLItems:array toClass:[self recordClass]] firstObject];
}

- (NSArray <BaseModel <SQLModelRecordProtocol> *> *)findAllWithPrimaryKey:(NSArray <NSNumber *> *)primaryKeyValueList error:(NSError **)error {
    NSString *primaryKeyValueListString = [primaryKeyValueList componentsJoinedByString:@","];
    NSString *whereCondition = [NSString stringWithFormat:@"%@ IN (:primaryKeyValueListString)", [self primaryKeyName]];
    NSDictionary *whereConditionParams = NSDictionaryOfVariableBindings(primaryKeyValueListString);
   
    NSString *sqlString1 = [SQLStringModel select:nil isDistinct:NO];
    NSString *sqlString2 = [SQLStringModel from:self.tableName];
    NSString *sqlString3 = [SQLStringModel where:whereCondition params:whereConditionParams];
    NSString *sqlString = [NSString stringWithFormat:@"%@%@%@",sqlString1, sqlString2, sqlString3];
    NSLog(@"=======>[函数名:%s] sqlString = %@",__FUNCTION__,sqlString);
    NSArray *array = [[DataBase shareDataBase] queryData:sqlString];
    return [self transformSQLItems:array toClass:[self recordClass]];
}

- (NSArray <BaseModel <SQLModelRecordProtocol> *> *)findAllWithKeyName:(NSString *)keyname value:(id)value error:(NSError **)error {
    if(keyname && value) {
        NSString *whereCondition = [NSString stringWithFormat:@"%@ = :value", keyname];
        NSDictionary *whereConditionParams = NSDictionaryOfVariableBindings(value);
        NSString *sqlString1 = [SQLStringModel select:nil isDistinct:NO];
        NSString *sqlString2 = [SQLStringModel from:self.tableName];
        NSString *sqlString3 = [SQLStringModel where:whereCondition params:whereConditionParams];
        NSString *sqlString = [NSString stringWithFormat:@"%@%@%@",sqlString1, sqlString2, sqlString3];
        NSLog(@"=======>[函数名:%s] sqlString = %@",__FUNCTION__,sqlString);
        NSArray *array = [[DataBase shareDataBase] queryData:sqlString];
        return [self transformSQLItems:array toClass:[self recordClass]];
    }else {
        return nil;
    }
}

-(NSArray *)transformSQLItems:(NSArray *)array toClass:(Class)classType {
    NSMutableArray *recordList = [NSMutableArray array];
    if(array.count > 0) {
        [array enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull recordInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            id<SQLModelRecordProtocol> record = [[classType alloc] init];
            if ([record respondsToSelector:@selector(objectRepresentationWithDictionary:)]) {
                [record objectRepresentationWithDictionary:recordInfo];
                [recordList addObject:record];
            }
        }];
    }
    return recordList;
}

- (NSNumber *)countTotalRecord {
    NSString *sqlString = [NSString stringWithFormat:@"SELECT COUNT(*) as count FROM %@", self.tableName];
    long sum = [[DataBase shareDataBase] queryAllCount:sqlString];
    if(sum == -1) {
        return nil;
    }else {
        return @(sum);
    }
}

- (NSNumber *)countWithWhereCondition:(NSString *)whereCondition conditionParams:(NSDictionary *)conditionParams error:(NSError **)error {
    NSString *sqlString = @"SELECT COUNT(*) AS count FROM :tableName WHERE :whereString;";
    NSString *whereString = [whereCondition stringWithSQLParams:conditionParams];
    NSString *tableName = self.tableName;
    NSDictionary *params = NSDictionaryOfVariableBindings(whereString, tableName);
    
    NSString *finalString = [sqlString stringWithSQLParams:params];
    sqlString = [NSString stringWithFormat:@"%@%@",sqlString, finalString];
    
    long sum = [[DataBase shareDataBase] queryAllCount:sqlString];
    if(sum == -1) {
        return nil;
    }else {
        return @(sum);
    }
}


@end
