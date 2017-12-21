//
//  SubScriber.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/4.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^HandleCallBack)(id responseObj);

@interface SubScriber : NSObject

@property (nonatomic, copy)HandleCallBack handle;

@end
