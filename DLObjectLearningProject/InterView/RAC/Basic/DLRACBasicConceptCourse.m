//
//  DLRACBasicConceptCourse.m
//  DLObjectLearningProject
//
//  Created by denglong on 02/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  http://bbs.520it.com/forum.php?mod=viewthread&tid=253
//  最快让你上手ReactiveCocoa之基础篇

#import "DLRACBasicConceptCourse.h"
#import <UIKit/UIKit.h>
#import "NSObject+caculator.h"
#import "DLCaculator.h"
#import <ReactiveObjC/ReactiveObjC.h>

@interface FlagItem:NSObject
+ (instancetype)flagWithDict:(NSDictionary *)dict;
@end
@implementation FlagItem
@end

@interface DLRedView:UIView
@property(nonatomic, weak) UIButton *btn;
@property(nonatomic, weak) UITextField *textField;
- (void)btnClick;
@end
@implementation DLRedView
@end


/*
 比如按钮的点击使用action，ScrollView滚动使用delegate，属性值改变使用KVO等系统提供的方式。
 其实这些事件，都可以通过RAC处理
 ReactiveCocoa为事件提供了很多处理方法，而且利用RAC处理事件很方便，可以把要处理的事情，和监听的事情的代码放在一起，这样非常方便我们管理，就不需要跳到对应的方法里。非常符合我们开发中高聚合，低耦合的思想。
 */

/*
 编程思想：
 3.1 面向过程：处理事情以过程为核心，一步一步的实现。
 3.2 面向对象：万物皆对象
 3.3 链式变成思想：是将多个操作（多行代码）通过点号（.）链接在一起成为一句代码，使代码可读性好  a(1).b(2).c(3)
     链式编程特点：方法的返回值是block，block必须有返回值（本身对象），block参数（需要操作的值）
     代表：masonry框架
     模仿masonry，写一个加法计算器，练习链式编程思想
 3.4 响应式编程思想：不需要考虑调用顺序，只需要知道考虑结果，类似于蝴蝶效应，产生一个事件，会影响很多东西，这些事件像流一样的传播出去，然后影响结果，借用面向对象的一句话，万物皆是流。
     代表：KVO运用
 3.5 函数式编程思想：是把操作尽量写成一系列嵌套的函数或者方法调用
     函数式编程特点：每个方法必须有返回值（本身对象），把函数或者Block当做参谋，block参数（需要操作的值）block返回值（操作结果）
     代表：ReactiveCocoa
     用函数式编程实现，写一个加法计算器，并且加法计算器自带判断是否等于某个值
 
 4.ReactiveCocoa编程思想
    ReactiveCocoa综合了几种编程风格：
    函数式编程（Functional Programming）
    响应式编程（Reactive Programming）
    所以，你可能听说过ReactiveCocoa被描述为函数响应式编程（FRP）框架。
    以后使用RAC解决问题，就不需要考虑调用顺序，直接考虑结果，把每一次操作写成一系列嵌套的方法中，是代码高聚合，方便管理。
 
 6.ReactiveCocoa常见类
    学习框架首要之处：个人认为先要搞清楚框架中常用的类，在RAC中最核心的类RACSignal,搞定这个类就能用ReactiveCocoa开发了。
 6.1 RACSignal:信号类，一般表示将来有数据传递，只要有数据改变，信号内部接收到数据，就会马上发出数据。
 注意：
    信号类（RACSignal），只是表示当数据改变时，信号内部会发出数据，它本身不具备发送信号的能力，而是交给内部一个订阅者去发出。
    默认一个信号都是冷信号，也就是值改变了，也不会触发，只有订阅了这个信号，这个信号才会变为热信号，值改变了才会触发。
    如何订阅信号：调用信号RACSignal的subscribeNext就能订阅。
    RACSignal简单使用：
    //1.创建信号 createSignal
    //2.订阅信号，才会激活信号 subscribeNext
    //3.发送信号 sendNext
 
    //底层实现
     // 1.创建信号，首先把didSubscribe保存到信号中，还不会触发。
     // 2.当信号被订阅，也就是调用signal的subscribeNext:nextBlock
     // 2.2 subscribeNext内部会创建订阅者subscriber，并且把nextBlock保存到subscriber中。
     // 2.1 subscribeNext内部会调用siganl的didSubscribe
     // 3.siganl的didSubscribe中调用[subscriber sendNext:@1];
     // 3.1 sendNext底层其实就是执行subscriber的nextBlock
 */

