//
//  RACSignal+Operations.m
//  ReactiveObjC
//
//  Created by Justin Spahr-Summers on 2012-09-06.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACSignal+Operations.h"
#import "NSObject+RACDeallocating.h"
#import "NSObject+RACDescription.h"
#import "RACBlockTrampoline.h"
#import "RACCommand.h"
#import "RACCompoundDisposable.h"
#import "RACDisposable.h"
#import "RACEvent.h"
#import "RACGroupedSignal.h"
#import "RACMulticastConnection+Private.h"
#import "RACReplaySubject.h"
#import "RACScheduler.h"
#import "RACSerialDisposable.h"
#import "RACSignalSequence.h"
#import "RACStream+Private.h"
#import "RACSubject.h"
#import "RACSubscriber+Private.h"
#import "RACSubscriber.h"
#import "RACTuple.h"
#import "RACUnit.h"
#import <libkern/OSAtomic.h>
#import <objc/runtime.h>

NSString * const RACSignalErrorDomain = @"RACSignalErrorDomain";

const NSInteger RACSignalErrorTimedOut = 1;
const NSInteger RACSignalErrorNoMatchingCase = 2;

// Subscribes to the given signal with the given blocks.
//
// If the signal errors or completes, the corresponding block is invoked. If the
// disposable passed to the block is _not_ disposed, then the signal is
// subscribed to again.
static RACDisposable *subscribeForever (RACSignal *signal, void (^next)(id), void (^error)(NSError *, RACDisposable *), void (^completed)(RACDisposable *)) {
	next = [next copy];
	error = [error copy];
	completed = [completed copy];

	RACCompoundDisposable *compoundDisposable = [RACCompoundDisposable compoundDisposable];

	RACSchedulerRecursiveBlock recursiveBlock = ^(void (^recurse)(void)) {
		RACCompoundDisposable *selfDisposable = [RACCompoundDisposable compoundDisposable];
		[compoundDisposable addDisposable:selfDisposable];

		__weak RACDisposable *weakSelfDisposable = selfDisposable;

		RACDisposable *subscriptionDisposable = [signal subscribeNext:next error:^(NSError *e) {
			@autoreleasepool {
				error(e, compoundDisposable);
				[compoundDisposable removeDisposable:weakSelfDisposable];
			}

			recurse();
		} completed:^{
			@autoreleasepool {
				completed(compoundDisposable);
				[compoundDisposable removeDisposable:weakSelfDisposable];
			}

			recurse();
		}];

		[selfDisposable addDisposable:subscriptionDisposable];
	};

	// Subscribe once immediately, and then use recursive scheduling for any
	// further resubscriptions.
	recursiveBlock(^{
		RACScheduler *recursiveScheduler = RACScheduler.currentScheduler ?: [RACScheduler scheduler];

		RACDisposable *schedulingDisposable = [recursiveScheduler scheduleRecursiveBlock:recursiveBlock];
		[compoundDisposable addDisposable:schedulingDisposable];
	});

	return compoundDisposable;
}

@implementation RACSignal (Operations)

/*
 doNext:能让我们在原信号sendNext之前，能执行一个block闭包，在这个闭包中我们可以执行我们想要执行的副作用操作。
 */
- (RACSignal *)doNext:(void (^)(id x))block {
	NSCParameterAssert(block != NULL);

	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return [self subscribeNext:^(id x) {
			block(x);
			[subscriber sendNext:x];
		} error:^(NSError *error) {
			[subscriber sendError:error];
		} completed:^{
			[subscriber sendCompleted];
		}];
	}] setNameWithFormat:@"[%@] -doNext:", self.name];
}

/*
 doError:能让我们在原信号sendError之前，能执行一个block闭包，在这个闭包中我们可以执行我们想要执行的副作用操作。
 */
- (RACSignal *)doError:(void (^)(NSError *error))block {
	NSCParameterAssert(block != NULL);

	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return [self subscribeNext:^(id x) {
			[subscriber sendNext:x];
		} error:^(NSError *error) {
			block(error);
			[subscriber sendError:error];
		} completed:^{
			[subscriber sendCompleted];
		}];
	}] setNameWithFormat:@"[%@] -doError:", self.name];
}

/*doCompleted:能让我们在原信号sendCompleted之前，能执行一个block闭包，在这个闭包中我们可以执行我们想要执行的副作用操作。*/
- (RACSignal *)doCompleted:(void (^)(void))block {
	NSCParameterAssert(block != NULL);

	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return [self subscribeNext:^(id x) {
			[subscriber sendNext:x];
		} error:^(NSError *error) {
			[subscriber sendError:error];
		} completed:^{
			block();
			[subscriber sendCompleted];
		}];
	}] setNameWithFormat:@"[%@] -doCompleted:", self.name];
}

/*
 这个操作其实就是调用了throttle:valuesPassingTest:方法，传入时间间隔interval，predicate( )闭包则永远返回YES，原信号的每个信号都执行节流操作。
 */
- (RACSignal *)throttle:(NSTimeInterval)interval {
	return [[self throttle:interval valuesPassingTest:^(id _) {
		return YES;
	}] setNameWithFormat:@"[%@] -throttle: %f", self.name, (double)interval];
}

- (RACSignal *)throttle:(NSTimeInterval)interval valuesPassingTest:(BOOL (^)(id next))predicate {
	NSCParameterAssert(interval >= 0);
	NSCParameterAssert(predicate != nil);

    /*
     小结一下，每个原信号发送过来，通过在throttle:valuesPassingTest:里面的did subscriber闭包中进行订阅。这个闭包中主要干了4件事情：
     
     调用flushNext(NO)闭包判断能否发送原信号的值。入参为NO，不发送原信号的值。
     判断阀门条件predicate(x)能否发送原信号的值。
     如果以上两个条件都满足，nextValue中进行赋值为原信号发来的值，hasNextValue = YES代表当前有要发送的值。
     开启一个delayScheduler，延迟interval的时间，发送原信号的这个值，即调用flushNext(YES)。
     */
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACCompoundDisposable *compoundDisposable = [RACCompoundDisposable compoundDisposable];

		// We may never use this scheduler, but we need to set it up ahead of
		// time so that our scheduled blocks are run serially if we do.
		RACScheduler *scheduler = [RACScheduler scheduler];

		// Information about any currently-buffered `next` event.
		__block id nextValue = nil;
		__block BOOL hasNextValue = NO;
		RACSerialDisposable *nextDisposable = [[RACSerialDisposable alloc] init];

        //flushNext( )这个闭包是为了hook住原信号的发送。
		void (^flushNext)(BOOL send) = ^(BOOL send) {
			@synchronized (compoundDisposable) {//之所以把RACCompoundDisposable作为线程间互斥信号量，因为RACCompoundDisposable里面会加入所有的RACDisposable信号。接着下面的操作用@synchronized给线程间加锁。
				[nextDisposable.disposable dispose];

				if (!hasNextValue) return;
				if (send) [subscriber sendNext:nextValue];

				nextValue = nil;
				hasNextValue = NO;
			}
		};

		RACDisposable *subscriptionDisposable = [self subscribeNext:^(id x) {
            /*
             首先先创建一个delayScheduler。先判断当前的currentScheduler是否存在，不存在就取之前创建的[RACScheduler scheduler]。这里虽然两处都是RACTargetQueueScheduler类型的，但是currentScheduler是com.ReactiveCocoa.RACScheduler.mainThreadScheduler，而[RACScheduler scheduler]创建的是com.ReactiveCocoa.RACScheduler.backgroundScheduler。
             */
			RACScheduler *delayScheduler = RACScheduler.currentScheduler ?: scheduler;
			BOOL shouldThrottle = predicate(x);

			@synchronized (compoundDisposable) {
				flushNext(NO);
				if (!shouldThrottle) {
					[subscriber sendNext:x];
					return;
				}

				nextValue = x;
				hasNextValue = YES;
				nextDisposable.disposable = [delayScheduler afterDelay:interval schedule:^{
					flushNext(YES);
				}];
			}
		} error:^(NSError *error) {
			[compoundDisposable dispose];
			[subscriber sendError:error];
		} completed:^{
			flushNext(YES);
			[subscriber sendCompleted];
		}];

		[compoundDisposable addDisposable:subscriptionDisposable];
		return compoundDisposable;
	}] setNameWithFormat:@"[%@] -throttle: %f valuesPassingTest:", self.name, (double)interval];
}

