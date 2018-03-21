//
//  RACPassthroughSubscriber.h
//  ReactiveObjC
//
//  Created by Justin Spahr-Summers on 2013-06-13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RACSubscriber.h"

@class RACCompoundDisposable;
@class RACSignal<__covariant ValueType>;

// A private subscriber that passes through all events to another subscriber
// while not disposed.
// 目的就是为了把所有的信号事件从一个订阅者subscriber传递给另一个还没有disposed的订阅者subscriber。
@interface RACPassthroughSubscriber : NSObject <RACSubscriber>

// Initializes the receiver to pass through events until disposed.
//
// subscriber - The subscriber to forward events to. This must not be nil.
// signal     - The signal that will be sending events to the receiver.
// disposable - When this disposable is disposed, no more events will be
//              forwarded. This must not be nil.
//
// Returns an initialized passthrough subscriber.
- (instancetype)initWithSubscriber:(id<RACSubscriber>)subscriber signal:(RACSignal *)signal disposable:(RACCompoundDisposable *)disposable;

@end