@interface DLRACBasicConceptCourse()
@property(nonatomic, strong) RACCommand *command;
@end

@implementation DLRACBasicConceptCourse
- (void)testChain{
    int result = [NSObject makeCalculate:^(DLCaculatorMaker *maker) {
        maker.add(1).add(2).add(3).add(4).divide(5);
    }];
    NSLog(@"%@",@(result));
}

//函数式编程测试
- (void)testFunctionConcept{
    DLCaculator *cal = [[DLCaculator alloc] init];
    BOOL isequal = [[[cal caculator:^int(int result) {
        result += 2;
        result *= 5;
        return result;
    }] equal:^BOOL(int result) {
        return result == 10;
    }] isEqual];
    NSLog(@"%@",@(isequal));
}

//RACSignal基本使用
- (void)signalTest{
    //1.创建信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //block调用时刻：每当有订阅者订阅信号，就会调用block
        //2.发送信号
        [subscriber sendNext:@1];
        
        //如果不再发送数据，最好发送信号完成，内部会自动调用[RACDisposable disposable]取消订阅信号
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            //block调用时刻：当信号发送完成或者发送错误，就会自动执行这个block，取消订阅信号
            //执行完Block后，当前信号就不再被订阅了
            NSLog(@"信号被销毁");
        }];
    }];
    
    //3.订阅信号，才会激活信号
    [signal subscribeNext:^(id  _Nullable x) {
        //block调用时刻：每当有信号发出数据，就会调用block
        NSLog(@"接受到数据：%@",x);
    }];
}

/*
 6.2RACSubscriber：表示订阅者的意思，用于发送信号，这是一个协议，不是一个类，只要遵守这个协议，并且实现方法才能成为订阅者。通过create创建的信号，都有一个订阅者，帮助它发送数据。
 6.3 RACDisposable：用于取消或者清理资源，当信号发送完成或者发送错误的时候，就会自动触发它。
    使用场景：不想监听某个信号时，可以通过它主动取消订阅信号
 6.4 RACSubject：信号提供者，自己可以充当信号，又能发送信号
    使用场景：通常用来替代代理，有了它，就不必定义代理了
    RACReplaySubject:重复提供信号类，RACSignal的子类。
    RACReplaySubject与RACSubject区别：
        RACReplaySubject可以先发送信号，再订阅信号，RACSubject就不可以
        使用场景一：如果一个信号没被订阅一次，就需要把之前的值重复发送一遍，使用重复提供信息类
        使用场景二：可以设置capacity数量来限制缓存的value的数量，即只缓冲罪行的几个值。
        RACSubject和RACReplaySubject简单使用：
 

 */

//RACSubject使用步骤
//1.创建信号 [RACSubject subject],跟RACSignal不一样，创建信号时没有block
//2.订阅信号 - (RACDisposable *)subscribeNext:(void (^)(id x))nextBlock
//3.发送信号：sendNext:(id)value

//RACSubject:底层实现和RACSignal不一样
//1.调用subscribeNext订阅信号，只是把订阅者保存起来，并且订阅者的nextBlock已经赋值了
//2.调用sendNext发送信号，遍历刚刚保存的所有订阅者，一个一个调用订阅者的nextBlock

- (void)racSubjectTest{
    //1.创建信号
    RACSubject *subject = [RACSubject subject];
    
    //2.订阅信号
    [subject subscribeNext:^(id  _Nullable x) {
        //block调用时刻：当信号发出新值，就会调用
        NSLog(@"第一个订阅者%@",x);
    }];
    
    [subject subscribeNext:^(id  _Nullable x) {
        NSLog(@"第二个订阅者%@",x);
    }];
    
    //3.发送信号
    [subject sendNext:@"1"];
}