- (RACSignal *)delay:(NSTimeInterval)interval {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];

		// We may never use this scheduler, but we need to set it up ahead of
		// time so that our scheduled blocks are run serially if we do.
		RACScheduler *scheduler = [RACScheduler scheduler];

        /*
         在schedule闭包中做的时间就是延迟interval的时间发送原信号的值。
         */
		void (^schedule)(dispatch_block_t) = ^(dispatch_block_t block) {
			RACScheduler *delayScheduler = RACScheduler.currentScheduler ?: scheduler;
			RACDisposable *schedulerDisposable = [delayScheduler afterDelay:interval schedule:block];
			[disposable addDisposable:schedulerDisposable];
		};

		RACDisposable *subscriptionDisposable = [self subscribeNext:^(id x) {
			schedule(^{
				[subscriber sendNext:x];
			});
		} error:^(NSError *error) {
			[subscriber sendError:error];
		} completed:^{
			schedule(^{
				[subscriber sendCompleted];
			});
		}];

		[disposable addDisposable:subscriptionDisposable];
		return disposable;
	}] setNameWithFormat:@"[%@] -delay: %f", self.name, (double)interval];
}

- (RACSignal *)repeat {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return subscribeForever(self,
			^(id x) {
				[subscriber sendNext:x];
			},
			^(NSError *error, RACDisposable *disposable) {
				[disposable dispose];
				[subscriber sendError:error];
			},
			^(RACDisposable *disposable) {
				// Resubscribe.
			});
	}] setNameWithFormat:@"[%@] -repeat", self.name];
}

- (RACSignal *)catch:(RACSignal * (^)(NSError *error))catchBlock {
	NSCParameterAssert(catchBlock != NULL);

	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACSerialDisposable *catchDisposable = [[RACSerialDisposable alloc] init];

		RACDisposable *subscriptionDisposable = [self subscribeNext:^(id x) {
			[subscriber sendNext:x];
		} error:^(NSError *error) {
			RACSignal *signal = catchBlock(error);
			NSCAssert(signal != nil, @"Expected non-nil signal from catch block on %@", self);
            //当对原信号进行订阅的时候，如果出现了错误，会去执行catchBlock( )闭包，入参为刚刚产生的error。catchBlock( )闭包产生的是一个新的RACSignal，并再次用订阅者订阅该信号。
            
            //这里之所以说是高阶操作，是因为这里原信号发生错误之后，错误会升阶成一个信号。
			catchDisposable.disposable = [signal subscribe:subscriber];
		} completed:^{
			[subscriber sendCompleted];
		}];

		return [RACDisposable disposableWithBlock:^{
			[catchDisposable dispose];
			[subscriptionDisposable dispose];
		}];
	}] setNameWithFormat:@"[%@] -catch:", self.name];
}

- (RACSignal *)catchTo:(RACSignal *)signal {
	return [[self catch:^(NSError *error) {
		return signal;//catchTo:的实现就是调用catch:方法，只不过原来catch:方法里面的catchBlock( )闭包，永远都只返回catchTo:的入参，signal信号。
	}] setNameWithFormat:@"[%@] -catchTo: %@", self.name, signal];
}

+ (RACSignal *)try:(id (^)(NSError **errorPtr))tryBlock {
	NSCParameterAssert(tryBlock != NULL);

	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		NSError *error;
		id value = tryBlock(&error);
		RACSignal *signal = (value == nil ? [RACSignal error:error] : [RACSignal return:value]);
		return [signal subscribe:subscriber];
	}] setNameWithFormat:@"+try:"];
}

/*
 try:可以用来进来信号的升阶操作。对原信号进行flattenMap变换，对信号发出来的每个值都调用一遍tryBlock( )闭包，如果这个闭包的返回值是YES，那么就返回[RACSignal return:value]，如果闭包的返回值是NO，那么就返回error。原信号中如果都是值，那么经过try:操作之后，每个值都会变成RACSignal，于是原信号也就变成了高阶信号了。
 */
- (RACSignal *)try:(BOOL (^)(id value, NSError **errorPtr))tryBlock {
	NSCParameterAssert(tryBlock != NULL);

	return [[self flattenMap:^(id value) {
		NSError *error = nil;
		BOOL passed = tryBlock(value, &error);
		return (passed ? [RACSignal return:value] : [RACSignal error:error]);
	}] setNameWithFormat:@"[%@] -try:", self.name];
}

/*
 tryMap:的实现和try:的实现基本一致，唯一不同的就是入参闭包的返回值不同。在tryMap:中调用mapBlock( )闭包，返回是一个对象，如果这个对象不为nil，就返回[RACSignal return:mappedValue]。如果返回的对象是nil，那么就变换成error信号。
 */
- (RACSignal *)tryMap:(id (^)(id value, NSError **errorPtr))mapBlock {
	NSCParameterAssert(mapBlock != NULL);

	return [[self flattenMap:^(id value) {
		NSError *error = nil;
		id mappedValue = mapBlock(value, &error);
		return (mappedValue == nil ? [RACSignal error:error] : [RACSignal return:mappedValue]);
	}] setNameWithFormat:@"[%@] -tryMap:", self.name];
}

/*
 initially:能让我们在原信号发送之前，先调用了defer:操作，在return self之前先执行了一个闭包，在这个闭包中我们可以执行我们想要执行的副作用操作。
 */
- (RACSignal *)initially:(void (^)(void))block {
	NSCParameterAssert(block != NULL);

	return [[RACSignal defer:^{
		block();
		return self;
	}] setNameWithFormat:@"[%@] -initially:", self.name];
}

/*
 finally:操作调用了doError:和doCompleted:操作，依次在sendError之前，sendCompleted之前，插入一个block( )闭包。这样当信号因为错误而要终止取消订阅，或者，发送结束之前，都能执行一段我们想要执行的副作用操作。
 */
- (RACSignal *)finally:(void (^)(void))block {
	NSCParameterAssert(block != NULL);

	return [[[self
		doError:^(NSError *error) {
			block();
		}]
		doCompleted:^{
			block();
		}]
		setNameWithFormat:@"[%@] -finally:", self.name];
}

- (RACSignal *)bufferWithTime:(NSTimeInterval)interval onScheduler:(RACScheduler *)scheduler {
	NSCParameterAssert(scheduler != nil);
	NSCParameterAssert(scheduler != RACScheduler.immediateScheduler);

	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACSerialDisposable *timerDisposable = [[RACSerialDisposable alloc] init];
		NSMutableArray *values = [NSMutableArray array];

        /*
         flushValues( )闭包里面主要是把数组包装成一个元组，并且全部发送出来，原数组里面就全部清空了。这也是bufferWithTime:onScheduler:的作用，在interval时间内，把这个时间间隔内的原信号都缓存起来，并且在interval的那一刻，把这些缓存的信号打包成一个元组，发送出来。
         
         和throttle:valuesPassingTest:方法一样，在原信号completed的时候，立即执行flushValues( )闭包，把里面存的值都发送出来。
         */
		void (^flushValues)() = ^{
			@synchronized (values) {
				[timerDisposable.disposable dispose];

				if (values.count == 0) return;

				RACTuple *tuple = [RACTuple tupleWithObjectsFromArray:values];
				[values removeAllObjects];
				[subscriber sendNext:tuple];
			}
		};

		RACDisposable *selfDisposable = [self subscribeNext:^(id x) {
			@synchronized (values) {
				if (values.count == 0) {
					timerDisposable.disposable = [scheduler afterDelay:interval schedule:flushValues];
				}

				[values addObject:x ?: RACTupleNil.tupleNil];
			}
		} error:^(NSError *error) {
			[subscriber sendError:error];
		} completed:^{
			flushValues();
			[subscriber sendCompleted];
		}];

		return [RACDisposable disposableWithBlock:^{
			[selfDisposable dispose];
			[timerDisposable dispose];
		}];
	}] setNameWithFormat:@"[%@] -bufferWithTime: %f onScheduler: %@", self.name, (double)interval, scheduler];
}

