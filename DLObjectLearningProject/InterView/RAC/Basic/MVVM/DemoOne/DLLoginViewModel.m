//
//  DLLoginViewModel.m
//  DLObjectLearningProject
//
//  Created by denglong on 01/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import "DLLoginViewModel.h"

@implementation DLLoginViewModel
- (DLAccount *)account{
    if (!_account) {
        _account = [[DLAccount alloc] init];
    }
    return _account;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initailBind];
    }
    return self;
}
//初始化绑定
- (void)initailBind{
    //监听账号的属性值变化，把他们聚合成一个信号
    _enableLoginSignal = [RACSignal combineLatest:@[RACObserve(self.account, account),RACObserve(self.account, pwd)] reduce:^id (NSString *account,NSString *pwd){
        return @(account.length && pwd.length);
    }];
    
    //处理登录业务逻辑
    _loginCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        NSLog(@"点击了登录");
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            //模仿网络延迟
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [subscriber sendNext:@"登录成功"];
                //数据传递完毕，必须调用完成，否则命令用于处于执行状态
                [subscriber sendCompleted];
            });
            return nil;
        }];
    }];
    
    //监听登录产生的数据
    [_loginCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        if ([x isEqualToString:@"登录成功"]) {
            NSLog(@"登录成功");
        }
    }];
    
    //监听登录状态
    [[_loginCommand.executing skip:1] subscribeNext:^(NSNumber * _Nullable x) {
        if ([x isEqualToNumber:@(YES)]) {
            //正在登录ing...
        }else{
            //登录成功
        }
    }];
}
@end
