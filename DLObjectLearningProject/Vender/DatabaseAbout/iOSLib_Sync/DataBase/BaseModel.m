//
//  BaseModel.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "BaseModel.h"
#import "objc/runtime.h"
#import "BaseTable.h"
#import "Sync_Utils.h"

@implementation BaseModel

#pragma mark - SQLModelRecordProtocol
- (NSDictionary *)dictionaryRepresentationWithTable:(BaseTable<SQLModelTableProtocol> *)table
{
    unsigned int count = 0;
    
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    NSMutableDictionary *propertyList = [[NSMutableDictionary alloc] init];
    while (count-- > 0) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[count])];
        id value = [self valueForKey:key];
        if(value == nil) {
            propertyList[key] = [NSNull null];
        }else if([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]){
            NSData *data = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:nil];
            NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            propertyList[key] = jsonStr;
        } else {
             propertyList[key] = value;
        }
    }
    free(properties);
    
    NSMutableDictionary *dictionaryRepresentation = [[NSMutableDictionary alloc] init];
    
    [table.columnInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull columnName, NSString * _Nonnull columnDescription, BOOL * _Nonnull stop) {
        if (propertyList[columnName]) {
            dictionaryRepresentation[columnName] = propertyList[columnName];
        }
    }];
    return dictionaryRepresentation;
}



- (void)objectRepresentationWithDictionary:(NSDictionary *)dictionary
{
    unsigned int count;
    objc_property_t* props = class_copyPropertyList([self class], &count);
    for (int i = 0; i < count; i++) {
        objc_property_t property = props[i];
        NSString *key = [NSString stringWithUTF8String:property_getName(property)];
        NSString *propertyType = [self getPropertyType:property];
        if([propertyType containsString:@"NSArray"]) {
            NSString *jsonStr = dictionary[key];
            if(![Sync_Utils isEmptyString:jsonStr]) {
                NSData *data = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
                NSArray *array=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                [dictionary setValue:array.copy forKey:key];
            }else {
                [dictionary setValue:[NSNull null] forKey:key];
            }

        }else if([propertyType containsString:@"NSMutableArray"]) {
            NSString *jsonStr = dictionary[key];
            if(![Sync_Utils isEmptyString:jsonStr]) {
                NSData *data=[jsonStr dataUsingEncoding:NSUTF8StringEncoding];
                NSArray *array=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                [dictionary setValue:array.mutableCopy forKey:key];
            }else {
                [dictionary setValue:[NSNull null] forKey:key];
            }

        }else if([propertyType containsString:@"NSDictionary"]) {
            NSString *jsonStr = dictionary[key];
            if(![Sync_Utils isEmptyString:jsonStr]) {
                NSData *data=[jsonStr dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                [dictionary setValue:dic.copy forKey:key];
            }else {
                [dictionary setValue:[NSNull null] forKey:key];
            }
        }else if([propertyType containsString:@"NSMutableDictionary"]) {
            NSString *jsonStr = dictionary[key];
            if(![Sync_Utils isEmptyString:jsonStr]) {
                NSData *data=[jsonStr dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                [dictionary setValue:dic.mutableCopy forKey:key];
            }else {
                [dictionary setValue:[NSNull null] forKey:key];
            }
        }
    }
    
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        [self setPersistanceValue:value forKey:key];
    }];
}

- (BOOL)setPersistanceValue:(id)value forKey:(NSString *)key
{
    BOOL result = YES;
    NSString *setter = [NSString stringWithFormat:@"set%@%@:", [[key substringToIndex:1] capitalizedString], [key substringFromIndex:1]];
    if ([self respondsToSelector:NSSelectorFromString(setter)]) {
        if ([value isKindOfClass:[NSString class]]) {
            [self setValue:value forKey:key];
        } else if ([value isKindOfClass:[NSNull class]]) {
            [self setValue:nil forKey:key];
        } else {
            [self setValue:value forKey:key];
        }
    } else {
        result = NO;
    }
    return result;
}


-(NSString *)getPropertyType:(objc_property_t)property {
    const char * type = property_getAttributes(property);
    NSString *typeString = [NSString stringWithUTF8String:type];
    NSArray *attributes = [typeString componentsSeparatedByString:@","];
    NSString *typeAttributes = [attributes objectAtIndex:0];
    NSString *propertyType = [typeAttributes substringFromIndex:1];
    return propertyType;
    
   // const char *rawPropertyType = [propertyType UTF8String];
   // return rawPropertyType;
    
}



- (BaseModel<SQLModelRecordProtocol> *)mergeRecord:(BaseModel<SQLModelRecordProtocol> *)record shouldOverride:(BOOL)shouldOverride
{
    if ([self respondsToSelector:@selector(availableKeyList)]) {
        NSArray *availableKeyList = [self availableKeyList];
        [availableKeyList enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([record respondsToSelector:NSSelectorFromString(key)]) {
                id recordValue = [record valueForKey:key];
                if (shouldOverride) {
                    [self setPersistanceValue:recordValue forKey:key];
                } else {
                    id selfValue = [self valueForKey:key];
                    if (selfValue == nil) {
                        [self setPersistanceValue:recordValue forKey:key];
                    }
                }
            }
        }];
    }
    return self;
}

@end
