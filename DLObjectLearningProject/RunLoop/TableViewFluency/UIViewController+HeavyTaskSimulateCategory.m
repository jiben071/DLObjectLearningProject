//
//  UIViewController+HeavyTaskSimulateCategory.m
//  DLObjectLearningProject
//
//  Created by denglong on 21/12/2017.
//  Copyright © 2017 long deng. All rights reserved.
//

#import "UIViewController+HeavyTaskSimulateCategory.h"

@implementation UIViewController (HeavyTaskSimulateCategory)
+ (void)task_5:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    NSLog(@"任务五的runloop模式：%@",[NSRunLoop currentRunLoop].currentMode);
    for (NSInteger i = 1; i <= 5; i++) {
        [[cell.contentView viewWithTag:i] removeFromSuperview];
    }
}

+ (void)task_1:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    NSLog(@"任务一的runloop模式：%@",[NSRunLoop currentRunLoop].currentMode);
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 300, 25)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor redColor];
    label.text = [NSString stringWithFormat:@"%zd - Drawing index is top priority", indexPath.row];
    label.font = [UIFont boldSystemFontOfSize:13];
    label.tag = 1;
    [cell.contentView addSubview:label];
}

+ (void)task_2:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath  {
    NSLog(@"任务二的runloop模式：%@",[NSRunLoop currentRunLoop].currentMode);
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(105, 20, 85, 85)];
    imageView.tag = 2;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"spaceship" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = image;
    [UIView transitionWithView:cell.contentView duration:0.3 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [cell.contentView addSubview:imageView];
    } completion:^(BOOL finished) {
    }];
}

+ (void)task_3:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath  {
    NSLog(@"任务三的runloop模式：%@",[NSRunLoop currentRunLoop].currentMode);
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(200, 20, 85, 85)];
    imageView.tag = 3;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"spaceship" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = image;
    [UIView transitionWithView:cell.contentView duration:0.3 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [cell.contentView addSubview:imageView];
    } completion:^(BOOL finished) {
    }];
}

+ (void)task_4:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath  {
    NSLog(@"任务四的runloop模式：%@",[NSRunLoop currentRunLoop].currentMode);
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 99, 300, 35)];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor colorWithRed:0 green:100.f/255.f blue:0 alpha:1];
    label.text = [NSString stringWithFormat:@"%zd - Drawing large image is low priority. Should be distributed into different run loop passes.", indexPath.row];
    label.font = [UIFont boldSystemFontOfSize:13];
    label.tag = 4;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 20, 85, 85)];
    imageView.tag = 5;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"spaceship" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = image;
    [UIView transitionWithView:cell.contentView duration:0.3 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [cell.contentView addSubview:label];
        [cell.contentView addSubview:imageView];
    } completion:^(BOOL finished) {
    }];
}
@end
