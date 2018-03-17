//
//  DLRACExperienceViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 15/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import "DLRACExperienceViewController.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import <ReactiveObjC/RACReturnSignal.h>

@interface DLRACExperienceViewController ()
@property(nonatomic, assign) NSInteger currentPage;
@end

@implementation DLRACExperienceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)kvoSample{
//    @weakify(self)
    [[[[[RACObserve(self, currentPage)
        skip:1]
       distinctUntilChanged]
      throttle:0.15]//节流 这里添加 throttle， 表示在 0.15 秒内 值 没有改变时，才会进行请求
      takeUntil:self.rac_willDeallocSignal]
     subscribeNext:^(NSNumber  *_Nullable newValue) {
//        @strongify(self)
        NSLog(@"kvo监测到的页数：%@",newValue);
//        [self p_checkBottomToolState];
    }];
}

/*
- (void)yd_bindViewModel {
    RAC(self.titleLabel, text) = [[RACObserve(self, viewModel.title) distinctUntilChanged] takeUntil:self.rac_willDeallocSignal];
}
*/




@end
