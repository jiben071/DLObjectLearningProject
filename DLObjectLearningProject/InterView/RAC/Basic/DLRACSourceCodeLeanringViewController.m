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




@end
