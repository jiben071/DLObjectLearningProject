//
//  RACDynamicSignal.h
//  ReactiveObjC
//
//  Created by Justin Spahr-Summers on 2013-10-10.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "RACSignal.h"

// A private `RACSignal` subclasses that implements its subscription behavior
// using a block.
//一个私有RACSignal子类，用来通过block实现订阅行为
@interface RACDynamicSignal : RACSignal

+ (RACSignal *)createSignal:(RACDisposable * (^)(id<RACSubscriber> subscriber))didSubscribe;

@end
