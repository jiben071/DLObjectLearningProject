//
//  SyncClient.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "SyncClient.h"

@implementation SyncClient

-(void)add:(BaseModel<SQLModelRecordProtocol> *)item {
    if(self.table) {
        [self.table insertRecord:item error:nil];
    }
}

-(void)addList:(NSArray<BaseModel<SQLModelRecordProtocol> *> *)itemList {
    if(self.table) {
        [self.table insertRecordList:itemList error:nil];
    }
}

-(void)remove:(BaseModel<SQLModelRecordProtocol> *)item {
    if(self.table) {
        [self.table deleteRecord:item error:nil];
    }
}

-(void)removeModelwithKey:(NSString *)key value:(id)value {
    if(self.table) {
        [self.table deleteAllWithKeyName:key value:value error:nil];
    }
}

-(void)removeAllItem {
    if(self.table) {
        [self.table deleteAllRecordWithError:nil];
    }
}

-(void)update:(BaseModel<SQLModelRecordProtocol> *)item {
    if(self.table) {
        [self.table updateRecord:item error:nil];
    }
}

-(void)update:(BaseModel<SQLModelRecordProtocol> *)item withKeyValueList:(NSDictionary *)keyValueList {
    if(self.table) {
        [self.table updateKeyValueList:keyValueList primaryKeyValue:@(item.id_q) error:nil];
    }
}

-(NSArray *)getData {
    if(self.table) {
        return [self.table findAllWithError:nil];
    }else {
        return nil;
    }
}

-(NSArray *)getModelwithKey:(NSString *)key value:(id)value {
    if(self.table) {
        return [self.table findAllWithKeyName:key value:value error:nil];
    }else {
        return nil;
    }
}






@end