/*
 collect函数会调用aggregateWithStartFactory: reduce:方法。把所有原信号的值收集起来，保存在NSMutableArray中。
 */
- (RACSignal *)collect {
	return [[self aggregateWithStartFactory:^{
		return [[NSMutableArray alloc] init];
	} reduce:^(NSMutableArray *collectedValues, id x) {
		[collectedValues addObject:(x ?: NSNull.null)];
		return collectedValues;
	}] setNameWithFormat:@"[%@] -collect", self.name];
}

- (RACSignal *)takeLast:(NSUInteger)count {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		NSMutableArray *valuesTaken = [NSMutableArray arrayWithCapacity:count];
		return [self subscribeNext:^(id x) {
			[valuesTaken addObject:x ? : RACTupleNil.tupleNil];

			while (valuesTaken.count > count) {
				[valuesTaken removeObjectAtIndex:0];
			}
		} error:^(NSError *error) {
			[subscriber sendError:error];
		} completed:^{
			for (id value in valuesTaken) {
				[subscriber sendNext:value == RACTupleNil.tupleNil ? nil : value];
			}

			[subscriber sendCompleted];
		}];
	}] setNameWithFormat:@"[%@] -takeLast: %lu", self.name, (unsigned long)count];
}

- (RACSignal *)combineLatestWith:(RACSignal *)signal {
	NSCParameterAssert(signal != nil);

	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];

		__block id lastSelfValue = nil;
		__block BOOL selfCompleted = NO;

		__block id lastOtherValue = nil;
		__block BOOL otherCompleted = NO;

		void (^sendNext)(void) = ^{
			@synchronized (disposable) {
				if (lastSelfValue == nil || lastOtherValue == nil) return;
				[subscriber sendNext:RACTuplePack(lastSelfValue, lastOtherValue)];
			}
		};

		RACDisposable *selfDisposable = [self subscribeNext:^(id x) {
			@synchronized (disposable) {
				lastSelfValue = x ?: RACTupleNil.tupleNil;
				sendNext();
			}
		} error:^(NSError *error) {
			[subscriber sendError:error];
		} completed:^{
			@synchronized (disposable) {
				selfCompleted = YES;
				if (otherCompleted) [subscriber sendCompleted];
			}
		}];

		[disposable addDisposable:selfDisposable];

		RACDisposable *otherDisposable = [signal subscribeNext:^(id x) {
			@synchronized (disposable) {
				lastOtherValue = x ?: RACTupleNil.tupleNil;
				sendNext();
			}
		} error:^(NSError *error) {
			[subscriber sendError:error];
		} completed:^{
			@synchronized (disposable) {
				otherCompleted = YES;
				if (selfCompleted) [subscriber sendCompleted];
			}
		}];

		[disposable addDisposable:otherDisposable];

		return disposable;
	}] setNameWithFormat:@"[%@] -combineLatestWith: %@", self.name, signal];
}

+ (RACSignal *)combineLatest:(id<NSFastEnumeration>)signals {
	return [[self join:signals block:^(RACSignal *left, RACSignal *right) {
		return [left combineLatestWith:right];
	}] setNameWithFormat:@"+combineLatest: %@", signals];
}

+ (RACSignal *)combineLatest:(id<NSFastEnumeration>)signals reduce:(RACGenericReduceBlock)reduceBlock {
	NSCParameterAssert(reduceBlock != nil);

	RACSignal *result = [self combineLatest:signals];

	// Although we assert this condition above, older versions of this method
	// supported this argument being nil. Avoid crashing Release builds of
	// apps that depended on that.
	if (reduceBlock != nil) result = [result reduceEach:reduceBlock];

	return [result setNameWithFormat:@"+combineLatest: %@ reduce:", signals];
}

- (RACSignal *)merge:(RACSignal *)signal {
	return [[RACSignal
		merge:@[ self, signal ]]
		setNameWithFormat:@"[%@] -merge: %@", self.name, signal];
}

+ (RACSignal *)merge:(id<NSFastEnumeration>)signals {
	NSMutableArray *copiedSignals = [[NSMutableArray alloc] init];
	for (RACSignal *signal in signals) {
		[copiedSignals addObject:signal];
	}

	return [[[RACSignal
		createSignal:^ RACDisposable * (id<RACSubscriber> subscriber) {
			for (RACSignal *signal in copiedSignals) {
				[subscriber sendNext:signal];
			}

			[subscriber sendCompleted];
			return nil;
		}]
		flatten]
		setNameWithFormat:@"+merge: %@", copiedSignals];
}

/*
 如果maxConcurrent = 0，会发生什么？那么flatten:就退化成flatten了。
 如果maxConcurrent = 1，会发生什么？那么flatten:就退化成concat了。
 如果maxConcurrent > 1，会发生什么？由于至今还没有遇到能用到maxConcurrent > 1的需求情况，所以这里暂时不展示图解了。maxConcurrent > 1之后，flatten的行为还依照高阶信号的个数和maxConcurrent的关系。如果高阶信号的个数<=maxConcurrent的值，那么flatten:又退化成flatten了。如果高阶信号的个数>maxConcurrent的值，那么多的信号就会进入queuedSignals缓存数组。
 */
