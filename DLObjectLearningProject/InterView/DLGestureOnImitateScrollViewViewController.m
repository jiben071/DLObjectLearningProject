//
//  DLGestureOnImitateScrollViewViewController.m
//  DLObjectLearningProject
//
//  Created by long deng on 2017/12/20.
//  Copyright © 2017年 long deng. All rights reserved.
//  这里主要是解决手势冲突的问题

#import "DLGestureOnImitateScrollViewViewController.h"

@interface DLGestureOnImitateScrollViewViewController ()<UIGestureRecognizerDelegate>

@end

@implementation DLGestureOnImitateScrollViewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



//作用：可以在这里解决手势冲突
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}





@end