/*
 // RACReplaySubject使用步骤:
 // 1.创建信号 [RACSubject subject]，跟RACSiganl不一样，创建信号时没有block。
 // 2.可以先订阅信号，也可以先发送信号。
 // 2.1 订阅信号 - (RACDisposable *)subscribeNext:(void (^)(id x))nextBlock
 // 2.2 发送信号 sendNext:(id)value
 
 // RACReplaySubject:底层实现和RACSubject不一样。
 // 1.调用sendNext发送信号，把值保存起来，然后遍历刚刚保存的所有订阅者，一个一个调用订阅者的nextBlock。
 // 2.调用subscribeNext订阅信号，遍历保存的所有值，一个一个调用订阅者的nextBlock
 
 // 如果想当一个信号被订阅，就重复播放之前所有值，需要先发送信号，在订阅信号。
 // 也就是先保存值，在订阅值。
 */
- (void)replaySubjectTest{
    //1.创建信号
    RACReplaySubject *replaySubject = [RACReplaySubject subject];
    
    //2.发送信号
    [replaySubject sendNext:@1];
    [replaySubject sendNext:@2];
    
    //3.订阅信号
    [replaySubject subscribeNext:^(id  _Nullable x) {//调用subscribeNext方法就会在内部创建一个订阅者
        NSLog(@"第一个订阅者收到的数据%@",x);//每创建一个订阅者，都会接收到之前已经发送过的信号值
    }];
    
    [replaySubject subscribeNext:^(id  _Nullable x) {
        NSLog(@"第一个订阅者收到的数据%@",x);
    }];
}


/*
6.6RACTuple：元组类，类似NSArray，用来包装值
6.7RACSequence：RAC中的集合类，用于代替NSArray，NSDictionary，可以使用它来快速遍历数组和字典。
使用场景：1.字典转模型
RACSequence和RACTuple简单使用
 */
- (void)sequenceTest{
    //1.遍历数组
    NSArray *numbers = @[@1,@2,@3,@4];
    // 这里其实是三步
    // 第一步: 把数组转换成集合RACSequence numbers.rac_sequence
    // 第二步: 把集合RACSequence转换RACSignal信号类,numbers.rac_sequence.signal
    // 第三步: 订阅信号，激活信号，会自动把集合中的所有值，遍历出来。
    [numbers.rac_sequence.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //2.遍历字典，遍历出来的键值对会包装秤RACTuple（元组对象）
    NSDictionary *dict = @{@"name":@"xmg",@"age":@18};
    [dict.rac_sequence.signal subscribeNext:^(RACTuple  *_Nullable x) {
        //解包元组，会把元组的值，按顺序给参数里面的变量赋值
        RACTupleUnpack(NSString *key,NSString *value) = x;
        NSLog(@"%@ %@",key,value);
    }];
    
    //3.字典转模型
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"flags.plist" ofType:nil];
    NSArray *dictArray = [NSArray arrayWithContentsOfFile:filePath];
    NSMutableArray *flags = [NSMutableArray array];
    //rac_sequence注意点：调用subscribeNext，并不会马上执行nextBlock，而是会等一会
    [dictArray.rac_sequence.signal subscribeNext:^(id  _Nullable x) {
        //运用RAC遍历字典，x：字典
        FlagItem *item = [FlagItem flagWithDict:x];
        [flags addObject:item];
    }];
    
    //3.3 RAC高级写法
    //map:映射的意思，目的：把原始值value映射成一个新值
    //array：把集合转换成数组
    //底层实现：当信号被订阅，会遍历集合中的原始值
    NSArray *flagsTwo = [[dictArray.rac_sequence map:^id _Nullable(id  _Nullable value) {
        return [FlagItem flagWithDict:value];
    }] array];
}

