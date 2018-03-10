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

@end
