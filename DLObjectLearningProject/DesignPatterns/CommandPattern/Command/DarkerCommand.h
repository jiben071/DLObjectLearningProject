//
//  DarkerCommand.h
//  CommandPattern
//
//  Created by HEYANG on 15/11/25.
//  Copyright © 2015年 HEYANG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "InvokerProtocol.h"
@class Receiver;

@interface DarkerCommand : NSObject  <InvokerProtocol>

- (instancetype)initWithReceiver:(Receiver*)receiver withParamter:(CGFloat)paramter;

@end
