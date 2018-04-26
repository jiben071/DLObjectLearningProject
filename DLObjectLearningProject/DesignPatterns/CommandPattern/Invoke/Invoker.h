//
//  Invoker.h
//  CommandPattern
//
//  Created by HEYANG on 15/11/25.
//  Copyright © 2015年 HEYANG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Singleton.h"

#import "CommandHelper.h"


@interface Invoker : NSObject

interfaceSingleton(Invoker);

/**
 *  添加指令操作
 *
 *  @param command 指令
 */
- (void)addExcute:(id<InvokerProtocol>)command;

/**
 *  回退操作
 */
-(void)rollBack;
@end
