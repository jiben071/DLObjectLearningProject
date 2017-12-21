//
//  RobotPushTask.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/13.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "SimpleTask.h"

@interface RobotPushTask : SimpleTask

-(void)start:(void(^)(Result *result, int code))callback;

@end
