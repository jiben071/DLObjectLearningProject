//
//  DLRACSourceCodeLeanringViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 21/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  https://halfrost.com/reactivecocoa_racsignal/

#import "DLRACSourceCodeLeanringViewController.h"
#import <ReactiveObjC/ReactiveObjC.h>

@interface DLRACSourceCodeLeanringViewController ()

@end

@implementation DLRACSourceCodeLeanringViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

//ReactiveCocoa 的宗旨是Streams of values over time ，随着时间变化而不断流动的数据流。

/*
 ReactiveCocoa 主要解决了以下这些问题：
 
 UI数据绑定
 UI控件通常需要绑定一个事件，RAC可以很方便的绑定任何数据流到控件上。
 
 用户交互事件绑定
 RAC为可交互的UI控件提供了一系列能发送Signal信号的方法。这些数据流会在用户交互中相互传递。
 
 解决状态以及状态之间依赖过多的问题
 有了RAC的绑定之后，可以不用在关心各种复杂的状态，isSelect，isFinish……也解决了这些状态在后期很难维护的问题。
 
 消息传递机制的大统一
 OC中编程原来消息传递机制有以下几种：Delegate，Block Callback，Target-Action，Timers，KVO，objc上有一篇关于OC中这5种消息传递方式改如何选择的文章Communication Patterns，推荐大家阅读。现在有了RAC之后，以上这5种方式都可以统一用RAC来处理。
 */

/*
 二. RAC中的核心RACSignal
 ReactiveCocoa 中最核心的概念之一就是信号RACStream。RACStream中有两个子类——RACSignal 和 RACSequence。本文先来分析RACSignal。
 */

- (void)signalTest {
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendNext:@3];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"signal dispose");
        }];
    }];
    
    RACDisposable *disposable = [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"subscribe value = %@", x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"error: %@", error);
    } completed:^{
        NSLog(@"completed");
    }];

    [disposable dispose];
}

- (void)bindTest{
    RACSignal *signal = [RACSignal createSignal:
                         ^RACDisposable *(id<RACSubscriber> subscriber)
                         {
                             [subscriber sendNext:@1];
                             [subscriber sendNext:@2];
                             [subscriber sendNext:@3];
                             [subscriber sendCompleted];
                             return [RACDisposable disposableWithBlock:^{
                                 NSLog(@"signal dispose");
                             }];
                         }];
    
    RACSignal *bindSignal = [signal bind:^RACSignalBindBlock _Nonnull{
        return ^RACSignal *(NSNumber *value, BOOL *stop){
            value = @(value.integerValue * 2);
            return [RACSignal return:value];
        };
    }];
    
    [bindSignal subscribeNext:^(id x) {
        NSLog(@"subscribe value = %@", x);
    }];
}

- (void)concatTest{
    RACSignal *signal = [RACSignal createSignal:
                         ^RACDisposable *(id<RACSubscriber> subscriber)
                         {
                             [subscriber sendNext:@1];
                             [subscriber sendNext:@2];
                             [subscriber sendNext:@3];
                             [subscriber sendNext:@4];
                             [subscriber sendCompleted];
                             return [RACDisposable disposableWithBlock:^{
                                 NSLog(@"signal dispose");
                             }];
                         }];
    
    
    RACSignal *signals = [RACSignal createSignal:
                          ^RACDisposable *(id<RACSubscriber> subscriber)
                          {
                              [subscriber sendNext:@"A"];
                              [subscriber sendNext:@"B"];
                              [subscriber sendNext:@"C"];
                              [subscriber sendNext:@"D"];
                              [subscriber sendCompleted];
                              return [RACDisposable disposableWithBlock:^{
                                  NSLog(@"signal dispose");
                              }];
                          }];
    
    RACSignal *concatSignal = [signal concat:signals];
    
    [concatSignal subscribeNext:^(id x) {
        NSLog(@"subscribe value = %@", x);
    }];
    
    RACSignal *zipSignal = [signal zipWith:signals];
    
    [zipSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"subscribe value = %@", x);
    }];
}

- (void)mapTest{
    RACSignal *signal = [RACSignal createSignal:
                         ^RACDisposable *(id<RACSubscriber> subscriber)
                         {
                             [subscriber sendNext:@1];
                             [subscriber sendNext:@2];
                             [subscriber sendNext:@3];
                             [subscriber sendNext:@4];
                             [subscriber sendCompleted];
                             return [RACDisposable disposableWithBlock:^{
                                 NSLog(@"signal dispose");
                             }];
                         }];
    
    //map操作一般是用来做信号变换的。
    RACSignal *signalB = [signal map:^id _Nullable(NSNumber  *_Nullable value) {
        return @([value intValue] * 10);
    }];
}


