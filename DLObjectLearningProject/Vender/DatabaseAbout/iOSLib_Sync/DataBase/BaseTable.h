//
//  BaseTable.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQLModelRecordProtocol.h"
#import "BaseModel.h"

static NSString * const SQLOperationErrorDomain = @"com.iOSLibSync.SqlErrorDomain";

@protocol SQLModelTableProtocol <NSObject>

- (NSString *)tableName;

- (NSDictionary *)columnInfo;

- (Class)recordClass;

- (NSString *)primaryKeyName;

@end

@interface BaseTable : NSObject<SQLModelTableProtocol>

//create table
-(instancetype)init;

//insert
- (BOOL)insertRecordList:(NSArray <BaseModel <SQLModelRecordProtocol> *> *)recordList error:(NSError **)error;

- (BOOL)insertRecord:(BaseModel <SQLModelRecordProtocol> *)record error:(NSError **)error;


//update
- (void)updateRecord:(BaseModel <SQLModelRecordProtocol> *)record error:(NSError **)error;

- (void)updateRecordList:(NSArray <BaseModel <SQLModelRecordProtocol> *> *)recordList error:(NSError **)error;

- (void)updateValue:(id)value forKey:(NSString *)key whereCondition:(NSString *)whereCondition whereConditionParams:(NSDictionary *)whereConditionParams error:(NSError **)error;

- (void)updateKeyValueList:(NSDictionary *)keyValueList whereCondition:(NSString *)whereCondition whereConditionParams:(NSDictionary *)whereConditionParams error:(NSError **)error;

- (void)updateValue:(id)value forKey:(NSString *)key primaryKeyValue:(NSNumber *)primaryKeyValue error:(NSError **)error;

- (void)updateValue:(id)value forKey:(NSString *)key primaryKeyValueList:(NSArray <NSNumber *> *)primaryKeyValueList error:(NSError **)error;

- (void)updateValue:(id)value forKey:(NSString *)key whereKey:(NSString *)wherekey inList:(NSArray *)keyList error:(NSError *__autoreleasing *)error;

- (void)updateKeyValueList:(NSDictionary *)keyValueList primaryKeyValue:(NSNumber *)primaryKeyValue error:(NSError **)error;

- (void)updateKeyValueList:(NSDictionary *)keyValueList primaryKeyValueList:(NSArray <NSNumber *> *)primaryKeyValueList error:(NSError **)error;


//delete
-(void)deleteAllRecordWithError:(NSError **)error;

-(void)deleteRecord:(BaseModel <SQLModelRecordProtocol> *)record error:(NSError **)error;

-(void)deleteRecordList:(NSArray <BaseModel<SQLModelRecordProtocol> *> *)recordList error:(NSError **)error;

-(void)deleteAllWithKeyName:(NSString *)keyname value:(id)value error:(NSError **)error;

-(void)deleteWithWhereCondition:(NSString *)whereCondition conditionParams:(NSDictionary *)conditionParams error:(NSError **)error;

- (void)deleteWithPrimaryKey:(NSNumber *)primaryKeyValue error:(NSError **)error;

- (void)deleteWithPrimaryKeyList:(NSArray <NSNumber *> *)primaryKeyValueList error:(NSError **)error;


//find
- (NSArray <BaseModel <SQLModelRecordProtocol> *> *)findAllWithError:(NSError **)error;

- (NSArray <BaseModel <SQLModelRecordProtocol> *> *)findAllWithWhereCondition:(NSString *)condition conditionParams:(NSDictionary *)conditionParams isDistinct:(BOOL)isDistinct error:(NSError **)error;

- (NSArray <BaseModel <SQLModelRecordProtocol> *> *)findAllWithWhereCondition:(NSString *)condition orderBy:(NSString *)orderKey error:(NSError **)error;

- (BaseModel <SQLModelRecordProtocol> *)findWithPrimaryKey:(NSNumber *)primaryKeyValue error:(NSError **)error;

- (NSArray <BaseModel <SQLModelRecordProtocol> *> *)findAllWithPrimaryKey:(NSArray <NSNumber *> *)primaryKeyValueList error:(NSError **)error;

- (NSArray <BaseModel <SQLModelRecordProtocol> *> *)findAllWithKeyName:(NSString *)keyname value:(id)value error:(NSError **)error;

- (NSNumber *)countTotalRecord;

- (NSNumber *)countWithWhereCondition:(NSString *)whereCondition conditionParams:(NSDictionary *)conditionParams error:(NSError **)error;


@end
