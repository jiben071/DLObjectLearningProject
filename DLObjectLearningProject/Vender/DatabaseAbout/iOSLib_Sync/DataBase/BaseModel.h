//
//  BaseModel.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SQLModelRecordProtocol.h"

#define FROM_CLOUD @"cloud"
#define FROM_ROBOT @"robot"

@interface BaseModel : NSObject<SQLModelRecordProtocol>

@property (nonatomic, assign) NSUInteger id_q;


@end
