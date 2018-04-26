//
//  InvokerProtocol.h
//  CommandPattern
//
//  Created by HEYANG on 15/11/25.
//  Copyright © 2015年 HEYANG. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol InvokerProtocol <NSObject>
/*
 * 这个协议是Invoker调用者要求的协议，希望遵循这个协议的类，实现了必须要实现的两个方法
 * 因为这两个方法，在Invoker中一定会被调用
 */

@required

/**
 *  命令的执行
 */
- (void)excute;

/**
 *  撤销命令
 */
- (void)rollBackExcute;



@end
