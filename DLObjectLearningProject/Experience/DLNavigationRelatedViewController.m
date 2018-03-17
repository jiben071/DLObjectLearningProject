//
//  DLNavigationRelatedViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 17/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import "DLNavigationRelatedViewController.h"

@interface DLNavigationRelatedViewController ()

@end

@implementation DLNavigationRelatedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//1.在导航的中途插入另外一个控制器，完成跳转流程控制器的增减
#pragma mark - 将提醒打开蓝牙的提示界面插入到蓝牙联网流程里面
- (void)insertBlueToothVC{
    UIViewController *openVC = [[UIViewController alloc] init];
    NSArray *array = self.navigationController.viewControllers;
    NSMutableArray *arr = [NSMutableArray arrayWithArray:array];
    
    BOOL hasOpenVC = NO;
    for (UIViewController *vc in array) {
        if ([vc isMemberOfClass:[UIViewController class]]) {
            hasOpenVC = YES;
            break;
        }
    }
    if (!hasOpenVC) {
        [arr insertObject:openVC atIndex:arr.count - 1];
    }
    
    self.navigationController.viewControllers = arr;
}

@end
