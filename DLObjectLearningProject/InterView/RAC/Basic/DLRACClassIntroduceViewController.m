//
//  DLRACClassIntroduceViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 08/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  概念介绍
//  http://blog.csdn.net/xdrt81y/article/details/30624469

#import "DLRACClassIntroduceViewController.h"
#import <ReactiveObjC/ReactiveObjC.h>

@interface DLRACClassIntroduceViewController ()
@property(nonatomic, strong) UIButton *createButton;
@property(nonatomic, strong) UITextField *userNameField;
@property(nonatomic, strong) UITextField *emailField;

@property(nonatomic, strong) UIButton *submitButton;
//@property(nonatomic, strong) UITextField *userNameField;
@property(nonatomic, strong) UITextField *passwordField;
@end

@implementation DLRACClassIntroduceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//ReactiveCocoa框架的每个组件

/*
 ReactiveCocoa框架概览
 
 可以把信号想象成水龙头，只不过里面不是水，而是玻璃球(value)，直径跟水管的内径一样，这样就能保证玻璃球是依次排列，不会出现并排的情况(数据都是线性处理的，不会出现并发情况)。水龙头的开关默认是关的，除非有了接收方(subscriber)，才会打开。这样只要有新的玻璃球进来，就会自动传送给接收方。可以在水龙头上加一个过滤嘴(filter)，不符合的不让通过，也可以加一个改动装置，把球改变成符合自己的需求(map)。也可以把多个水龙头合并成一个新的水龙头(combineLatest:reduce:)，这样只要其中的一个水龙头有玻璃球出来，这个新合并的水龙头就会得到这个球。
 */

/*
 Streams
 
 Streams 表现为RACStream类，可以看做是水管里面流动的一系列玻璃球，它们有顺序的依次通过，在第一个玻璃球没有到达之前，你没法获得第二个玻璃球。
 RACStream描述的就是这种线性流动玻璃球的形态，比较抽象，它本身的使用意义并不很大，一般会以signals或者sequences等这些更高层次的表现形态代替。
 */

/*
 Signals
 
 Signals 表现为RACSignal类，就是前面提到水龙头，ReactiveCocoa的核心概念就是Signal，它一般表示未来要到达的值，想象玻璃球一个个从水龙头里出来，只有了接收方（subscriber）才能获取到这些玻璃球（value）。
 
 Signal会发送下面三种事件给它的接受方（subscriber)，想象成水龙头有个指示灯来汇报它的工作状态，接受方通过-subscribeNext:error:completed:对不同事件作出相应反应
 
 next 从水龙头里流出的新玻璃球（value）
 error 获取新的玻璃球发生了错误，一般要发送一个NSError对象，表明哪里错了
 completed 全部玻璃球已经顺利抵达，没有更多的玻璃球加入了
 一个生命周期的Signal可以发送任意多个“next”事件，和一个“error”或者“completed”事件（当然“error”和“completed”只可能出现一种）
 */



/*
 Subjects
 
 subjects 表现为RACSubject类，可以认为是“可变的（mutable）”信号/自定义信号，它是嫁接非RAC代码到Signals世界的桥梁，很有用。嗯。。。 这样讲还是很抽象，举个例子吧：
 */

- (void)subjectTest{
    RACSubject *letters = [RACSubject subject];
    [letters sendNext:@"a"];//可以看到@"a"只是一个NSString对象，要想在水管里顺利流动，就要借RACSubject的力。
}

/*
Commands

command 表现为RACCommand类，偷个懒直接举个例子吧，比如一个简单的注册界面：
 */
- (void)commandTest{
    RACSignal *formValid=[RACSignal
                          combineLatest:@[
                                          self.userNameField.rac_textSignal,
                                          self.emailField.rac_textSignal,
                                          ]
                          reduce:^(NSString *userName,NSString *email){
                              return@(userName.length && email.length);
                          }];
    
    //错误，无法使用了
//    RACCommand *createAccountCommand=[RACCommand commandWithCanExecuteSignal:formValid];
    RACCommand *createAccountCommand = nil;
    
    /*
     //无法使用
    RACSignal *networkResults=[[[createAccountCommand
                                 addSignalBlock:^RACSignal *(id value){
                                     //... 网络交互代码
                                 }]
                                switchToLatest]
                               deliverOn:[RACScheduler mainThreadScheduler]];
     */
    
    // 绑定创建按钮的 UI state 和点击事件
    //无法使用
//    [[self.createButton.rac_signal ForControlEvents:UIControlEventTouchUpInside] executeCommand:createAccountCommand];
}

/*
 Sequences
 
 sequence 表现为RACSequence类，可以简单看做是RAC世界的NSArray，RAC增加了-rac_sequence方法，可以使诸如NSArray这些集合类（collection classes）直接转换为RACSequence来使用。
 */

