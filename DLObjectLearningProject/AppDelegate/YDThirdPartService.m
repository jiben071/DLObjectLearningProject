//
//  YDThirdPartService.m
//  YiDing
//
//  Created by 王隆帅 on 16/3/21.
//  Copyright © 2016年 王隆帅. All rights reserved.
//  作用目的：简化AppDelegate
//  https://www.jianshu.com/p/3beb21d5def2

#import "YDThirdPartService.h"

@implementation YDThirdPartService

+ (void)load {
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        [[self class] initCoredata];
        
        [[self class] ls_setKeyBord];
        
        [[self class] ls_testReachableStaus];
        
    });
}

#pragma mark - 初始化coredata
+ (void)initCoredata {
    
}

#pragma mark - 键盘回收相关
+ (void)ls_setKeyBord {
    
//    IQKeyboardManager *manager = [IQKeyboardManager sharedManager];
//    manager.enable = YES;
//    manager.shouldResignOnTouchOutside = YES;
//    manager.shouldToolbarUsesTextFieldTintColor = YES;
//    manager.enableAutoToolbar = YES;
}

#pragma mark － 检测网络相关
+ (void)ls_testReachableStaus {
        
}

@end
