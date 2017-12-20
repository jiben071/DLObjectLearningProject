//
//  DLFatherObject.m
//  DLObjectLearningProject
//
//  Created by long deng on 2017/12/19.
//  Copyright © 2017年 long deng. All rights reserved.
//  探索私有属性是如何访问的

#import "DLFatherObject.h"

@interface DLFatherObject()
@property (nonatomic,copy) NSString *name;/**< 名字 */
@end

@implementation DLFatherObject
- (NSString *)description{
    return [NSString stringWithFormat:@"name:%@",_name];
}
@end
