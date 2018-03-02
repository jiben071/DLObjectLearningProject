//
//  NSObject+caculator.h
//  DLObjectLearningProject
//
//  Created by denglong on 02/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DLCaculatorMaker.h"

@interface NSObject (caculator)
+(CGFloat)makeCalculate:(void (^)(DLCaculatorMaker *maker))block;
@end