/*
 Schedulers
 
 scheduler 表现为RACScheduler类，类似于GCD，but schedulers support cancellationbut schedulers support cancellation, and always execute serially.
 */

/*
 ReactiveCocoa的简单使用
 
 实践出真知，下面就举一些简单的例子，一起看看RAC的使用
 */

//Subscription
//接收 -subscribeNext: -subscribeError: -subscribeCompleted:
- (void)subscribeTest{
    RACSignal *letters = [@"A B C D E F G H I" componentsSeparatedByString:@" "].rac_sequence.signal;
    
    //依次输出A B C D...
    [letters subscribeNext:^(NSString *_Nullable x) {
        NSLog(@"%@",x);
    }];
}

/*
 Injecting effects
 
 注入效果 -doNext: -doError: -doCompleted:，看下面注释应该就明白了：
 */

- (void)injectingTest{
    __block unsigned subscriptions = 0;
    RACSignal *loggingSignal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        subscriptions++;
        [subscriber sendCompleted];
        return nil;
    }];
    
    //不会输出任何东西(注入效果)
    loggingSignal = [loggingSignal doCompleted:^{
        NSLog(@"about to complete subscription %u",subscriptions);
    }];
    
    // 输出:
    // about to complete subscription 1
    // subscription 1
    [loggingSignal subscribeCompleted:^{
        NSLog(@"subscription %u",subscriptions);
    }];
}

/*
 Mapping
 
 -map: 映射，可以看做对玻璃球的变换、重新组装
 */
- (void)mapTest{
    RACSequence *letters = [@"A B C D E F G H I" componentsSeparatedByString:@" "].rac_sequence;
    
    // Contains: AA BB CC DD EE FF GG HH II
    RACSequence *mapped = [letters map:^id _Nullable(NSString  *_Nullable value) {
        return [value stringByAppendingString:value];
    }];
    
    [mapped.signal subscribeNext:^(NSString  *_Nullable x) {
        NSLog(@"%@",x);
    }];
}

/*
 Filtering
 
 -filter: 过滤，不符合要求的玻璃球不允许通过
 */

- (void)filterTest{
    RACSequence *numbers = [@"1 2 3 4 5 6 7 8 9" componentsSeparatedByString:@" "].rac_sequence;
    //contains 2 4 6 8
    RACSequence *filtered = [numbers filter:^BOOL(NSString  *_Nullable value) {
        return (value.intValue % 2) == 0;
    }];
}

/*
 Concatenating
 
 -concat: 把一个水管拼接到另一个水管之后
 */
- (void)concatTest{
    RACSequence *letters = [@"A B C D E F G H I" componentsSeparatedByString:@" "].rac_sequence;
    RACSequence *numbers = [@"1 2 3 4 5 6 7 8 9" componentsSeparatedByString:@" "].rac_sequence;
    
    // Contains: A B C D E F G H I 1 2 3 4 5 6 7 8 9
    RACSequence *concatenated = [letters concat:numbers];
}

/*
 Flattening
 
 -flatten:
 
 Sequences are concatenated
 */
- (void)flattenTest{
    RACSequence *letters=[@"A B C D E F G H I"componentsSeparatedByString:@" "].rac_sequence;
    RACSequence *numbers=[@"1 2 3 4 5 6 7 8 9"componentsSeparatedByString:@" "].rac_sequence;
    RACSequence *sequenceOfSequences = @[letters,numbers].rac_sequence;
    
    // Contains: A B C D E F G H I 1 2 3 4 5 6 7 8 9
    RACSequence *flattened = [sequenceOfSequences flatten];
}

/*
 Signals are merged （merge可以理解成把几个水管的龙头合并成一个，哪个水管中的玻璃球哪个先到先吐哪个玻璃球）
 
 RACSubject到Rignal的使用
 */
- (void)signalToMerged{
    RACSubject *letters = [RACSubject subject];
    RACSubject *numbers = [RACSubject subject];
    RACSignal *signalOfSignals = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:letters];
        [subscriber sendNext:numbers];
        [subscriber sendCompleted];
        return nil;
    }];
    
    RACSignal *flattened = [signalOfSignals flatten];
    
    //Outputs: A 1 B C 2
    [flattened subscribeNext:^(NSString  *_Nullable x) {
        NSLog(@"%@",x);
    }];
    
    [letters sendNext:@"A"];
    [numbers sendNext:@"1"];
    [letters sendNext:@"B"];
    [letters sendNext:@"C"];
    [numbers sendNext:@"2"];
}

/*
 Mapping and flattening
 
 -flattenMap: 先 map 再 flatten
 */
