//
//  DLRACSampleViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 14/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  ReactiveObjC使用
//  https://www.cnblogs.com/CoderEYLee/p/6640503.html

#import "DLRACSampleViewController.h"
#import <ReactiveObjC/ReactiveObjC.h>

@interface DLRACSampleViewController ()
@property(nonatomic, strong) UIButton *button;
@property(nonatomic, strong) UIView *redView;
@property(nonatomic, strong) UITextField *textField;
@property(nonatomic, strong) UILabel *textLabel;
@property(nonatomic, strong) UIButton *loginButton;
@property(nonatomic, strong) UITextField *userName;
@property(nonatomic, strong) UITextField *password;
@end

@implementation DLRACSampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - 监听事件（按钮点击）
/*
 原理：将系统的UIControlEventTouchUpInside事件转化为信号、我们只需要订阅该信号就可以了。
 点击按钮的时候触发UIControlEventTouchUpInside事件---> 发出信号 实际是:  执行订阅者(subscriber)的sendNext方法
 */
- (void)clickTest{
    //外界引用
    [[self.button rac_signalForSelector:UIControlEventTouchUpInside] subscribeNext:^(RACTuple * _Nullable x) {
        //x 就是被点击的按钮
        NSLog(@"按钮被点击了%@", x);
    }];
}

#pragma mark - 代替代理
/*
 需求：自定义redView,监听红色view中按钮点击
 之前都是需要通过代理监听，给红色View添加一个代理属性，点击按钮的时候，通知代理做事情,符合封装的思想。
 rac_signalForSelector:把调用某个对象的方法的信息转换成信号(RACSubject)，就会调用这个方法，就会发送信号。
 这里表示只要监听了redView的btnClick:方法。(只要redView的btnClick:方法执行了,就会执行下面的方法,并且将参数传递过来)
 */
- (void)delegateTest{
    
    [[self.redView rac_signalForSelector:@selector(btnClick:)] subscribeNext:^(id x) {
        NSLog(@"点击红色视图中的按钮", x);
    }];
}

#pragma mark - 代替KVO
// 把监听redView的center属性改变转换成信号，只要值改变就会发送信号
// observer:可以传入nil
- (void)kvoTest{
    [[self.redView rac_valuesAndChangesForKeyPath:@"center" options:NSKeyValueObservingOptionNew observer:nil] subscribeNext:^(RACTwoTuple<id,NSDictionary *> * _Nullable x) {
        NSLog(@"%@",x);
    }];
}

#pragma mark - 代替通知
// 把监听到的通知转换信号
- (void)notificationTest{
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillShowNotification object:nil] takeUntil:[self rac_willDeallocSignal]] subscribeNext:^(NSNotification * _Nullable x) {
        NSLog(@"%@", x);
    }];
}

#pragma mark - 监听文本框的文字变化
//监听文本框的文字变化，获取文本框文字改变的信号
- (void)textChangedTest{
    [self.textField.rac_textSignal subscribeNext:^(NSString * _Nullable x) {
        self.textLabel.text = x;
        NSLog(@"文字改变了%@",x);
    }];
}

#pragma mark - 处理多个请求
- (void)multiRequestHandle{
    //处理多个请求，都返回结果的时候，统一做处理
    RACSignal *request1 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //发送请求1
        [subscriber sendNext:@"发送请求1"];
        return nil;
    }];
    
    RACSignal *request2 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //发送请求2
        [subscriber sendNext:@"发送请求2"];
        return nil;
    }];
    
    //使用注意：几个信号，selector的方法就几个参数，每个参数对应信号发出的数据
    //不需要订阅:不需要主动订阅,内部会主动订阅
    [self rac_liftSelector:@selector(updateUIWithR1:r2:) withSignalsFromArray:@[request1,request2]];
}

// 更新UI
- (void)updateUIWithR1:(id)data r2:(id)data1{
    NSLog(@"更新UI%@ %@",data,data1);
}

#pragma mark - 遍历数组
// 这里其实是三步(底层已经封装好了,直接使用就行)
// 第一步: 把数组转换成集合RACSequence numbers.rac_sequence
// 第二步: 把集合RACSequence转换RACSignal信号类,numbers.rac_sequence.signal
// 第三步: 订阅信号，激活信号，会自动把集合中的所有值，遍历出来。
- (void)arrayTest{
    // 1.遍历数组
    NSArray *numbers = @[@1,@2,@3,@4];
    [numbers.rac_sequence.signal subscribeNext:^(id  _Nullable x) {
        
    }];
}

#pragma mark - 常用宏
- (void)macroTest{
    /*
     RACObserve(就是一个宏定义):快速的监听某个对象的某个属性改变
     监听self.view的center属性,当center发生改变的时候就会触发NSLog方法
     */
    [RACObserve(self.view, center) subscribeNext:^(id  _Nullable x) {
        
    }];
    
    //登录按钮的状态实时监听
    RAC(self.loginButton,enabled) = [RACSignal combineLatest:@[_userName.rac_textSignal,_password.rac_textSignal] reduce:^id (NSString *userName,NSString *password){
        return @(userName.length && password.length);
    }];
    
    //循环引用
    // @weakify() 宏定义
    @weakify(self) //相当于__weak typeof(self) weakSelf = self;
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self)  //相当于__strong typeof(weakSelf) strongSelf = weakSelf;
        NSLog(@"%@",self.view);
        return nil;
    }];
//    _signal = signal;
}

/*
 实际开发遇到的坑
 
 一: "引用循环"是肯定会出现的,因此一定要避免"强引用循环"
 
 解决方案:一端使用strong一端使用weak
 */

/*
 出现的错误：Terminating app due to uncaught exception 'NSInvalidArgumentException',reason:[__NSPlaceholderArray initWithObjects:count:]:attempt to insert nil object from objects[7]
 
 
 解决办法:所有控件在使用RAC之前一定要先初始化!先初始化!先初始化!
 （Masonry框架：布局之前一定要添加到父控件中）有相似之处
 */


@end
