//
//  SyncClient.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseTable.h"

#import "BaseModel.h"

typedef NS_ENUM(NSUInteger, SyncContext) {
    CONTEXT_ROBOT = 1,
    CONTEXT_MODIFY = 2,
    CONTEXT_CLOUD = 3,
};

@interface SyncClient : NSObject

@property (nonatomic, strong)BaseTable *table;


-(void)add:(BaseModel<SQLModelRecordProtocol> *)item;

-(void)addList:(NSArray<BaseModel<SQLModelRecordProtocol> *> *)itemList;

-(void)removeAllItem;

-(void)remove:(BaseModel<SQLModelRecordProtocol> *)item;

-(void)removeModelwithKey:(NSString *)key value:(id)value;

-(void)update:(BaseModel<SQLModelRecordProtocol> *)item;

-(void)update:(BaseModel<SQLModelRecordProtocol> *)item withKeyValueList:(NSDictionary *)keyValueList;

-(NSArray *)getData;

-(NSArray *)getModelwithKey:(NSString *)key value:(id)value;

- (void)getObject;


@end
