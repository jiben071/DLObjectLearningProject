//
//  RACDynamicSignal.m
//  ReactiveObjC
//
//  Created by Justin Spahr-Summers on 2013-10-10.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "RACDynamicSignal.h"
#import <ReactiveObjC/RACEXTScope.h>
#import "RACCompoundDisposable.h"
#import "RACPassthroughSubscriber.h"
#import "RACScheduler+Private.h"
#import "RACSubscriber.h"
#import <libkern/OSAtomic.h>

@interface RACDynamicSignal ()

// The block to invoke for each subscriber.
@property (nonatomic, copy, readonly) RACDisposable * (^didSubscribe)(id<RACSubscriber> subscriber);

@end

@implementation RACDynamicSignal

#pragma mark Lifecycle

//所以新建Signal的任务就全部落在了RACSignal的子类RACDynamicSignal上了。
//block闭包在订阅的时候才会被“释放”出来。
+ (RACSignal *)createSignal:(RACDisposable * (^)(id<RACSubscriber> subscriber))didSubscribe {
	RACDynamicSignal *signal = [[self alloc] init];
	signal->_didSubscribe = [didSubscribe copy];//RACDynamicSignal这个类很简单，里面就保存了一个名字叫didSubscribe的block。
	return [signal setNameWithFormat:@"+createSignal:"];//最后再给signal命名+createSignal:。
}

#pragma mark Managing Subscribers

- (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
	NSCParameterAssert(subscriber != nil);

    //dispossable管理信号产生的disposal
	RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
    //RACPassthroughSubscriber是一个私有的类。RACPassthroughSubscriber类就只有这一个方法。目的就是为了把所有的信号事件从一个订阅者subscriber传递给另一个还没有disposed的订阅者subscriber。
	subscriber = [[RACPassthroughSubscriber alloc] initWithSubscriber:subscriber signal:self disposable:disposable];

	if (self.didSubscribe != NULL) {
        //RACScheduler.subscriptionScheduler是一个全局的单例。
		RACDisposable *schedulingDisposable = [RACScheduler.subscriptionScheduler schedule:^{//在当前线程
            //这两句关键的语句。之前信号里面保存的block就会在此处被“释放”执行。self.didSubscribe(subscriber)这一句就执行了信号保存的didSubscribe闭包。
            //在didSubscribe闭包中有sendNext，sendError，sendCompleted，执行这些语句会分别调用RACPassthroughSubscriber里面对应的方法。
			RACDisposable *innerDisposable = self.didSubscribe(subscriber);//回调订阅者
			[disposable addDisposable:innerDisposable];
		}];

		[disposable addDisposable:schedulingDisposable];
	}
	
	return disposable;
}

@end
