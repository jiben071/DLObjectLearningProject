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



#pragma mark - bind测试
/*
 bind（绑定）的使用思想和Hook的一样——>都是拦截API从而可以对数据进行操作，从而影响返回数据。
 发送信号的时候回来到30行的block。在这个block里我们可以对数据进行一些操作，那么35行打印的value和订阅信号后的value就会变了。变成什么样随你喜欢
 */
- (void)bindTest{
    //1.创建信号
    RACSubject *subject = [RACSubject subject];
    //2.绑定信号
    RACSignal *bindSignal = [subject bind:^RACSignalBindBlock _Nonnull{
        //block调用时刻：只要绑定信号订阅就会调用。不做什么事情
        return ^RACSignal *(id value,BOOL *stop){
            //一般在这个block中做事，发数据的时候会来到这个block
            //只要源信号(subject)发送数据，就会调用block
            //block作用：处理源信号内容
            //value：源信号发送的内容
            value = @3;//如果在这里把value的值改了，那么订阅绑定信号的值即44行的x就变了
            NSLog(@"接受到源信号的内容：%@",value);
            //返回信号，不能为nil，如果非要返回空——则empty或alloc init
            return [RACReturnSignal return:value];
        };
    }];
    
    //3.订阅绑定信号
    [bindSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"接收到绑定信号处理完的信号：%@",x);
    }];
    //4.发送信号
    [subject sendNext:@"123"];
}

@end