- (RACSignal *)flatten:(NSUInteger)maxConcurrent {
    //入参maxConcurrent的意思是最大可容纳同时被订阅的信号个数。
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACCompoundDisposable *compoundDisposable = [[RACCompoundDisposable alloc] init];

		// Contains disposables for the currently active subscriptions.
		//
		// This should only be used while synchronized on `subscriber`.
        //activeDisposables里面装的是当前正在订阅的订阅者们的disposables信号。
		NSMutableArray *activeDisposables = [[NSMutableArray alloc] initWithCapacity:maxConcurrent];

		// Whether the signal-of-signals has completed yet.
		//
		// This should only be used while synchronized on `subscriber`.
        //selfCompleted表示高阶信号是否Completed。
		__block BOOL selfCompleted = NO;

		// Subscribes to the given signal.
		__block void (^subscribeToSignal)(RACSignal *);

		// Weak reference to the above, to avoid a leak.
        //recur是对subscribeToSignal闭包的一个弱引用，防止strong-weak循环引用，在下面会分析subscribeToSignal闭包，就会明白为什么recur要用weak修饰了。
		__weak __block void (^recur)(RACSignal *);

		// Sends completed to the subscriber if all signals are finished.
		//
		// This should only be used while synchronized on `subscriber`.
        //completeIfAllowed的作用是在所有信号都发送完毕的时候，通知订阅者，给订阅者发送completed。
		void (^completeIfAllowed)(void) = ^{
            //当selfCompleted = YES 并且activeDisposables数组里面的信号都发送完毕，没有可以发送的信号了，即activeDisposables.count = 0，那么就给订阅者sendCompleted。
			if (selfCompleted && activeDisposables.count == 0) {
				[subscriber sendCompleted];
			}
		};

		// The signals waiting to be started.
		//
		// This array should only be used while synchronized on `subscriber`.
        //queuedSignals里面装的是被暂时缓存起来的信号，它们等待被订阅。
		NSMutableArray *queuedSignals = [NSMutableArray array];

        //subscribeToSignal闭包的作用是订阅所给的信号。这个闭包的入参参数就是一个信号，在闭包内部订阅这个信号，并进行一些操作。
		recur = subscribeToSignal = ^(RACSignal *signal) {
			RACSerialDisposable *serialDisposable = [[RACSerialDisposable alloc] init];

			@synchronized (subscriber) {
                //activeDisposables先添加当前高阶信号发出来的信号的Disposable( 也就是入参信号的Disposable)
				[compoundDisposable addDisposable:serialDisposable];
				[activeDisposables addObject:serialDisposable];
			}

			serialDisposable.disposable = [signal subscribeNext:^(id x) {
				[subscriber sendNext:x];
			} error:^(NSError *error) {
				[subscriber sendError:error];
			} completed:^{
                //这里会对recur进行__strong，因为下面第6步会用到subscribeToSignal( )闭包，同样也是为了防止出现循环引用。
				__strong void (^subscribeToSignal)(RACSignal *) = recur;
				RACSignal *nextSignal;

                //订阅入参信号，给订阅者发送信号。当发送完毕后，activeDisposables中移除它对应的Disposable。
				@synchronized (subscriber) {
					[compoundDisposable removeDisposable:serialDisposable];
					[activeDisposables removeObjectIdenticalTo:serialDisposable];

                    //如果当前缓存的queuedSignals数组里面没有缓存的信号，那么就调用completeIfAllowed( )闭包。
					if (queuedSignals.count == 0) {
						completeIfAllowed();
						return;
					}

                    //如果当前缓存的queuedSignals数组里面有缓存的信号，那么就取出第0个信号，并在queuedSignals数组移除它。
					nextSignal = queuedSignals[0];
					[queuedSignals removeObjectAtIndex:0];
				}

                // 6  把第4步取出的信号继续订阅，继续调用subscribeToSignal( )闭包。
				subscribeToSignal(nextSignal);
			}];
		};

        //订阅高阶信号发出来的信号
        /*
         每发送完一个信号就判断缓存数组queuedSignals的个数，如果缓存数组里面已经没有信号了，那么就结束原来高阶信号的发送。如果缓存数组里面还有信号就继续订阅。如此循环，直到原高阶信号所有的信号都发送完毕。
         */
		[compoundDisposable addDisposable:[self subscribeNext:^(RACSignal *signal) {
			if (signal == nil) return;

			NSCAssert([signal isKindOfClass:RACSignal.class], @"Expected a RACSignal, got %@", signal);

			@synchronized (subscriber) {
                //如果当前最大可容纳信号的个数 > 0 ，且，activeDisposables数组里面已经装满到最大可容纳信号的个数，不能再装新的信号了。那么就把当前的信号缓存到queuedSignals数组中。
				if (maxConcurrent > 0 && activeDisposables.count >= maxConcurrent) {
					[queuedSignals addObject:signal];

					// If we need to wait, skip subscribing to this
					// signal.
					return;
				}
			}

            //直到activeDisposables数组里面有空的位子可以加入新的信号，那么就调用subscribeToSignal( )闭包，开始订阅这个新的信号。
			subscribeToSignal(signal);
		} error:^(NSError *error) {
			[subscriber sendError:error];
		} completed:^{
			@synchronized (subscriber) {
                //最后完成的时候标记变量selfCompleted为YES，并且调用completeIfAllowed( )闭包。
				selfCompleted = YES;
				completeIfAllowed();
			}
		}]];

		[compoundDisposable addDisposable:[RACDisposable disposableWithBlock:^{
			// A strong reference is held to `subscribeToSignal` until we're
			// done, preventing it from deallocating early.
            //这里值得一提的是，还需要把subscribeToSignal手动置为nil。因为在subscribeToSignal闭包中强引用了completeIfAllowed闭包，防止completeIfAllowed闭包被提早的销毁掉了。所以在completeIfAllowed闭包执行完毕的时候，需要再把subscribeToSignal闭包置为nil。
			subscribeToSignal = nil;
		}]];

		return compoundDisposable;
	}] setNameWithFormat:@"[%@] -flatten: %lu", self.name, (unsigned long)maxConcurrent];
}

/*
 then的操作也是延迟，只不过它是把block( )闭包延迟到原信号发送complete之后。通过then信号变化得到的新的信号，在原信号发送值的期间的时间内，都不会发送任何值，因为ignoreValues了，一旦原信号sendComplete之后，就紧接着block( )闭包产生的信号。
 */
- (RACSignal *)then:(RACSignal * (^)(void))block {
	NSCParameterAssert(block != nil);

	return [[[self
		ignoreValues]
		concat:[RACSignal defer:block]]
		setNameWithFormat:@"[%@] -then:", self.name];
}

//但是针对的信号的对象是不同的，concat是针对高阶信号进行降阶操作。concat:是把两个信号连接起来的操作。
- (RACSignal *)concat {
	return [[self flatten:1] setNameWithFormat:@"[%@] -concat", self.name];
}

/*
 aggregateWithStartFactory: reduce:内部实现就是调用aggregateWithStart: reduce:，只不过入参多了一个产生start的startFactory( )闭包罢了。
 */
- (RACSignal *)aggregateWithStartFactory:(id (^)(void))startFactory reduce:(id (^)(id running, id next))reduceBlock {
	NSCParameterAssert(startFactory != NULL);
	NSCParameterAssert(reduceBlock != NULL);

	return [[RACSignal defer:^{
		return [self aggregateWithStart:startFactory() reduce:reduceBlock];
	}] setNameWithFormat:@"[%@] -aggregateWithStartFactory:reduce:", self.name];
}

/*
 aggregateWithStart: reduce:调用aggregateWithStart: reduceWithIndex:函数，只不过没有只用index值。同样，如果原信号没有发送complete信号，也不会输出任何信号。
 */
- (RACSignal *)aggregateWithStart:(id)start reduce:(id (^)(id running, id next))reduceBlock {
	return [[self
		aggregateWithStart:start
		reduceWithIndex:^(id running, id next, NSUInteger index) {
			return reduceBlock(running, next);
		}]
		setNameWithFormat:@"[%@] -aggregateWithStart: %@ reduce:", self.name, RACDescription(start)];
}

/*
 aggregate是合计的意思。所以最后变换出来的信号只有最后一个值。
 值得注意的一点是，原信号如果没有发送complete信号，那么该函数就不会输出新的信号值。因为在一直等待结束。
 */
- (RACSignal *)aggregateWithStart:(id)start reduceWithIndex:(id (^)(id, id, NSUInteger))reduceBlock {
	return [[[[self
		scanWithStart:start reduceWithIndex:reduceBlock]
		startWith:start]
		takeLast:1]
		setNameWithFormat:@"[%@] -aggregateWithStart: %@ reduceWithIndex:", self.name, RACDescription(start)];
}

//setKeyPath: onObject:就是调用setKeyPath: onObject: nilValue:方法，只不过nilValue传递的是nil。
- (RACDisposable *)setKeyPath:(NSString *)keyPath onObject:(NSObject *)object {
	return [self setKeyPath:keyPath onObject:object nilValue:nil];
}

