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
		return signal;
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

- (RACSignal *)try:(BOOL (^)(id value, NSError **errorPtr))tryBlock {
	NSCParameterAssert(tryBlock != NULL);

	return [[self flattenMap:^(id value) {
		NSError *error = nil;
		BOOL passed = tryBlock(value, &error);
		return (passed ? [RACSignal return:value] : [RACSignal error:error]);
	}] setNameWithFormat:@"[%@] -try:", self.name];
}

- (RACSignal *)tryMap:(id (^)(id value, NSError **errorPtr))mapBlock {
	NSCParameterAssert(mapBlock != NULL);

	return [[self flattenMap:^(id value) {
		NSError *error = nil;
		id mappedValue = mapBlock(value, &error);
		return (mappedValue == nil ? [RACSignal error:error] : [RACSignal return:mappedValue]);
	}] setNameWithFormat:@"[%@] -tryMap:", self.name];
}

- (RACSignal *)initially:(void (^)(void))block {
	NSCParameterAssert(block != NULL);

	return [[RACSignal defer:^{
		block();
		return self;
	}] setNameWithFormat:@"[%@] -initially:", self.name];
}

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

- (RACSignal *)flatten:(NSUInteger)maxConcurrent {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACCompoundDisposable *compoundDisposable = [[RACCompoundDisposable alloc] init];

		// Contains disposables for the currently active subscriptions.
		//
		// This should only be used while synchronized on `subscriber`.
		NSMutableArray *activeDisposables = [[NSMutableArray alloc] initWithCapacity:maxConcurrent];

		// Whether the signal-of-signals has completed yet.
		//
		// This should only be used while synchronized on `subscriber`.
		__block BOOL selfCompleted = NO;

		// Subscribes to the given signal.
		__block void (^subscribeToSignal)(RACSignal *);

		// Weak reference to the above, to avoid a leak.
		__weak __block void (^recur)(RACSignal *);

		// Sends completed to the subscriber if all signals are finished.
		//
		// This should only be used while synchronized on `subscriber`.
		void (^completeIfAllowed)(void) = ^{
			if (selfCompleted && activeDisposables.count == 0) {
				[subscriber sendCompleted];
			}
		};

		// The signals waiting to be started.
		//
		// This array should only be used while synchronized on `subscriber`.
		NSMutableArray *queuedSignals = [NSMutableArray array];

		recur = subscribeToSignal = ^(RACSignal *signal) {
			RACSerialDisposable *serialDisposable = [[RACSerialDisposable alloc] init];

			@synchronized (subscriber) {
				[compoundDisposable addDisposable:serialDisposable];
				[activeDisposables addObject:serialDisposable];
			}

			serialDisposable.disposable = [signal subscribeNext:^(id x) {
				[subscriber sendNext:x];
			} error:^(NSError *error) {
				[subscriber sendError:error];
			} completed:^{
				__strong void (^subscribeToSignal)(RACSignal *) = recur;
				RACSignal *nextSignal;

				@synchronized (subscriber) {
					[compoundDisposable removeDisposable:serialDisposable];
					[activeDisposables removeObjectIdenticalTo:serialDisposable];

					if (queuedSignals.count == 0) {
						completeIfAllowed();
						return;
					}

					nextSignal = queuedSignals[0];
					[queuedSignals removeObjectAtIndex:0];
				}

				subscribeToSignal(nextSignal);
			}];
		};

		[compoundDisposable addDisposable:[self subscribeNext:^(RACSignal *signal) {
			if (signal == nil) return;

			NSCAssert([signal isKindOfClass:RACSignal.class], @"Expected a RACSignal, got %@", signal);

			@synchronized (subscriber) {
				if (maxConcurrent > 0 && activeDisposables.count >= maxConcurrent) {
					[queuedSignals addObject:signal];

					// If we need to wait, skip subscribing to this
					// signal.
					return;
				}
			}

			subscribeToSignal(signal);
		} error:^(NSError *error) {
			[subscriber sendError:error];
		} completed:^{
			@synchronized (subscriber) {
				selfCompleted = YES;
				completeIfAllowed();
			}
		}]];

		[compoundDisposable addDisposable:[RACDisposable disposableWithBlock:^{
			// A strong reference is held to `subscribeToSignal` until we're
			// done, preventing it from deallocating early.
			subscribeToSignal = nil;
		}]];

		return compoundDisposable;
	}] setNameWithFormat:@"[%@] -flatten: %lu", self.name, (unsigned long)maxConcurrent];
}

