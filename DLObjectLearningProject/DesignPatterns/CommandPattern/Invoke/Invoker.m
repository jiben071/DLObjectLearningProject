//
//  Invoker.m
//  CommandPattern
//
//  Created by HEYANG on 15/11/25.
//  Copyright © 2015年 HEYANG. All rights reserved.
//

#import "Invoker.h"

@interface Invoker ()

/** 存储指令对象 */
@property (nonatomic,strong)NSMutableArray *commandArray;

@end

@implementation Invoker

implementationSingleton(Invoker);//因为需要记录命令记录，最好使用单利模式


-(NSMutableArray*)commandArray{
    if (_commandArray == nil) {
        NSLog(@"创建了一次NSMutableArray对象");
        _commandArray = [NSMutableArray array];
    }
    return _commandArray;
}

- (void)addExcute:(id<InvokerProtocol>)command{
    [command excute];
    NSLog(@"开始执行了");
    [self.commandArray addObject:command];
    NSLog(@"执行结束了");
}


-(void)rollBack{
    NSLog(@"撤销操作");
    [self.commandArray.lastObject rollBackExcute];
    [self.commandArray removeLastObject];
}
@end
