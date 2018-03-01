//
//  DLLoginViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 01/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import "DLLoginViewController.h"

@interface DLLoginViewController ()

@end

@implementation DLLoginViewController
- (DLLoginViewModel *)loginViewModel{
    if (!_loginViewModel) {
        _loginViewModel = [[DLLoginViewModel alloc] init];
    }
    return _loginViewModel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

//视图模型绑定
- (void)bindModel{
    //给模型的属性绑定信号
    //只要账号文本框一改变，就会给account赋值
    RAC(self.loginViewModel.account,account) = _accountField.rac_textSignal;
    RAC(self.loginViewModel.account,pwd) = _pwdField.rac_textSignal;
    
    //绑定登录按钮
    RAC(self.loginBtn,enabled) = self.loginViewModel.enableLoginSignal;
    //监听登录按钮点击
    [[_loginBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        //执行登录事件
        [self.loginViewModel.loginCommand execute:nil];
    }];
}

@end