- (RACDisposable *)setKeyPath:(NSString *)keyPath onObject:(NSObject *)object nilValue:(id)nilValue {
	NSCParameterAssert(keyPath != nil);
	NSCParameterAssert(object != nil);

	keyPath = [keyPath copy];

	RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];

	// Purposely not retaining 'object', since we want to tear down the binding
	// when it deallocates normally.
	__block void * volatile objectPtr = (__bridge void *)object;

	RACDisposable *subscriptionDisposable = [self subscribeNext:^(id x) {
		// Possibly spec, possibly compiler bug, but this __bridge cast does not
		// result in a retain here, effectively an invisible __unsafe_unretained
		// qualifier. Using objc_precise_lifetime gives the __strong reference
		// desired. The explicit use of __strong is strictly defensive.
        /*
         作者怀疑是编译器的一个bug，即使是显示的调用了__strong，依旧没法保证被强引用了，所以还需要用objc_precise_lifetime来保证强引用。
         
         关于这个问题，笔者查询了一下LLVM的文档，在6.3 precise lifetime semantics这一节中提到了这个问题。
         
         通常上，凡是声明了__strong的变量，都会有很确切的生命周期。ARC会维持这些__strong的变量在其生命周期中被retained。
         
         但是自动存储的局部变量是没有确切的生命周期的。这些变量仅仅只是简单的持有一个强引用，强引用着retain对象的指针类型的值。这些值完全受控于本地控制者的如何优化。所以要想改变这些局部变量的生命周期，是不可能的事情。因为有太多的优化，理论上都会导致局部变量的生命周期减少，但是这些优化非常有用。
         
         但是LLVM为我们提供了一个关键字objc_precise_lifetime，使用这个可以是局部变量的生命周期变成确切的。这个关键字有时候还是非常有用的。甚至更加极端情况，该局部变量都没有被使用，但是它依旧可以保持一个确定的生命周期。
         */
		__strong NSObject *object __attribute__((objc_precise_lifetime)) = (__bridge __strong id)objectPtr;
		[object setValue:x ?: nilValue forKeyPath:keyPath];
	} error:^(NSError *error) {
		__strong NSObject *object __attribute__((objc_precise_lifetime)) = (__bridge __strong id)objectPtr;

		NSCAssert(NO, @"Received error from %@ in binding for key path \"%@\" on %@: %@", self, keyPath, object, error);

		// Log the error if we're running with assertions disabled.
		NSLog(@"Received error from %@ in binding for key path \"%@\" on %@: %@", self, keyPath, object, error);

		[disposable dispose];
	} completed:^{
		[disposable dispose];
	}];

	[disposable addDisposable:subscriptionDisposable];

	#if DEBUG
	static void *bindingsKey = &bindingsKey;
	NSMutableDictionary *bindings;

	@synchronized (object) {
        /*
         如果bindings字典不存在，那么就调用objc_setAssociatedObject对object进行关联对象。参数是OBJC_ASSOCIATION_RETAIN_NONATOMIC。如果bindings字典存在，就用objc_getAssociatedObject取出字典。
         
         在字典里面重新更新绑定key-value值，key就是入参keyPath，value是原信号。
         */
		bindings = objc_getAssociatedObject(object, bindingsKey);
		if (bindings == nil) {
			bindings = [NSMutableDictionary dictionary];
			objc_setAssociatedObject(object, bindingsKey, bindings, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		}
	}

	@synchronized (bindings) {
		NSCAssert(bindings[keyPath] == nil, @"Signal %@ is already bound to key path \"%@\" on object %@, adding signal %@ is undefined behavior", [bindings[keyPath] nonretainedObjectValue], keyPath, object, self);

		bindings[keyPath] = [NSValue valueWithNonretainedObject:self];
	}
	#endif

	RACDisposable *clearPointerDisposable = [RACDisposable disposableWithBlock:^{
		#if DEBUG
		@synchronized (bindings) {
			[bindings removeObjectForKey:keyPath];//当信号取消订阅的时候，移除所有的关联值。
		}
		#endif

        //在这个while的死循环里面只有当OSAtomicCompareAndSwapPtrBarrier返回值为YES，才能退出整个死循环。返回值为YES就代表&objectPtr被置为了NULL，这样就确保了在线程安全的情况下，不存在野指针的问题了。
		while (YES) {
			void *ptr = objectPtr;
            //OSAtomicCompareAndSwapPtrBarrier(type __oldValue, type __newValue, volatile type *__theValue)
            //这个函数用于比较__oldValue是否与__theValue指针指向的内存位置的值匹配，如果匹配，则将__newValue的值存储到__theValue指向的内存位置。整个函数的返回值就是交换是否成功的BOOL值。
			if (OSAtomicCompareAndSwapPtrBarrier(ptr, NULL, &objectPtr)) {
				break;
			}
		}
	}];

	[disposable addDisposable:clearPointerDisposable];

	[object.rac_deallocDisposable addDisposable:disposable];

	RACCompoundDisposable *objectDisposable = object.rac_deallocDisposable;
	return [RACDisposable disposableWithBlock:^{
		[objectDisposable removeDisposable:disposable];
		[disposable dispose];
	}];
}

+ (RACSignal *)interval:(NSTimeInterval)interval onScheduler:(RACScheduler *)scheduler {
	return [[RACSignal interval:interval onScheduler:scheduler withLeeway:0.0] setNameWithFormat:@"+interval: %f onScheduler: %@", (double)interval, scheduler];
}

+ (RACSignal *)interval:(NSTimeInterval)interval onScheduler:(RACScheduler *)scheduler withLeeway:(NSTimeInterval)leeway {
	NSCParameterAssert(scheduler != nil);
	NSCParameterAssert(scheduler != RACScheduler.immediateScheduler);

	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return [scheduler after:[NSDate dateWithTimeIntervalSinceNow:interval] repeatingEvery:interval withLeeway:leeway schedule:^{
			[subscriber sendNext:[NSDate date]];
		}];
	}] setNameWithFormat:@"+interval: %f onScheduler: %@ withLeeway: %f", (double)interval, scheduler, (double)leeway];
}

- (RACSignal *)takeUntil:(RACSignal *)signalTrigger {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
		void (^triggerCompletion)(void) = ^{
			[disposable dispose];
			[subscriber sendCompleted];
		};

		RACDisposable *triggerDisposable = [signalTrigger subscribeNext:^(id _) {
			triggerCompletion();
		} completed:^{
			triggerCompletion();
		}];

		[disposable addDisposable:triggerDisposable];

		if (!disposable.disposed) {
			RACDisposable *selfDisposable = [self subscribeNext:^(id x) {
				[subscriber sendNext:x];
			} error:^(NSError *error) {
				[subscriber sendError:error];
			} completed:^{
				[disposable dispose];
				[subscriber sendCompleted];
			}];

			[disposable addDisposable:selfDisposable];
		}

		return disposable;
	}] setNameWithFormat:@"[%@] -takeUntil: %@", self.name, signalTrigger];
}

- (RACSignal *)takeUntilReplacement:(RACSignal *)replacement {
	return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACSerialDisposable *selfDisposable = [[RACSerialDisposable alloc] init];

		RACDisposable *replacementDisposable = [replacement subscribeNext:^(id x) {
			[selfDisposable dispose];
			[subscriber sendNext:x];
		} error:^(NSError *error) {
			[selfDisposable dispose];
			[subscriber sendError:error];
		} completed:^{
			[selfDisposable dispose];
			[subscriber sendCompleted];
		}];

		if (!selfDisposable.disposed) {
			selfDisposable.disposable = [[self
				concat:[RACSignal never]]
				subscribe:subscriber];
		}

		return [RACDisposable disposableWithBlock:^{
			[selfDisposable dispose];
			[replacementDisposable dispose];
		}];
	}];
}

/*
 witchToLatest这个操作只能用在高阶信号上，如果原信号里面有不是信号的值，那么就会崩溃，崩溃信息如下：

 ***** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: '-switchToLatest requires that the source signal (<RACDynamicSignal: 0x608000038ec0> name: ) send signals.
 */
- (RACSignal *)switchToLatest {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
        //在switchToLatest操作中，先把原信号转换成热信号，connection.signal就是RACSubject类型的。对RACSubject进行flattenMap:变换。在flattenMap:变换中，connection.signal会先concat:一个never信号。这里concat:一个never信号的原因是为了内部的信号过早的结束而导致订阅者收到complete信号。
		RACMulticastConnection *connection = [self publish];

		RACDisposable *subscriptionDisposable = [[connection.signal
			flattenMap:^(RACSignal *x) {
				NSCAssert(x == nil || [x isKindOfClass:RACSignal.class], @"-switchToLatest requires that the source signal (%@) send signals. Instead we got: %@", self, x);

				// -concat:[RACSignal never] prevents completion of the receiver from
				// prematurely terminating the inner signal.
                //flattenMap:变换中x也是一个信号，对x进行takeUntil:变换，效果就是下一个信号到来之前，x会一直发送信号，一旦下一个信号到来，x就会被取消订阅，开始订阅新的信号。
				return [x takeUntil:[connection.signal concat:[RACSignal never]]];//这里concat:一个never信号的原因是为了内部的信号过早的结束而导致订阅者收到complete信号。
			}]
			subscribe:subscriber];

		RACDisposable *connectionDisposable = [connection connect];
		return [RACDisposable disposableWithBlock:^{
			[subscriptionDisposable dispose];
			[connectionDisposable dispose];
		}];
	}] setNameWithFormat:@"[%@] -switchToLatest", self.name];
}

