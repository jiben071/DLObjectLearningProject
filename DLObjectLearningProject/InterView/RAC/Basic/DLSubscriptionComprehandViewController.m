//
//  DLSubscriptionComprehandViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 09/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  https://tech.meituan.com/RACSignalSubscription.html
//  RACSignal的Subscription深入分析
//  在RACSignal+Operation中关于multicast && replay的，一共有5个操作：publish、multicast、replay、replayLast、replayLazily，他们之间有什么细微的差别呢？

#import "DLSubscriptionComprehandViewController.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import <AFNetworking/AFNetworking.h>

@interface DLSubscriptionComprehandViewController ()

@end

@implementation DLSubscriptionComprehandViewController

/*
 #Subscription过程概括
 RACSignal的Subscription过程概括起来可以分为三个步骤：
 
 [RACSignal createSignal]来获得signal
 [signal subscribeNext:]来获得subscriber，然后进行subscription
 进入didSubscribe，通过[subscriber sendNext:]来执行next block
 */

- (void)viewDidLoad {
    [super viewDidLoad];

    
    // part 2 : [signal subscribeNext:]来获得subscriber，然后进行subscription
    [[self signInSignal] subscribeNext:^(id  _Nullable x) {
        NSLog(@"Sign in result: %@", x);
    }];
}


- (RACSignal *)signInSignal{
    //part 1:[RACSignal createSignal]来获得signal
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //登录服务
//        [self.signInService
//         signInWithUsername:self.usernameTextField.text
//         password:self.passwordTextField.text
//         complete:^(BOOL success) {
        
             // part 3: 进入didSubscribe，通过[subscriber sendNext:]来执行next block
             [subscriber sendNext:@(YES)];
             [subscriber sendCompleted];
//         }];
        return nil;
    }];
}


#pragma mark - 案例二
- (void)multicastTest{
    //This signal starts a new request on each subscription
    RACSignal *networkRequest = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //网络请求
        /*
        AFHTTPRequestOperation *operation = [client
                                             HTTPRequestOperationWithRequest:request
                                             success:^(AFHTTPRequestOperation *operation, id response) {
                                                 [subscriber sendNext:response];
                                                 [subscriber sendCompleted];
                                             }
                                             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 [subscriber sendError:error];
                                             }];
        
        [client enqueueHTTPRequestOperation:operation];
        return [RACDisposable disposableWithBlock:^{
            [operation cancel];
        }];
         */
        return nil;
    }];
    // Starts a single request, no matter how many subscriptions `connection.signal`
    // gets. This is equivalent to the -replay operator, or similar to
    // +startEagerlyWithScheduler:block:.
    
    //目的：无论多少个订阅，都只发生一次网络请求
    RACMulticastConnection *connection = [networkRequest multicast:[RACReplaySubject subject]];
    [connection connect];
    
    [connection.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"subscriber one: %@", x);
    }];
    
    [connection.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"subscriber one: %@", x);
    }];
}


#pragma mark - replay, replayLast, and replayLazily  区分学习
//问题所在，重复订阅，目的只需执行一次
- (void)reExecutedExample{
    __block int num = 0;
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        num++;
        NSLog(@"Increment num to: %@",@(num));
        [subscriber sendNext:@(num)];
        return nil;
    }];
    
    NSLog(@"start subscriptions");
    
    //In this way, a normal RACSignal can be thought of as lazy, as it doesn’t do any work until it has a subscriber.
    //有点类似懒加载，直到有订阅者订阅它
    //Subscriber 1 (S1)
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"S1:%@",x);
    }];
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"S2:%@",x);
    }];
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"S3:%@",x);
    }];
}

//Our second example shows how each subscriber only receives the values that are sent after their subscription is added.
- (void)problemTwoTest{
    RACSubject *letters = [RACSubject subject];
    RACSignal *signal = letters;
    
    NSLog(@"Subscribe S1");
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"S1: %@", x);
    }];
    
    NSLog(@"Send A");
    [letters sendNext:@"A"];
    NSLog(@"Send B");
    [letters sendNext:@"B"];
    
    NSLog(@"Subscribe S2");
    [signal subscribeNext:^(id x) {
        NSLog(@"S2: %@", x);
    }];
    
    NSLog(@"Send C");
    [letters sendNext:@"C"];
    NSLog(@"Send D");
    [letters sendNext:@"D"];
    
    NSLog(@"Subscribe S3");
    [signal subscribeNext:^(id x) {
        NSLog(@"S3: %@", x);
    }];
}

//replay test
- (void)replayTest{
    __block int num = 0;
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        num++;
        NSLog(@"Increament num to: %i",num);
        [subscriber sendNext:@(num)];
        return nil;
    }] replay];
    
    NSLog(@"Start subscriptions");
    
    // Subscriber 1 (S1)
    [signal subscribeNext:^(id x) {
        NSLog(@"S1: %@", x);
    }];
    
    // Subscriber 2 (S2)
    [signal subscribeNext:^(id x) {
        NSLog(@"S2: %@", x);
    }];
    
    // Subscriber 3 (S3)
    [signal subscribeNext:^(id x) {
        NSLog(@"S3: %@", x);
    }];
    
    
    /*
     打印结果：（没有重复执行num++，打印的是历史signal的值）
     This time the num integer is incremented immediately, before there are even any subscribers. And it is only incremented once, meaning that the subscription code is only been executed a single time, regardless of how many subscribers the signal has.
     Increment num to: 1
     Start subscriptions
     S1: 1
     S2: 1
     S3: 1
     */
    
}