/*
 6.8 RACCommand：RAC中用于处理事件的类，可以把事件如何处理，事件中的数据如何传递，包装到这个类中，他可以很方便的监控事件的执行过程
    使用场景：监听按钮点击，网络请求
 */
//RACCommand简单使用
- (void)commandTest{
    // 一、RACCommand使用步骤:
    // 1.创建命令 initWithSignalBlock:(RACSignal * (^)(id input))signalBlock
    // 2.在signalBlock中，创建RACSignal，并且作为signalBlock的返回值
    // 3.执行命令 - (RACSignal *)execute:(id)input
    
    // 二、RACCommand使用注意:
    // 1.signalBlock必须要返回一个信号，不能传nil.
    // 2.如果不想要传递信号，直接创建空的信号[RACSignal empty];
    // 3.RACCommand中信号如果数据传递完，必须调用[subscriber sendCompleted]，这时命令才会执行完毕，否则永远处于执行中。
    // 4.RACCommand需要被强引用，否则接收不到RACCommand中的信号，因此RACCommand中的信号是延迟发送的。
    
    // 三、RACCommand设计思想：内部signalBlock为什么要返回一个信号，这个信号有什么用。
    // 1.在RAC开发中，通常会把网络请求封装到RACCommand，直接执行某个RACCommand就能发送请求。
    // 2.当RACCommand内部请求到数据的时候，需要把请求的数据传递给外界，这时候就需要通过signalBlock返回的信号传递了。
    
    // 四、如何拿到RACCommand中返回信号发出的数据。
    // 1.RACCommand有个执行信号源executionSignals，这个是signal of signals(信号的信号),意思是信号发出的数据是信号，不是普通的类型。
    // 2.订阅executionSignals就能拿到RACCommand中返回的信号，然后订阅signalBlock返回的信号，就能获取发出的值。
    
    // 五、监听当前命令是否正在执行executing
    
    // 六、使用场景,监听按钮点击，网络请求
    
    //1.创建命令
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        NSLog(@"执行命令");
        //创建空信号，必须返回信号
//        return [RACSignal empty];
        
        //2.创建信号，用来传递数据
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            [subscriber sendNext:@"请求数据"];
            //注意：数据传递完毕，最好调用sendCompleted，这时命令才执行完毕。
            [subscriber sendCompleted];
            return nil;
        }];
    }];
    
    //强引用命令，不要被销毁，否者接受不到数据
    _command = command;
    
    //3.订阅RACCommand中的信号
    [command.executionSignals subscribeNext:^(RACSignal  *_Nullable x) {
        [x subscribeNext:^(id  _Nullable x) {
            NSLog(@"%@",x);
        }];
    }];
    
    //RAC高级用法
    //switchToLatest:用于signal of signals，获取signal of signals发出的最新信号，也就是可以直接拿到RACCommand中的信号
    [command.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //4.监听命令是否执行完毕，默认会来一次，可以直接跳过，skip表示跳过第一次信号
    [[command.executing skip:1] subscribeNext:^(NSNumber * _Nullable x) {
        if ([x boolValue] == YES) {
            //正在执行
            NSLog(@"正在执行");
        }else{
            //执行完成
            NSLog(@"执行完成");
        }
    }];
    
    //5.执行命令
    [self.command execute:@1];
}

/*
 6.9 RACMulticastConnection:用于当一个信号，被多次订阅时，为了保证创建信号时，避免多次调用创建信号中的block，造成副作用，可以使用这个类处理。
 使用注意：RACMulticastConnection通过RACSignal的-publish或者-multicast:方法创建
 RACMulticastConnection简单使用
 */