+ (RACSignal *)switch:(RACSignal *)signal cases:(NSDictionary *)cases default:(RACSignal *)defaultSignal {
	NSCParameterAssert(signal != nil);
	NSCParameterAssert(cases != nil);

	for (id key in cases) {
		id value __attribute__((unused)) = cases[key];
		NSCAssert([value isKindOfClass:RACSignal.class], @"Expected all cases to be RACSignals, %@ isn't", value);
	}

	NSDictionary *copy = [cases copy];

	return [[[signal
		map:^(id key) {
			if (key == nil) key = RACTupleNil.tupleNil;

			RACSignal *signal = copy[key] ?: defaultSignal;
			if (signal == nil) {
				NSString *description = [NSString stringWithFormat:NSLocalizedString(@"No matching signal found for value %@", @""), key];
				return [RACSignal error:[NSError errorWithDomain:RACSignalErrorDomain code:RACSignalErrorNoMatchingCase userInfo:@{ NSLocalizedDescriptionKey: description }]];
			}

			return signal;//如果得到的信号不为nil，那么原信号完全转换完成就会变成一个高阶信号，这个高阶信号里面装的都是信号。最后再对这个高阶信号执行switchToLatest转换。
		}]
		switchToLatest]
		setNameWithFormat:@"+switch: %@ cases: %@ default: %@", signal, cases, defaultSignal];
}

+ (RACSignal *)if:(RACSignal *)boolSignal then:(RACSignal *)trueSignal else:(RACSignal *)falseSignal {
    //入参boolSignal，trueSignal，falseSignal三个信号都不能为nil。
	NSCParameterAssert(boolSignal != nil);
	NSCParameterAssert(trueSignal != nil);
	NSCParameterAssert(falseSignal != nil);

	return [[[boolSignal
		map:^(NSNumber *value) {
            //boolSignal里面都必须装的是NSNumber类型的值。
			NSCAssert([value isKindOfClass:NSNumber.class], @"Expected %@ to send BOOLs, not %@", boolSignal, value);

            //针对boolSignal进行map升阶操作，boolSignal信号里面的值如果是YES，那么就转换成trueSignal信号，如果为NO，就转换成falseSignal。升阶转换完成之后，boolSignal就是一个高阶信号，然后再进行switchToLatest操作。
			return (value.boolValue ? trueSignal : falseSignal);
		}]
		switchToLatest]
		setNameWithFormat:@"+if: %@ then: %@ else: %@", boolSignal, trueSignal, falseSignal];
}

//first方法就更加省略，连defaultValue也不传。最终返回信号是原信号中第一个next里面的值，如果原信号第一个值没有，比如直接error或者completed，那么返回的是nil。
- (id)first {
	return [self firstOrDefault:nil];
}

//firstOrDefault:的实现就是调用了firstOrDefault: success: error:方法。只不过不需要传success和error，不关心内部的状态。最终返回信号是原信号中第一个next里面的值，如果原信号第一个值没有，比如直接error或者completed，那么返回的是defaultValue。
- (id)firstOrDefault:(id)defaultValue {
	return [self firstOrDefault:defaultValue success:NULL error:NULL];
}

//在ReactiveCocoa中还包含一些同步的操作，这些操作一般我们很少使用，除非真的很确定这样做了之后不会有什么问题，否则胡乱使用会导致线程死锁等一些严重的问题。
- (id)firstOrDefault:(id)defaultValue success:(BOOL *)success error:(NSError **)error {
    /*
     NSCondition 的对象实际上作为一个锁和一个线程检查器：锁主要为了当检测条件时保护数据源，执行条件引发的任务；线程检查器主要是根据条件决定是否继续运行线程，即线程是否被阻塞。
     */
	NSCondition *condition = [[NSCondition alloc] init];
	condition.name = [NSString stringWithFormat:@"[%@] -firstOrDefault: %@ success:error:", self.name, defaultValue];

	__block id value = defaultValue;
	__block BOOL done = NO;//done为YES表示已经成功执行了subscribeNext，error，completed这3个操作里面的任意一个。反之为NO。

	// Ensures that we don't pass values across thread boundaries by reference.
	__block NSError *localError;
	__block BOOL localSuccess;

    //由于对原信号进行了take:1操作，所以只会对第一个值进行操作。执行完subscribeNext，error，completed这3个操作里面的任意一个，又会加一次锁，对外部传进来的入参success和error进行赋值，已便外部可以拿到里面的状态。最终返回信号是原信号中第一个next里面的值，如果原信号第一个值没有，比如直接error或者completed，那么返回的是defaultValue。
	[[self take:1] subscribeNext:^(id x) {
		[condition lock];//一般用于多线程同时访问、修改同一个数据源，保证在同一时间内数据源只被访问、修改一次，其他线程的命令需要在lock 外等待，只到unlock ，才可访问

		value = x;//入参defaultValue是给内部变量value的一个初始值。当原信号发送出一个值之后，value的值时刻都会与原信号的值保持一致。
		localSuccess = YES;

		done = YES;
		[condition broadcast];//condition的broadcast操作是唤醒其他线程的操作，相当于操作系统里面互斥信号量的signal操作。
		[condition unlock];
	} error:^(NSError *e) {
		[condition lock];

		if (!done) {
			localSuccess = NO;
			localError = e;

			done = YES;
			[condition broadcast];
		}

		[condition unlock];
	} completed:^{
		[condition lock];

		localSuccess = YES;

		done = YES;
		[condition broadcast];
		[condition unlock];
	}];

	[condition lock];
	while (!done) {
		[condition wait];//让当前线程处于等待状态
	}

    //success和error是外部变量的地址，从外面可以监听到里面的状态。在函数内部赋值，在函数外面拿到它们的值。
	if (success != NULL) *success = localSuccess;
	if (error != NULL) *error = localError;

	[condition unlock];
	return value;
}

/*
 waitUntilCompleted:里面还是调用firstOrDefault: success: error:方法。返回值是success。只要原信号正常的发送完信号，success应该为YES，但是如果发送过程中出现了error，success就为NO。success作为返回值，外部就可以监听到是否发送成功。
 
 虽然这个方法可以监听到发送结束的状态，但是也尽量不要使用，因为它的实现调用了firstOrDefault: success: error:方法，这个方法里面有大量的锁的操作，一不留神就会导致死锁。
 */
- (BOOL)waitUntilCompleted:(NSError **)error {
	BOOL success = NO;

	[[[self
		ignoreValues]
		setNameWithFormat:@"[%@] -waitUntilCompleted:", self.name]
		firstOrDefault:nil success:&success error:error];

	return success;
}

+ (RACSignal *)defer:(RACSignal<id> * (^)(void))block {
	NSCParameterAssert(block != NULL);

	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return [block() subscribe:subscriber];
	}] setNameWithFormat:@"+defer:"];
}

//经过collect之后，原信号所有的值都会被加到一个数组里面，取出信号的第一个值就是一个数组。所以执行完first之后第一个值就是原信号所有值的数组。
- (NSArray *)toArray {
	return [[[self collect] first] copy];
}

- (RACSequence *)sequence {
	return [[RACSignalSequence sequenceWithSignal:self] setNameWithFormat:@"[%@] -sequence", self.name];
}

/*
 publish方法只不过是去调用了multicast:方法，publish内部会新建好一个RACSubject，并把它当成入参传递给RACMulticastConnection。
 同样publish方法也需要手动的调用connect方法。
 */
- (RACMulticastConnection *)publish {
	RACSubject *subject = [[RACSubject subject] setNameWithFormat:@"[%@] -publish", self.name];
	RACMulticastConnection *connection = [self multicast:subject];
	return connection;
}

/*
 调用 multicast:把冷信号转换成热信号有一个点不方便的是，需要自己手动connect。注意转换完之后的热信号在RACMulticastConnection的signal属性中，所以需要订阅的是connection.signal。
 */
- (RACMulticastConnection *)multicast:(RACSubject *)subject {
	[subject setNameWithFormat:@"[%@] -multicast: %@", self.name, subject.name];
	RACMulticastConnection *connection = [[RACMulticastConnection alloc] initWithSourceSignal:self subject:subject];
	return connection;
}

/*
 replay方法会把RACReplaySubject当成RACMulticastConnection的RACSubject传递进去，初始化好了RACMulticastConnection，再自动调用connect方法，返回的信号就是转换好的热信号，即RACMulticastConnection里面的RACSubject信号。
 */
- (RACSignal *)replay {
    /*
     这里必须是RACReplaySubject，因为在replay方法里面先connect了。如果用RACSubject，那信号在connect之后就会通过RACSubject把原信号发送给各个订阅者了。用RACReplaySubject把信号保存起来，即使replay方法里面先connect，订阅者后订阅也是可以拿到之前的信号值的。
     */
	RACReplaySubject *subject = [[RACReplaySubject subject] setNameWithFormat:@"[%@] -replay", self.name];

	RACMulticastConnection *connection = [self multicast:subject];
	[connection connect];

	return connection.signal;
}