//The second example shows how each new subscriber receives the full history of the signal:
- (void)fullHistoryTest{
    RACSubject *letters = [RACSubject subject];
    RACSignal *signal = [letters replay];
    
    NSLog(@"Subscribe S1");
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"S1:%@",x);
    }];
    NSLog(@"Send A");
    [letters sendNext:@"A"];
    NSLog(@"Send B");
    [letters sendNext:@"B"];
    
    NSLog(@"Subscribe S2");
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"S2:%@",x);
    }];
    
    NSLog(@"Send C");
    [letters sendNext:@"C"];
    NSLog(@"Send D");
    [letters sendNext:@"D"];
    
    NSLog(@"Subscribe S3");
    [signal subscribeNext:^(id x) {
        NSLog(@"S3: %@", x);
    }];
    
    /*打印结果：
     Subscribe S1
     
     Send A
     S1: A
     
     Send B
     S1: B
     
     Subscribe S2
     S2: A
     S2: B
     
     Send C
     S1: C
     S2: C
     
     Send D
     S1: D
     S2: D
     
     Subscribe S3
     S3: A
     S3: B
     S3: C
     S3: D
     
     */
}

- (void)replayLatestTest{
    RACSubject *letters = [RACSubject subject];
    RACSignal *signal = [letters replayLast];
    
    NSLog(@"Subscribe S1");
    [signal subscribeNext:^(id x) {
        NSLog(@"S1: %@", x);
    }];
    
    NSLog(@"Send A");
    [letters sendNext:@"A"];
    NSLog(@"Send B");
    [letters sendNext:@"B"];
    
    NSLog(@"Subscribe S2");
    [signal subscribeNext:^(id x) {
        NSLog(@"S2: %@", x);
    }];
    
    NSLog(@"Send C");
    [letters sendNext:@"C"];
    NSLog(@"Send D");
    [letters sendNext:@"D"];
    
    NSLog(@"Subscribe S3");
    [signal subscribeNext:^(id x) {
        NSLog(@"S3: %@", x);
    }];
    
    /*打印结果：
     Subscribe S1
     
     Send A
     S1: A
     
     Send B
     S1: B
     
     Subscribe S2
     S2: B
     
     Send C
     S1: C
     S2: C
     
     Send D
     S1: D
     S2: D
     
     Subscribe S3
     S3: D
     */
}

- (void)lazilyRepeatTest{
    __block int num = 0;
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        num++;
        NSLog(@"Increment num to:%@",@(num));//这里不会马上执行，直到第一次订阅
        [subscriber sendNext:@(num)];
        return nil;
    }] replayLazily];
    
    NSLog(@"Start subscriptions");
    
    // Subscriber 1 (S1)
    [signal subscribeNext:^(id x) {//直到第一次订阅
        NSLog(@"S1: %@", x);
    }];
    
    // Subscriber 2 (S2)
    [signal subscribeNext:^(id x) {
        NSLog(@"S2: %@", x);
    }];
    
    // Subscriber 3 (S3)
    [signal subscribeNext:^(id x) {
        NSLog(@"S3: %@", x);
    }];
    
    /*
     打印结果：
     Start subscriptions
     Increment num to: 1
     S1: 1
     S2: 1
     S3: 1
     */
}

//And the second example shows that the full history is sent to any new subscribers, just like with -replay.
-(void)replayLazilyTest2{
    RACSubject *letters = [RACSubject subject];
    RACSignal *signal = [letters replayLazily];
    
    NSLog(@"Subscribe S1");
    [signal subscribeNext:^(id x) {
        NSLog(@"S1: %@", x);
    }];
    
    NSLog(@"Send A");
    [letters sendNext:@"A"];
    NSLog(@"Send B");
    [letters sendNext:@"B"];
    
    NSLog(@"Subscribe S2");
    [signal subscribeNext:^(id x) {
        NSLog(@"S2: %@", x);
    }];
    
    NSLog(@"Send C");
    [letters sendNext:@"C"];
    NSLog(@"Send D");
    [letters sendNext:@"D"];
    
    NSLog(@"Subscribe S3");
    [signal subscribeNext:^(id x) {
        NSLog(@"S3: %@", x);
    }];
    
    /*
     打印结果：
     Subscribe S1
     
     Send A
     S1: A
     
     Send B
     S1: B
     
     Subscribe S2
     S2: A
     S2: B
     
     Send C
     S1: C
     S2: C
     
     Send D
     S1: D
     S2: D
     
     Subscribe S3
     S3: A
     S3: B
     S3: C
     S3: D
     */
}

/*
 Summary:
 ReactiveCocoa provides three convenience methods for allowing multiple subscribers to the same signal,without re-executing the source signal's subscrption code, and to provide some level of historical values to later subscribers.
 -replay and replayLast both make the signal hot,and will provide either all values(-replay) or the most recent(-replayLast) value to subscribers.-replayLazily returns a cold signal that will provide all of the signal's values to subscribers.
 */










@end