- (void)multicastTest{
    // RACMulticastConnection使用步骤:
    // 1.创建信号 + (RACSignal *)createSignal:(RACDisposable * (^)(id<RACSubscriber> subscriber))didSubscribe
    // 2.创建连接 RACMulticastConnection *connect = [signal publish];
    // 3.订阅信号,注意：订阅的不在是之前的信号，而是连接的信号。 [connect.signal subscribeNext:nextBlock]
    // 4.连接 [connect connect]
    
    // RACMulticastConnection底层原理:
    // 1.创建connect，connect.sourceSignal -> RACSignal(原始信号)  connect.signal -> RACSubject
    // 2.订阅connect.signal，会调用RACSubject的subscribeNext，创建订阅者，而且把订阅者保存起来，不会执行block。
    // 3.[connect connect]内部会订阅RACSignal(原始信号)，并且订阅者是RACSubject
    // 3.1.订阅原始信号，就会调用原始信号中的didSubscribe
    // 3.2 didSubscribe，拿到订阅者调用sendNext，其实是调用RACSubject的sendNext
    // 4.RACSubject的sendNext,会遍历RACSubject所有订阅者发送信号。
    // 4.1 因为刚刚第二步，都是在订阅RACSubject，因此会拿到第二步所有的订阅者，调用他们的nextBlock
    
    
    // 需求：假设在一个信号中发送请求，每次订阅一次都会发送请求，这样就会导致多次请求。
    // 解决：使用RACMulticastConnection就能解决.
    
    
    //1.创建请求信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"发送请求");
        return nil;
    }];
    
    //2.订阅信号
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"接收数据");
    }];
    
    //2.订阅信号
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"接收数据");
    }];
    
    //3.运行结果，会执行两遍发送请求，也就是每次订阅都会发送一次请求
    
    
    //RACMulticastConnection：解决重复请求问题
    //1.创建信号
    RACSignal *signalAgain = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"发送请求");
        [subscriber sendNext:@1];
        return nil;
    }];
    
    //2.创建连接
    RACMulticastConnection *connect = [signalAgain publish];
    
    //3.订阅信号
    //注意：订阅信号，也不能激活信号，只是保存订阅者到数组，必须通过调用连接，就会一次性调用所有订阅者的sendNext：
    [connect.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅者一信号");
    }];
    [connect.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅者二信号");
    }];
    
    //4.连接，激活信号
    [connect connect];
}

/*
 6.10 RACSchedule:RAC中的队列，用GCD封装。
 6.11 RACUnit：表示stream不包含有意义的值，也就是看到这个可以直接理解为nil
 6.11 RACEvent:把数据包装成信号事件(signal event)。它主要通过RACSignal的-materialize来使用，然并卵
 */

/*
 7.ReactiveCocoa开发中常见用法
 7.1代替代理
 rac_signalForSelector:用于替代代理
 7.2代替KVO：
 rac_valuesAndChangesForKeyPath:用于监听某个对象的属性改变
 7.3监听事件
 rac_signalForControlEvents:用于监听某个事件
 7.4代替通知
 rac_addObserverForName:用于监听某个通知
 7.5监听文本框文字改变
 rac_textSignal:只要文本框发出改变就会发出这个信号
 7.6处理当界面有多次请求时，需要都获取到数据时，才能展示界面
 rac_liftSelector:withSignalsFromArraySignals:当传入的Signals（信号数组），每一个signal都至少sendNext过一次，就会去触发第一个selector参数的方法
 使用注意：几个信号，参数一的方法就几个参数，每个参数对应信号发出的数据。
 */