- (void)flattenMapTest{
    RACSequence *numbers=[@"1 2 3 4 5 6 7 8 9" componentsSeparatedByString:@" "].rac_sequence;
    // Contains: 1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9
    RACSequence *extended = [numbers flattenMap:^__kindof RACSequence * _Nullable(NSString  *_Nullable value) {
        return @[value,value].rac_sequence;
    }];
    
    RACSequence *edited = [numbers flattenMap:^__kindof RACSequence * _Nullable(NSString  *_Nullable value) {
        if (value.intValue % 2 == 0) {
            return [RACSequence empty];
        }else{
            NSString *newNum = [value stringByAppendingString:@"_"];
            return [RACSequence return:newNum];
        }
    }];
    
    RACSignal *letters=[@"A B C D E F G H I"componentsSeparatedByString:@" "].rac_sequence.signal;
    [[letters flattenMap:^__kindof RACSignal * _Nullable(NSString  *_Nullable value) {
        return [self databasesaveEntriedForLetter:value];
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"All database entries saved successfully.");
    }];
}

- (RACSignal *)databasesaveEntriedForLetter:(NSString *)letter{
    return [RACSignal empty];
}

/*
 Sequencing
 
 -then:
 */
- (void)thenTest{
    RACSignal *letters = [@"A B C D E F G H I" componentsSeparatedByString:@" "].rac_sequence.signal;
    
    // 新水龙头只包含: 1 2 3 4 5 6 7 8 9
    // 但当有接收时，仍会执行旧水龙头doNext的内容，所以也会输出 A B C D E F G H I
    RACSignal *sequenced = [[letters doNext:^(id  _Nullable x) {//doNext：注入效果，执行next之前会先执行此block
        NSLog(@"%@",x);
    }]then:^RACSignal * _Nonnull{
        return [@"1 2 3 4 5 6 7 8 9" componentsSeparatedByString:@" "].rac_sequence.signal;
    }];
}

/*
 Merging
 
 +merge: 前面在flatten中提到的水龙头的合并
 */
- (void)mergeTest{
    RACSubject *letters = [RACSubject subject];
    RACSubject *numbers = [RACSubject subject];
    RACSignal *merged = [RACSignal merge:@[letters,numbers]];
    
    //Outputs:A 1 B C 2
    [merged subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    [letters sendNext:@"A"];
    [numbers sendNext:@"1"];
    [letters sendNext:@"B"];
    [letters sendNext:@"C"];
    [numbers sendNext:@"2"];
}

/*
 Combining latest values
 
 +combineLatest: 任何时刻取每个水龙头吐出的最新的那个玻璃球
 */
- (void)combiningTest{
    RACSubject *letters = [RACSubject subject];
    RACSubject *numbers = [RACSubject subject];
    RACSignal *combined = [RACSignal combineLatest:@[letters,numbers] reduce:^id (NSString *letter,NSString *number){
        return [letter stringByAppendingString:number];
    }];
    
    // Outputs: B1 B2 C2 C3
    [combined subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    [letters sendNext:@"A"];
    [letters sendNext:@"B"];
    [numbers sendNext:@"1"];
    [numbers sendNext:@"2"];
    [letters sendNext:@"C"];
    [numbers sendNext:@"3"];
}

/*
 Switching
 
 -switchToLatest: 取指定的那个水龙头的吐出的最新玻璃球
 */
- (void)switchTest{
    RACSubject *letters = [RACSubject subject];
    RACSubject *numbers = [RACSubject subject];
    RACSubject *signalOfSignals = [RACSubject subject];
    
    RACSignal *switched = [signalOfSignals switchToLatest];
    
    //Output: A B 1 D
    [switched subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    [signalOfSignals sendNext:letters];
    [letters sendNext:@"A"];
    [letters sendNext:@"B"];
    
    [signalOfSignals sendNext:numbers];
    [letters sendNext:@"C"];//switched没有接收
    [numbers sendNext:@"1"];
    
    [signalOfSignals sendNext:letters];
    [numbers sendNext:@"2"];//switched没有接收
    [letters sendNext:@"D"];
}

/*
 常用宏
 
 RAC 可以看作某个属性的值与一些信号的联动
 */
- (void)RACTest{
    RAC(self.submitButton,enabled) = [RACSignal combineLatest:@[self.userNameField.rac_textSignal,self.passwordField.rac_textSignal] reduce:^id (NSString *userName,NSString *password){
        return @(userName.length == 6 && password.length == 6 );
    }];
}

/*
 RACObserve 监听属性的改变，使用block的KVO
 */
- (void)kvoSetting{
    [RACObserve(self.userNameField, text) subscribeNext:^(NSString  *_Nullable x) {
        NSLog(@"%@",x);
    }];
}

/*
 UI Event
 
 RAC为系统UI提供了很多category，非常棒，比如UITextView、UITextField文本框的改动rac_textSignal，UIButton的的按下rac_command等等。
 */




@end
