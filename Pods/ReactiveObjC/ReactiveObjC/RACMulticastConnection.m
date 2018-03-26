//
//  RACMulticastConnection.m
//  ReactiveObjC
//
//  Created by Josh Abernathy on 4/11/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACMulticastConnection.h"
#import "RACMulticastConnection+Private.h"
#import "RACDisposable.h"
#import "RACSerialDisposable.h"
#import "RACSubject.h"
#import <libkern/OSAtomic.h>

@interface RACMulticastConnection () {
	RACSubject *_signal;

	// When connecting, a caller should attempt to atomically swap the value of this
	// from `0` to `1`.
	//
	// If the swap is successful the caller is resposible for subscribing `_signal`
	// to `sourceSignal` and storing the returned disposable in `serialDisposable`.
	//
	// If the swap is unsuccessful it means that `_sourceSignal` has already been
	// connected and the caller has no action to take.
	int32_t volatile _hasConnected;
}

@property (nonatomic, readonly, strong) RACSignal *sourceSignal;
@property (strong) RACSerialDisposable *serialDisposable;
@end

@implementation RACMulticastConnection

#pragma mark Lifecycle

/*
 初始化方法就是把外界传进来的RACSignal保存成sourceSignal，把外界传进来的RACSubject保存成自己的signal属性。
 */
- (instancetype)initWithSourceSignal:(RACSignal *)source subject:(RACSubject *)subject {
	NSCParameterAssert(source != nil);
	NSCParameterAssert(subject != nil);

	self = [super init];

	_sourceSignal = source;
	_serialDisposable = [[RACSerialDisposable alloc] init];
	_signal = subject;
	
	return self;
}

#pragma mark Connecting

- (RACDisposable *)connect {
    //原子运算的操作符,主要用于Compare and swap
    /*
     如果_hasConnected为0，意味着没有连接，OSAtomicCompareAndSwap32Barrier返回1，shouldConnect就应该连接。如果_hasConnected为1，意味着已经连接过了，OSAtomicCompareAndSwap32Barrier返回0，shouldConnect不会再次连接。
     */
	BOOL shouldConnect = OSAtomicCompareAndSwap32Barrier(0, 1, &_hasConnected);

	if (shouldConnect) {
        /*
         所谓连接的过程就是RACMulticastConnection内部用RACSubject订阅self.sourceSignal。sourceSignal是RACSignal，会把订阅者RACSubject保存到RACPassthroughSubscriber中，sendNext的时候就会调用RACSubject sendNext，这时就会把sourceSignal的信号都发送给各个订阅者了。
         */
		self.serialDisposable.disposable = [self.sourceSignal subscribe:_signal];
	}

	return self.serialDisposable;
}

- (RACSignal *)autoconnect {
    //在autoconnect为了保证线程安全，用到了一个subscriberCount的类似信号量的volatile变量，保证第一个订阅者能连接上。
	__block volatile int32_t subscriberCount = 0;//关键字volatile只确保每次获取volatile变量时都是从内存加载变量，而不是使用寄存器里面的值，但是它不保证代码访问变量是正确的。

    //返回的新的信号的订阅者订阅RACSubject，RACSubject也会去订阅内部的sourceSignal。
	return [[RACSignal
		createSignal:^(id<RACSubscriber> subscriber) {
            //OSAtomicIncrement32Barrier 和 OSAtomicDecrement32Barrier也是原子运算的操作符，分别是+1和-1操作
			OSAtomicIncrement32Barrier(&subscriberCount);
            //int32_t    OSAtomicIncrement32Barrier( volatile int32_t *__theValue );

			RACDisposable *subscriptionDisposable = [self.signal subscribe:subscriber];
			RACDisposable *connectionDisposable = [self connect];

			return [RACDisposable disposableWithBlock:^{
				[subscriptionDisposable dispose];

				if (OSAtomicDecrement32Barrier(&subscriberCount) == 0) {
					[connectionDisposable dispose];
				}
			}];
		}]
		setNameWithFormat:@"[%@] -autoconnect", self.signal.name];
}

@end
