//
//  RACSubject.m
//  ReactiveObjC
//
//  Created by Josh Abernathy on 3/9/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACSubject.h"
#import <ReactiveObjC/RACEXTScope.h>
#import "RACCompoundDisposable.h"
#import "RACPassthroughSubscriber.h"

@interface RACSubject ()

// Contains all current subscribers to the receiver.
// 包含接收方所有当前的订阅者
// This should only be used while synchronized on `self`.
// 这个变量仅被用于self的同步
@property (nonatomic, strong, readonly) NSMutableArray *subscribers;

// Contains all of the receiver's subscriptions to other signals.
// 包含所有接收方对于其它信号的订阅
@property (nonatomic, strong, readonly) RACCompoundDisposable *disposable;

// Enumerates over each of the receiver's `subscribers` and invokes `block` for
// each.
// 遍历所有接收方的订阅者和调用每一个订阅者的block
- (void)enumerateSubscribersUsingBlock:(void (^)(id<RACSubscriber> subscriber))block;

@end

@implementation RACSubject

#pragma mark Lifecycle

+ (instancetype)subject {
	return [[self alloc] init];
}

- (instancetype)init {
	self = [super init];
	if (self == nil) return nil;

	_disposable = [RACCompoundDisposable compoundDisposable];//管理取消订阅（组合模式）
	_subscribers = [[NSMutableArray alloc] initWithCapacity:1];
	
	return self;
}

- (void)dealloc {
	[self.disposable dispose];
}

#pragma mark Subscription
//直接传入一个订阅者
- (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
	NSCParameterAssert(subscriber != nil);

	RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
    //将订阅者与当前信号绑定在一起  将订阅者和disposable绑定
	subscriber = [[RACPassthroughSubscriber alloc] initWithSubscriber:subscriber signal:self disposable:disposable];

	NSMutableArray *subscribers = self.subscribers;
	@synchronized (subscribers) {
		[subscribers addObject:subscriber];//添加订阅者到管理数组
	}
	
	[disposable addDisposable:[RACDisposable disposableWithBlock:^{
		@synchronized (subscribers) {
			// Since newer subscribers are generally shorter-lived, search
			// starting from the end of the list.
            // 一般来说订阅者都比较短命，所以需要倒序遍历
            // 遍历下标
			NSUInteger index = [subscribers indexOfObjectWithOptions:NSEnumerationReverse passingTest:^ BOOL (id<RACSubscriber> obj, NSUInteger index, BOOL *stop) {
				return obj == subscriber;
			}];

            //如果发生了dispose移除订阅者
			if (index != NSNotFound) [subscribers removeObjectAtIndex:index];
		}
	}]];

	return disposable;
}

//重写遍历订阅者的方法，使其更安全
- (void)enumerateSubscribersUsingBlock:(void (^)(id<RACSubscriber> subscriber))block {
	NSArray *subscribers;
	@synchronized (self.subscribers) {
		subscribers = [self.subscribers copy];
	}

	for (id<RACSubscriber> subscriber in subscribers) {
		block(subscriber);
	}
}

#pragma mark RACSubscriber

- (void)sendNext:(id)value {
    //遍历发送值给所有的订阅者
	[self enumerateSubscribersUsingBlock:^(id<RACSubscriber> subscriber) {
		[subscriber sendNext:value];
	}];
}

- (void)sendError:(NSError *)error {
	[self.disposable dispose];//所有的signal都要使其失效
	
	[self enumerateSubscribersUsingBlock:^(id<RACSubscriber> subscriber) {
		[subscriber sendError:error];
	}];
}

- (void)sendCompleted {
	[self.disposable dispose];
	
	[self enumerateSubscribersUsingBlock:^(id<RACSubscriber> subscriber) {
		[subscriber sendCompleted];
	}];
}

- (void)didSubscribeWithDisposable:(RACCompoundDisposable *)d {
	if (d.disposed) return;
	[self.disposable addDisposable:d];

	@weakify(self, d);
	[d addDisposable:[RACDisposable disposableWithBlock:^{
		@strongify(self, d);
		[self.disposable removeDisposable:d];//若d失效，则移除之
	}]];
}

@end