- (void)scanWithStartTest {
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@1];
        [subscriber sendNext:@4];
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }];
    
    //通过使用scan这一系列的操作，可以有效的消除副作用操作！  什么副作用？！
    RACSignal *signalB = [signalA scanWithStart:@(2) reduceWithIndex:^id _Nullable(NSNumber * _Nullable running, NSNumber  *_Nullable next, NSUInteger index) {
        return @(running.intValue * next.intValue + index);
    }];
    
    /*
     2    // 2 * 1 + 0 = 2
     3    // 2 * 1 + 1 = 3
     14   // 3 * 4 + 2 = 14
     */
}

- (void)mapReplaceTest{
    RACSignal *signal = [RACSignal createSignal:
                         ^RACDisposable *(id<RACSubscriber> subscriber)
                         {
                             [subscriber sendNext:@1];
                             [subscriber sendNext:@2];
                             [subscriber sendNext:@3];
                             [subscriber sendNext:@4];
                             [subscriber sendCompleted];
                             return [RACDisposable disposableWithBlock:^{
                                 NSLog(@"signal dispose");
                             }];
                         }];
    //效果是不管signal发送什么信号，就替换成@"A"
    RACSignal *signalB = [signal mapReplace:@"A"];
    [signalB subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}

//reduce是减少，聚合在一起的意思，reduceEach就是每个信号内部都聚合在一起
- (void)reduceEachTest{
    RACSignal *signalA = [RACSignal createSignal:
                         ^RACDisposable *(id<RACSubscriber> subscriber)
                         {
                             [subscriber sendNext:@1];
                             [subscriber sendNext:@2];
                             [subscriber sendNext:@3];
                             [subscriber sendNext:@4];
                             [subscriber sendCompleted];
                             return [RACDisposable disposableWithBlock:^{
                                 NSLog(@"signal dispose");
                             }];
                         }];
    
    RACSignal *signalB = [signalA reduceEach:^id (NSNumber *num1,NSNumber *num2){
        return @([num1 intValue] + [num2 intValue]);
    }];
    
    [signalB subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}

- (void)reduceApplyTest {
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        id block = ^id(NSNumber *first,NSNumber *second,NSNumber *third){
            return @(first.integerValue + second.integerValue * third.integerValue);
        };
        [subscriber sendNext:RACTuplePack(block,@2,@3,@8)];
        [subscriber sendNext:RACTuplePack((id)(^id(NSNumber *x){
            return @(x.intValue * 10);
        }),@9,@10,@30)];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"signal dispose");
        }];
    }];
    RACSignal *signalB = [signalA reduceApply];
    [signalB subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}

#pragma mark - 冷热信号 https://halfrost.com/reactivecocoa_hot_cold_signal/
/*
 如何做到信号只执行一次didSubscribe闭包，最重要的一点是RACSignal冷信号只能被订阅一次。由于冷信号只能一对一，那么想一对多就只能交给热信号去处理了。这时候就需要把冷信号转换成热信号。
 在ReactiveCocoa v2.5中，冷信号转换成热信号需要用到RACMulticastConnection 这个类。
 */

/*
 把冷信号转换成热信号用以下5种方式，5种方法都会用到RACMulticastConnection。接下来一一分析它们的具体实现。
 1. multicast
 2. publish
 3. replay
 4. replayLast
 
 关于ReactiveCocoa v2.5中，冷信号即使转换成了热信号，热信号在之后的变换中还会在变成冷信号，所以在v2.5的版本中会有很多冷信号转成热信号的操作。在ReactiveCocoa v3.0以后的版本中，新增了热信号变换之后还是热信号的机制，如此以来就方便很多，不需要增加很多不必要的冷信号转成热信号的代码。
 */

#pragma mark - 高阶信号操作 https://halfrost.com/reactivecocoa_racsignal_operations3/
/*
 高阶操作大部分的操作是针对高阶信号的，也就是说信号里面发送的值还是一个信号或者是一个高阶信号。可以类比数组，这里就是多维数组，数组里面还是套的数组。
 */
#pragma mark -- 1. flattenMap: (在父类RACStream中定义的)
- (void)flattenMapTest{
    /*
     flattenMap:在整个RAC中具有很重要的地位，很多信号变换都是可以用flattenMap:来实现的。
     
     map:，flatten，filter，sequenceMany:这4个操作都是用flattenMap:来实现的。然而其他变换操作实现里面用到map:，flatten，filter又有很多。
     */
}


/*
 升阶操作：
 
 map( 把值map成一个信号)
 [RACSignal return:signal]
 
 降阶操作：
 
 flatten(等效于flatten:0，+merge:)
 concat(等效于flatten:1)
 flatten:1
 switchToLatest
 flattenMap:
 这5种操作能将高阶信号变为低阶信号，但是最终降阶之后的效果就只有3种：switchToLatest，flatten，concat。
 */


@end
