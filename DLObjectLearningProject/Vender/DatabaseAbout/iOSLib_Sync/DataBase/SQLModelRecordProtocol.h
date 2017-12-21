//
//  SQLModelRecordProtocol.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#ifndef SQLModelRecordProtocol_h
#define SQLModelRecordProtocol_h

@class SyncClient;
@protocol SQLModelRecordProtocol <NSObject>

@required
- (NSDictionary *)dictionaryRepresentationWithTable:(SyncClient <SQLModelRecordProtocol> *)table;

- (void)objectRepresentationWithDictionary:(NSDictionary *)dictionary;

- (BOOL)setPersistanceValue:(id)value forKey:(NSString *)key;

- (NSObject <SQLModelRecordProtocol> *)mergeRecord:(NSObject <SQLModelRecordProtocol> *)record shouldOverride:(BOOL)shouldOverride;

@optional
- (NSArray *)availableKeyList;

@end


#endif /* SQLModelRecordProtocol_h */