- (void)basicTest{
    DLRedView *redV = [[DLRedView alloc] init];
    //1.代替代理
    // 需求：自定义redView,监听红色view中按钮点击
    // 之前都是需要通过代理监听，给红色View添加一个代理属性，点击按钮的时候，通知代理做事情
    // rac_signalForSelector:把调用某个对象的方法的信息转换成信号，就要调用这个方法，就会发送信号。
    // 这里表示只要redV调用btnClick:,就会发出信号，订阅就好了。
    [[redV rac_signalForSelector:@selector(btnClick)] subscribeNext:^(RACTuple * _Nullable x) {
        NSLog(@"点击红色按钮");
    }];
    
    //2.KVO
    // 把监听redV的center属性改变转换成信号，只要值改变就会发送信号
    // observer:可以传入nil
    [[redV rac_valuesAndChangesForKeyPath:@"center" options:NSKeyValueObservingOptionNew observer:nil] subscribeNext:^(RACTwoTuple<id,NSDictionary *> * _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //3.监听事件
    //把按钮点击事件转换为信号，点击按钮，就会发送信号
    [[redV.btn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        NSLog(@"按钮被点击了");
    }];
    
    
    //4.代替通知
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillShowNotification object:nil] subscribeNext:^(NSNotification * _Nullable x) {
        NSLog(@"键盘弹出");
    }];
    
    //5.监听文本框的文字改变
    [redV.textField.rac_textSignal subscribeNext:^(NSString * _Nullable x) {
        NSLog(@"文字改变了%@",x);
    }];
    
    //6.处理多个请求，都返回结果的时候，统一做处理
    RACSignal *request1 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //发送请求1
        [subscriber sendNext:@"发送请求"];
        return nil;
    }];
    
    RACSignal *request2 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //发送请求2
        [subscriber sendNext:@"发送请求2"];
        return nil;
    }];
    
    //使用注意：几个信号，参数一的方法就几个参数，每个参数对应信号发出的数据。
    [self rac_liftSelector:@selector(updateWithR1:R2:) withSignalsFromArray:@[request1,request2]];
}

//更新UI
- (void)updateWithR1:(NSString *)value1 R2:(NSString *)value2{
    
}

/*
 8.ReactiveCocoa常见宏
 8.1 RAC(TARGET,[KEYPATH,[NIL_VAlUE]])：用于给某个对象的某个属性绑定。
 
 8.2 RACObserver(self,name):监听某个对象的某个属性，返回的是信号
 */
- (void)macroTest{
    DLRedView *redV = [[DLRedView alloc] init];
    //只要文本框文字改变，就会修改label的文字
    RAC(redV.btn.titleLabel,text) = redV.textField.rac_textSignal;
    
    [RACObserve(redV, center) subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}

/*
 8.3  @weakify(Obj)和@strongify(Obj),一般两个都是配套使用,在主头文件(ReactiveCocoa.h)中并没有导入，需要自己手动导入，RACEXTScope.h才可以使用。但是每次导入都非常麻烦，只需要在主头文件自己导入就好了。
 */

/*
 8.4 RACTuplePack：把数据包装成RACTuple（元组类）
 8.5 RACTupleUnpack：把RACTuple（元组类）解包成对应的数据。
 */
- (void)tupleTest{
    //把参数中的数据包装成元组
    RACTuple *tuple = RACTuplePack(@"xmg",@20);
    
    //解包元组，会把元组的值，按顺序给参数里面的变量赋值
    RACTupleUnpack(NSString *name,NSNumber *age) = tuple;
}


@end


//RACSubject替换代理
//需求：
//1.给当前控制器添加一个按钮，modal到另一个控制器界面
//2.另一个控制器view中有个按钮，点击按钮，通知当前控制器

@interface DLTwoViewController:UIViewController
@property(nonatomic, strong) RACSubject *delegateSignal;
@end

@implementation DLTwoViewController
- (IBAction)notice:(id)sender{
    //通知第一个控制器，告诉它，按钮被点了
    //通知代理
    //判断代理信号是否有值
    if (self.delegateSignal) {
        //有值，才需要通知
        [self.delegateSignal sendNext:nil];
    }
}
@end

@interface DLOneViewController:UIViewController
@end

@implementation DLOneViewController
- (IBAction)btnClick:(id)sender{
    //创建第二个控制器
    DLTwoViewController *twoVC = [[DLTwoViewController alloc] init];
    
    //设置代理信号
    twoVC.delegateSignal = [RACSubject subject];
    
    //订阅代理信号
    [twoVC.delegateSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"点击了通知按钮");
    }];
    
    //跳转到第二个控制器
    [self presentViewController:twoVC animated:YES completion:nil];
}
@end




