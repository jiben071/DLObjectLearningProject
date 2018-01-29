//
//  HSClockView.h
//  ClockDemo
//
//  Created by 胡 帅 on 16/3/18.
//  Copyright © 2016年 Disney. All rights reserved.
//  http://www.cnblogs.com/hushuai-ios/p/5295542.html
//  核心：其它的解决方案都是使用锚点：https://zsisme.gitbooks.io/ios-/content/chapter3/anchor.html
//  它的解决方案是使用三维仿射矩阵变换，“指针弧度角到仿射矩阵的变换”，这里推导出公式最为重要

#import <UIKit/UIKit.h>


@protocol HSClockViewProtocol <NSObject>
/**
 *  一个时钟与外界的通信，就是它的时间。
 *  要有setter/getter, KVO-compliance
 */
@property (nonatomic, assign) NSTimeInterval time;

/**
 *  暂停时钟运行
 */
- (void) pause;
/**
 *  继续或者开始时钟运行
 */
- (void) work;
/**
 *  根据最近一次时间设置，未设置过则使用系统时间
 *  校准设备延迟
 */
- (void) calibrate;

/**
 *  设置表盘背景图
 *
 *  @param image 表盘背景图，UIImage对象
 */
- (void) setDialBackgroundImage:(UIImage *) image;

@end


@interface HSClockView : UIView<HSClockViewProtocol>

@property (nonatomic, assign) NSTimeInterval time;

@end
