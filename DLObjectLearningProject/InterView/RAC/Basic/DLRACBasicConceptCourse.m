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
@end