/*
 replayLast 和 replay的实现基本一样，唯一的不同就是传入的RACReplaySubject的Capacity是1，意味着只能保存最新的值。所以使用replayLast，订阅之后就只能拿到原信号最新的值。
 */
- (RACSignal *)replayLast {
	RACReplaySubject *subject = [[RACReplaySubject replaySubjectWithCapacity:1] setNameWithFormat:@"[%@] -replayLast", self.name];

	RACMulticastConnection *connection = [self multicast:subject];
	[connection connect];

	return connection.signal;
}


/*
 作用同样是把冷信号转换成热信号
 sourceSignal是在返回的新信号第一次被订阅的时候才被订阅。
 */
- (RACSignal *)replayLazily {
	RACMulticastConnection *connection = [self multicast:[RACReplaySubject subject]];
    /*
     defer 单词的字面意思是延迟的。也和这个函数实现的效果是一致的。只有当defer返回的新信号被订阅的时候，才会执行入参block( )闭包。订阅者会订阅这个block( )闭包的返回值RACSignal。
     */
	return [[RACSignal
		defer:^{
            //block( )闭包被延迟创建RACSignal了，这就是defer。如果block( )闭包含有和时间有关的操作，或者副作用，想要延迟执行，就可以用defer。
			[connection connect];
			return connection.signal;
		}]
		setNameWithFormat:@"[%@] -replayLazily", self.name];
}

- (RACSignal *)timeout:(NSTimeInterval)interval onScheduler:(RACScheduler *)scheduler {
	NSCParameterAssert(scheduler != nil);
	NSCParameterAssert(scheduler != RACScheduler.immediateScheduler);

	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];

        //timeout: onScheduler:的实现很简单，它比正常的信号订阅多了一个timeoutDisposable操作。它在信号订阅的内部开启了一个scheduler，经过interval的时间之后，就会停止订阅原信号，并对订阅者sendError。
		RACDisposable *timeoutDisposable = [scheduler afterDelay:interval schedule:^{
			[disposable dispose];
			[subscriber sendError:[NSError errorWithDomain:RACSignalErrorDomain code:RACSignalErrorTimedOut userInfo:nil]];
		}];

		[disposable addDisposable:timeoutDisposable];

		RACDisposable *subscriptionDisposable = [self subscribeNext:^(id x) {
			[subscriber sendNext:x];
		} error:^(NSError *error) {
			[disposable dispose];
			[subscriber sendError:error];
		} completed:^{
			[disposable dispose];
			[subscriber sendCompleted];
		}];

		[disposable addDisposable:subscriptionDisposable];
		return disposable;
	}] setNameWithFormat:@"[%@] -timeout: %f onScheduler: %@", self.name, (double)interval, scheduler];
}

/*
 deliverOn:的入参是一个scheduler，当原信号subscribeNext，sendError，sendCompleted的时候，都去调用scheduler的schedule方法。
 */
- (RACSignal *)deliverOn:(RACScheduler *)scheduler {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return [self subscribeNext:^(id x) {
			[scheduler schedule:^{
				[subscriber sendNext:x];
			}];
		} error:^(NSError *error) {
			[scheduler schedule:^{
				[subscriber sendError:error];
			}];
		} completed:^{
			[scheduler schedule:^{
				[subscriber sendCompleted];
			}];
		}];
	}] setNameWithFormat:@"[%@] -deliverOn: %@", self.name, scheduler];
}

//subscribeOn:操作就是在传入的scheduler的闭包内部订阅原信号的。它与deliverOn:操作就不同：

//subscribeOn:操作能够保证didSubscribe block( )闭包在入参scheduler中执行，但是不能保证原信号subscribeNext，sendError，sendCompleted在哪个scheduler中执行。
- (RACSignal *)subscribeOn:(RACScheduler *)scheduler {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];

		RACDisposable *schedulingDisposable = [scheduler schedule:^{
			RACDisposable *subscriptionDisposable = [self subscribe:subscriber];

			[disposable addDisposable:subscriptionDisposable];
		}];

		[disposable addDisposable:schedulingDisposable];
		return disposable;
	}] setNameWithFormat:@"[%@] -subscribeOn: %@", self.name, scheduler];
}

- (RACSignal *)deliverOnMainThread {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		__block volatile int32_t queueLength = 0;
		
        //OSAtomicIncrement32 和 OSAtomicDecrement32是原子操作，分别代表+1和-1。下面的if-else判断里面，不管是满足哪一条，最终都还是在主线程中执行block( )闭包。
		void (^performOnMainThread)(dispatch_block_t) = ^(dispatch_block_t block) {
			int32_t queued = OSAtomicIncrement32(&queueLength);
			if (NSThread.isMainThread && queued == 1) {
				block();
				OSAtomicDecrement32(&queueLength);
			} else {
				dispatch_async(dispatch_get_main_queue(), ^{
					block();
					OSAtomicDecrement32(&queueLength);
				});
			}
		};

		return [self subscribeNext:^(id x) {
			performOnMainThread(^{
				[subscriber sendNext:x];
			});
		} error:^(NSError *error) {
			performOnMainThread(^{
				[subscriber sendError:error];
			});
		} completed:^{
			performOnMainThread(^{
				[subscriber sendCompleted];
			});
		}];
	}] setNameWithFormat:@"[%@] -deliverOnMainThread", self.name];
}

- (RACSignal *)groupBy:(id<NSCopying> (^)(id object))keyBlock transform:(id (^)(id object))transformBlock {
	NSCParameterAssert(keyBlock != NULL);

	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		NSMutableDictionary *groups = [NSMutableDictionary dictionary];
		NSMutableArray *orderedGroups = [NSMutableArray array];

		return [self subscribeNext:^(id x) {
			id<NSCopying> key = keyBlock(x);
			RACGroupedSignal *groupSubject = nil;
			@synchronized(groups) {
				groupSubject = groups[key];
				if (groupSubject == nil) {
					groupSubject = [RACGroupedSignal signalWithKey:key];
					groups[key] = groupSubject;
					[orderedGroups addObject:groupSubject];
					[subscriber sendNext:groupSubject];
				}
			}

			[groupSubject sendNext:transformBlock != NULL ? transformBlock(x) : x];
		} error:^(NSError *error) {
			[subscriber sendError:error];

			[orderedGroups makeObjectsPerformSelector:@selector(sendError:) withObject:error];
		} completed:^{
			[subscriber sendCompleted];

			[orderedGroups makeObjectsPerformSelector:@selector(sendCompleted)];
		}];
	}] setNameWithFormat:@"[%@] -groupBy:transform:", self.name];
}

- (RACSignal *)groupBy:(id<NSCopying> (^)(id object))keyBlock {
	return [[self groupBy:keyBlock transform:nil] setNameWithFormat:@"[%@] -groupBy:", self.name];
}

/*
 any操作是any:操作中的一种情况。即predicateBlock闭包永远都返回YES，所以any操作之后永远都只能得到一个只发送一个YES的新信号。
 */
- (RACSignal *)any {
	return [[self any:^(id x) {
		return YES;
	}] setNameWithFormat:@"[%@] -any", self.name];
}

/*
 所以any:操作的目的是找到第一个满足predicateBlock条件的值。找到了就返回YES的RACSignal的信号，如果没有找到，返回NO的RACSignal。
 */
- (RACSignal *)any:(BOOL (^)(id object))predicateBlock {
	NSCParameterAssert(predicateBlock != NULL);

    /*
     原信号会先经过materialize转换包装成RACEvent事件。依次判断predicateBlock(event.value)值的BOOL值，如果返回YES，就包装成RACSignal的新信号，发送YES出去，并且stop接下来的信号。如果返回MO，就返回[RACSignal empty]空信号。直到event.finished，返回[RACSignal return:@NO]。
     */
	return [[[self materialize] bind:^{
		return ^(RACEvent *event, BOOL *stop) {
			if (event.finished) {
				*stop = YES;
				return [RACSignal return:@NO];
			}

			if (predicateBlock(event.value)) {
				*stop = YES;
				return [RACSignal return:@YES];
			}

			return [RACSignal empty];
		};
	}] setNameWithFormat:@"[%@] -any:", self.name];
}

