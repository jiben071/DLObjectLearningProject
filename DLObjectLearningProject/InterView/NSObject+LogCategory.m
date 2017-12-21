//
//  NSObject+LogCategory.m
//  DLObjectLearningProject
//
//  Created by long deng on 2017/12/20.
//  Copyright © 2017年 long deng. All rights reserved.
//  完成自定义打印Log，核心在于方法交换

#import "NSObject+LogCategory.h"
#import <objc/runtime.h>

@implementation NSObject (LogCategory)
+ (NSString *)myLog{
    // 这里写打印行号,什么方法,哪个类调用等等
    return @"";
}

+ (void)load{
    Method description = class_getClassMethod(self, @selector(description));
    
    Method myLog = class_getClassMethod(self, @selector(myLog));
    
    method_exchangeImplementations(description, myLog);
}


//让分类支持属性
// 定义关联的key
static const char *key = "name";
- (NSString *)name{
    // 根据关联的key，获取关联的值。
    return objc_getAssociatedObject(self, key);
}
- (void)setName:(NSString *)name{
    // 第一个参数：给哪个对象添加关联
    // 第二个参数：关联的key，通过这个key获取
    // 第三个参数：关联的value
    // 第四个参数:关联的策略
    objc_setAssociatedObject(self, key, name, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}



@end
