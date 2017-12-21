//
//  NSString+SQL.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SQL)

- (NSString *)stringWithSQLParams:(NSDictionary *)params;

@end
