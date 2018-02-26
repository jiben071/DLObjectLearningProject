//
//  DLRacTestViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 26/02/2018.
//  Copyright © 2018 long deng. All rights reserved.
//
/*
 ReactiveCocoa的主旨是让你的代码更简洁易懂，这值得多想想。我个人认为，如果逻辑可以用清晰的管道、流式语法来表示，那就很好理解这个应用到底干了什么了。
 */

#import "DLRacTestViewController.h"
#import "RWDummySignInService.h"
#import <ReactiveObjC/ReactiveObjC.h>
@interface DLRacTestViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

//@property (nonatomic) BOOL passwordIsValid;
//@property (nonatomic) BOOL usernameIsValid;
@property (strong, nonatomic) RWDummySignInService *signInService;
@end

@implementation DLRacTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self updateUIState];
    
    self.signInService = [RWDummySignInService new];
    
    // handle text changes for both text fields
    
    // initially hide the failure message
    self.signInFailureText.hidden = YES;
    
//    [self.usernameTextField.rac_textSignal subscribeNext:^(NSString * _Nullable x) {
//        NSLog(@"%@",x);
//    }];
    
//    [[self.usernameTextField.rac_textSignal filter:^BOOL(NSString * _Nullable value) {
//        return value.length > 3;
//    }] subscribeNext:^(NSString *_Nullable x) {
//        NSLog(@"%@",x);
//    }];
    
    /*
    RACSignal *usernameSourceSignal = self.usernameTextField.rac_textSignal;
    
    RACSignal *filteredUsername = [usernameSourceSignal filter:^BOOL(id  _Nullable value) {
        NSString *text = value;
        return text.length > 3;
    }];
    
    [filteredUsername subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
     */
    
    /*
    [[[self.usernameTextField.rac_textSignal map:^id _Nullable(NSString * _Nullable value) {
        return @(value.length);//改造成你想要的珠子
    }] filter:^BOOL(NSNumber *_Nullable length) {
        return [length integerValue] > 3;//过滤珠子
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
     */
    
    [self addSignalToTextField];
    [self bindActionFunction];
}

//用信号替代异步API  把一个异步API用信号封装
- (RACSignal *)signInSignal{
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [self.signInService signInWithUsername:self.usernameTextField.text password:self.passwordTextField.text complete:^(BOOL success) {
            [subscriber sendNext:@(success)];
            [subscriber sendCompleted];
        }];
        return nil;//这个block的返回值是一个RACDisposable对象，它允许你在一个订阅被取消时执行一些清理工作。当前的信号不需要执行清理操作，所以返回nil就可以了。
    }];
}

- (void)addSignalToTextField{
    RACSignal *validUsernameSignal = [self.usernameTextField.rac_textSignal map:^id _Nullable(NSString * _Nullable value) {
        return @([self isValidUsername:value]);
    }];
    
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id _Nullable(NSString * _Nullable value) {
        return @([self isValidPassword:value]);
    }];
    
    /*
     //如此使用不好
    [[validPasswordSignal map:^id _Nullable(NSNumber  * _Nullable value) {
        return [value boolValue]?[UIColor clearColor]:[UIColor yellowColor];
    }] subscribeNext:^(UIColor  *_Nullable x) {
        self.passwordTextField.background = x;
    }];
     */
    
    //RAC作用是可以直接应用返回结果
    RAC(self.passwordTextField,backgroundColor) = [validPasswordSignal map:^id _Nullable(NSNumber  * _Nullable value) {
        return [value boolValue]?[UIColor clearColor]:[UIColor yellowColor];
    }];
    
    RAC(self.usernameTextField,backgroundColor) = [validUsernameSignal map:^id _Nullable(NSNumber  * _Nullable value) {
        return [value boolValue]?[UIColor clearColor]:[UIColor yellowColor];
    }];
    
    //聚合信号
    RACSignal *signUpActiveSignal = [RACSignal combineLatest:@[validUsernameSignal,validPasswordSignal] reduce:^id (NSNumber *userNameValid,NSNumber *passwordValid){
        return @([userNameValid boolValue] && [passwordValid boolValue]);
    }];
    
    [signUpActiveSignal subscribeNext:^(NSNumber *  _Nullable signupActive) {
        self.signInButton.enabled = [signupActive boolValue];
    }];
    
}

- (void)bindActionFunction{
    [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside]
      doNext:^(__kindof UIControl * _Nullable x) {//添加附加操作 Adding side-effects
          /*
           注意：在异步操作执行的过程中禁用按钮是一个常见的问题，ReactiveCocoa也能很好的解决。RACCommand就包含这个概念，它有一个enabled信号，能让你把按钮的enabled属性和信号绑定起来。你也许想试试这个类。
           */
          self.signInButton.enabled = NO;
          self.signInFailureText.hidden = YES;
      }]
      flattenMap:^id _Nullable(__kindof UIControl * _Nullable value) {//信号中的信号 需要用flattenMap  这个操作把按钮点击事件转换为登录信号，同时还从内部信号发送事件到外部信号。
        return [self signInSignal];//将异步操作替换成信号流
    }]
     subscribeNext:^(NSNumber  *_Nullable signedIn) {
        NSLog(@"Sign in result: %@",signedIn);
         self.signInButton.enabled = YES;
        BOOL success = [signedIn boolValue];
        self.signInFailureText.hidden = success;
        if (success) {
            NSLog(@"登录成功");
        }else{
            NSLog(@"登录失败");
        }
    }];
}

- (BOOL)isValidUsername:(NSString *)username {
    return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
    return password.length > 3;
}

- (IBAction)signInButtonTouched:(id)sender {
    // disable all UI controls
    self.signInButton.enabled = NO;
    self.signInFailureText.hidden = YES;
    
    // sign in
    [self.signInService signInWithUsername:self.usernameTextField.text
                                  password:self.passwordTextField.text
                                  complete:^(BOOL success) {
                                      self.signInButton.enabled = YES;
                                      self.signInFailureText.hidden = success;
                                      if (success) {
//                                          [self performSegueWithIdentifier:@"signInSuccess" sender:self];
                                          NSLog(@"登录成功");
                                      }
                                  }];
}


// updates the enabled state and style of the text fields based on whether the current username
// and password combo is valid




@end
