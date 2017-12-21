//
//  BatchTask.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/13.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimpleTask.h"
#import "Result.h"

typedef void(^BatchCallback)(NSArray<Result *> *results, int code);

@interface BatchTask : NSObject

+(instancetype)shareBatchTask;

-(void)startTask:(NSArray<SimpleTask *>*)taskArray withCallback:(BatchCallback)callback;

@end
