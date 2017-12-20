//
//  DLPrivatePropertyVisitedViewController.m
//  DLObjectLearningProject
//
//  Created by long deng on 2017/12/19.
//  Copyright © 2017年 long deng. All rights reserved.
//  运行时探究  获取私有变量

/*运行时的作用
 能获得某个类的所有成员变量
 能获得某个类的所有属性
 能获得某个类的所有方法
 交换方法实现
 能动态添加一个成员变量
 能动态添加一个属性
 能动态添加一个方法
 参考：http://www.jianshu.com/p/59992507f875
 */

#import "DLPrivatePropertyVisitedViewController.h"
#import <objc/runtime.h>
#import "DLFatherObject.h"

@interface DLPrivatePropertyVisitedViewController ()

@end

@implementation DLPrivatePropertyVisitedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    DLFatherObject *father = [DLFatherObject new];
    //count 记录变量的数量  IVar是runtime声明的一个宏
    unsigned int count = 0;
    
    //获取类的所有属性变量
    Ivar *members = class_copyIvarList([DLFatherObject class], &count);
    for (int i = 0; i < count; i++) {
        Ivar ivar = members[i];
        //将IVar变量转化为字符串，这里获得了属性名
        const char *memberName = ivar_getName(ivar);
        NSLog(@"属性名：%s",memberName);
        
        Ivar m_name = members[0];
        //修改属性值
        object_setIvar(father, m_name, @"张三");
        NSLog(@"%@", father);
    }
    
}

@end
