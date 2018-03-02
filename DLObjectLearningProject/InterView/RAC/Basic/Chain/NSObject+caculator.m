//
//  NSObject+caculator.m
//  DLObjectLearningProject
//
//  Created by denglong on 02/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import "NSObject+caculator.h"

@implementation NSObject (caculator)
+ (CGFloat)makeCalculate:(void (^)(DLCaculatorMaker *maker))block{
    //1.创建计算器管理者
    DLCaculatorMaker *makerObj = [[DLCaculatorMaker alloc] init];
    block(makerObj);//执行计算过程
    return makerObj.result;
}
@end