/*
 all:可以用来判断整个原信号发送过程中是否有错误事件RACEventTypeError，或者是否存在predicateBlock为NO的情况。可以把predicateBlock设置成一个正确条件。如果原信号出现错误事件，或者不满足设置的错误条件，都会发送新信号返回NO。如果全过程都没有出错，或者都满足predicateBlock设置的条件，则一直到RACEventTypeCompleted，发送YES的新信号。
 */
- (RACSignal *)all:(BOOL (^)(id object))predicateBlock {
	NSCParameterAssert(predicateBlock != NULL);

	return [[[self materialize] bind:^{
		return ^(RACEvent *event, BOOL *stop) {
			if (event.eventType == RACEventTypeCompleted) {
				*stop = YES;
				return [RACSignal return:@YES];
			}

			if (event.eventType == RACEventTypeError || !predicateBlock(event.value)) {
				*stop = YES;
				return [RACSignal return:@NO];
			}

			return [RACSignal empty];
		};
	}] setNameWithFormat:@"[%@] -all:", self.name];
}

/*
 所以retry:操作的用途就是在原信号在出现error的时候，重试retryCount的次数，如果依旧error，那么就会停止重试。
 如果原信号没有发生错误，那么原信号在发送结束，subscribeForever也就结束了。retry:操作对于没有任何error的信号相当于什么都没有发生。
 */
- (RACSignal *)retry:(NSInteger)retryCount {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		__block NSInteger currentRetryCount = 0;
		return subscribeForever(self,
			^(id x) {
				[subscriber sendNext:x];
			},
			^(NSError *error, RACDisposable *disposable) {
				if (retryCount == 0 || currentRetryCount < retryCount) {
					// Resubscribe.
					currentRetryCount++;
					return;
				}

				[disposable dispose];
				[subscriber sendError:error];
			},
			^(RACDisposable *disposable) {
				[disposable dispose];
				[subscriber sendCompleted];
			});
	}] setNameWithFormat:@"[%@] -retry: %lu", self.name, (unsigned long)retryCount];
}

/*
 这里的retry操作就是一个无限重试的操作。因为retryCount设置成0之后，在error的闭包中中，retryCount 永远等于 0，原信号永远都不会被dispose，所以subscribeForever会一直无限重试下去。
 同样的，如果对一个没有error的信号调用retry操作，也是不起任何作用的。
 */
- (RACSignal *)retry {
	return [[self retry:0] setNameWithFormat:@"[%@] -retry", self.name];
}

- (RACSignal *)sample:(RACSignal *)sampler {
	NSCParameterAssert(sampler != nil);

	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		NSLock *lock = [[NSLock alloc] init];
		__block id lastValue;
		__block BOOL hasValue = NO;

		RACSerialDisposable *samplerDisposable = [[RACSerialDisposable alloc] init];
		RACDisposable *sourceDisposable = [self subscribeNext:^(id x) {
			[lock lock];
			hasValue = YES;
			lastValue = x;
			[lock unlock];
		} error:^(NSError *error) {
			[samplerDisposable dispose];
			[subscriber sendError:error];
		} completed:^{
			[samplerDisposable dispose];
			[subscriber sendCompleted];
		}];

		samplerDisposable.disposable = [sampler subscribeNext:^(id _) {
			BOOL shouldSend = NO;
			id value;
			[lock lock];
			shouldSend = hasValue;
			value = lastValue;
			[lock unlock];

			if (shouldSend) {
				[subscriber sendNext:value];
			}
		} error:^(NSError *error) {
			[sourceDisposable dispose];
			[subscriber sendError:error];
		} completed:^{
			[sourceDisposable dispose];
			[subscriber sendCompleted];
		}];

		return [RACDisposable disposableWithBlock:^{
			[samplerDisposable dispose];
			[sourceDisposable dispose];
		}];
	}] setNameWithFormat:@"[%@] -sample: %@", self.name, sampler];
}

- (RACSignal *)ignoreValues {
	return [[self filter:^(id _) {
		return NO;
	}] setNameWithFormat:@"[%@] -ignoreValues", self.name];
}

- (RACSignal *)materialize {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return [self subscribeNext:^(id x) {
			[subscriber sendNext:[RACEvent eventWithValue:x]];
		} error:^(NSError *error) {
			[subscriber sendNext:[RACEvent eventWithError:error]];
			[subscriber sendCompleted];
		} completed:^{
			[subscriber sendNext:RACEvent.completedEvent];
			[subscriber sendCompleted];
		}];
	}] setNameWithFormat:@"[%@] -materialize", self.name];
}

- (RACSignal *)dematerialize {
	return [[self bind:^{
		return ^(RACEvent *event, BOOL *stop) {
			switch (event.eventType) {
				case RACEventTypeCompleted:
					*stop = YES;
					return [RACSignal empty];

				case RACEventTypeError:
					*stop = YES;
					return [RACSignal error:event.error];

				case RACEventTypeNext:
					return [RACSignal return:event.value];
			}
		};
	}] setNameWithFormat:@"[%@] -dematerialize", self.name];
}

- (RACSignal *)not {
	return [[self map:^(NSNumber *value) {
		NSCAssert([value isKindOfClass:NSNumber.class], @"-not must only be used on a signal of NSNumbers. Instead, got: %@", value);

		return @(!value.boolValue);
	}] setNameWithFormat:@"[%@] -not", self.name];
}

- (RACSignal *)and {
	return [[self map:^(RACTuple *tuple) {
		NSCAssert([tuple isKindOfClass:RACTuple.class], @"-and must only be used on a signal of RACTuples of NSNumbers. Instead, received: %@", tuple);
		NSCAssert(tuple.count > 0, @"-and must only be used on a signal of RACTuples of NSNumbers, with at least 1 value in the tuple");

		return @([tuple.rac_sequence all:^(NSNumber *number) {
			NSCAssert([number isKindOfClass:NSNumber.class], @"-and must only be used on a signal of RACTuples of NSNumbers. Instead, tuple contains a non-NSNumber value: %@", tuple);

			return number.boolValue;
		}]);
	}] setNameWithFormat:@"[%@] -and", self.name];
}

- (RACSignal *)or {
	return [[self map:^(RACTuple *tuple) {
		NSCAssert([tuple isKindOfClass:RACTuple.class], @"-or must only be used on a signal of RACTuples of NSNumbers. Instead, received: %@", tuple);
		NSCAssert(tuple.count > 0, @"-or must only be used on a signal of RACTuples of NSNumbers, with at least 1 value in the tuple");

		return @([tuple.rac_sequence any:^(NSNumber *number) {
			NSCAssert([number isKindOfClass:NSNumber.class], @"-or must only be used on a signal of RACTuples of NSNumbers. Instead, tuple contains a non-NSNumber value: %@", tuple);

			return number.boolValue;
		}]);
	}] setNameWithFormat:@"[%@] -or", self.name];
}

- (RACSignal *)reduceApply {
	return [[self map:^(RACTuple *tuple) {
		NSCAssert([tuple isKindOfClass:RACTuple.class], @"-reduceApply must only be used on a signal of RACTuples. Instead, received: %@", tuple);
		NSCAssert(tuple.count > 1, @"-reduceApply must only be used on a signal of RACTuples, with at least a block in tuple[0] and its first argument in tuple[1]");

		// We can't use -array, because we need to preserve RACTupleNil
		NSMutableArray *tupleArray = [NSMutableArray arrayWithCapacity:tuple.count];
		for (id val in tuple) {
			[tupleArray addObject:val];
		}
		RACTuple *arguments = [RACTuple tupleWithObjectsFromArray:[tupleArray subarrayWithRange:NSMakeRange(1, tupleArray.count - 1)]];

		return [RACBlockTrampoline invokeBlock:tuple[0] withArguments:arguments];
	}] setNameWithFormat:@"[%@] -reduceApply", self.name];
}

@end