- (RACSignal *)then:(RACSignal * (^)(void))block {
	NSCParameterAssert(block != nil);

	return [[[self
		ignoreValues]
		concat:[RACSignal defer:block]]
		setNameWithFormat:@"[%@] -then:", self.name];
}

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
			[bindings removeObjectForKey:keyPath];
		}
		#endif

		while (YES) {
			void *ptr = objectPtr;
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

- (RACSignal *)switchToLatest {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACMulticastConnection *connection = [self publish];

		RACDisposable *subscriptionDisposable = [[connection.signal
			flattenMap:^(RACSignal *x) {
				NSCAssert(x == nil || [x isKindOfClass:RACSignal.class], @"-switchToLatest requires that the source signal (%@) send signals. Instead we got: %@", self, x);

				// -concat:[RACSignal never] prevents completion of the receiver from
				// prematurely terminating the inner signal.
				return [x takeUntil:[connection.signal concat:[RACSignal never]]];
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

			return signal;
		}]
		switchToLatest]
		setNameWithFormat:@"+switch: %@ cases: %@ default: %@", signal, cases, defaultSignal];
}

+ (RACSignal *)if:(RACSignal *)boolSignal then:(RACSignal *)trueSignal else:(RACSignal *)falseSignal {
	NSCParameterAssert(boolSignal != nil);
	NSCParameterAssert(trueSignal != nil);
	NSCParameterAssert(falseSignal != nil);

	return [[[boolSignal
		map:^(NSNumber *value) {
			NSCAssert([value isKindOfClass:NSNumber.class], @"Expected %@ to send BOOLs, not %@", boolSignal, value);

			return (value.boolValue ? trueSignal : falseSignal);
		}]
		switchToLatest]
		setNameWithFormat:@"+if: %@ then: %@ else: %@", boolSignal, trueSignal, falseSignal];
}

- (id)first {
	return [self firstOrDefault:nil];
}

- (id)firstOrDefault:(id)defaultValue {
	return [self firstOrDefault:defaultValue success:NULL error:NULL];
}

- (id)firstOrDefault:(id)defaultValue success:(BOOL *)success error:(NSError **)error {
    /*
     NSCondition 的对象实际上作为一个锁和一个线程检查器：锁主要为了当检测条件时保护数据源，执行条件引发的任务；线程检查器主要是根据条件决定是否继续运行线程，即线程是否被阻塞。
     */
	NSCondition *condition = [[NSCondition alloc] init];
	condition.name = [NSString stringWithFormat:@"[%@] -firstOrDefault: %@ success:error:", self.name, defaultValue];

	__block id value = defaultValue;
	__block BOOL done = NO;

	// Ensures that we don't pass values across thread boundaries by reference.
	__block NSError *localError;
	__block BOOL localSuccess;

	[[self take:1] subscribeNext:^(id x) {
		[condition lock];//一般用于多线程同时访问、修改同一个数据源，保证在同一时间内数据源只被访问、修改一次，其他线程的命令需要在lock 外等待，只到unlock ，才可访问

		value = x;
		localSuccess = YES;

		done = YES;
		[condition broadcast];
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

	if (success != NULL) *success = localSuccess;
	if (error != NULL) *error = localError;

	[condition unlock];
	return value;
}

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

- (NSArray *)toArray {
	return [[[self collect] first] copy];
}

- (RACSequence *)sequence {
	return [[RACSignalSequence sequenceWithSignal:self] setNameWithFormat:@"[%@] -sequence", self.name];
}

- (RACMulticastConnection *)publish {
	RACSubject *subject = [[RACSubject subject] setNameWithFormat:@"[%@] -publish", self.name];
	RACMulticastConnection *connection = [self multicast:subject];
	return connection;
}

- (RACMulticastConnection *)multicast:(RACSubject *)subject {
	[subject setNameWithFormat:@"[%@] -multicast: %@", self.name, subject.name];
	RACMulticastConnection *connection = [[RACMulticastConnection alloc] initWithSourceSignal:self subject:subject];
	return connection;
}

- (RACSignal *)replay {
	RACReplaySubject *subject = [[RACReplaySubject subject] setNameWithFormat:@"[%@] -replay", self.name];

	RACMulticastConnection *connection = [self multicast:subject];
	[connection connect];

	return connection.signal;
}

- (RACSignal *)replayLast {
	RACReplaySubject *subject = [[RACReplaySubject replaySubjectWithCapacity:1] setNameWithFormat:@"[%@] -replayLast", self.name];

	RACMulticastConnection *connection = [self multicast:subject];
	[connection connect];

	return connection.signal;
}

- (RACSignal *)replayLazily {
	RACMulticastConnection *connection = [self multicast:[RACReplaySubject subject]];
	return [[RACSignal
		defer:^{
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
