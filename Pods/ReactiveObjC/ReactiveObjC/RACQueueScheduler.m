//
//  RACQueueScheduler.m
//  ReactiveObjC
//
//  Created by Josh Abernathy on 11/30/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACQueueScheduler.h"
#import "RACDisposable.h"
#import "RACQueueScheduler+Subclass.h"
#import "RACScheduler+Private.h"

@implementation RACQueueScheduler

#pragma mark Lifecycle

- (instancetype)initWithName:(NSString *)name queue:(dispatch_queue_t)queue {
	NSCParameterAssert(queue != NULL);

	self = [super initWithName:name];

	_queue = queue;
#if !OS_OBJECT_USE_OBJC
	dispatch_retain(_queue);
#endif

	return self;
}

#if !OS_OBJECT_USE_OBJC

- (void)dealloc {
	if (_queue != NULL) {
		dispatch_release(_queue);
		_queue = NULL;
	}
}

#endif

#pragma mark Date Conversions

+ (dispatch_time_t)wallTimeWithDate:(NSDate *)date {
	NSCParameterAssert(date != nil);

	double seconds = 0;
	double frac = modf(date.timeIntervalSince1970, &seconds);

	struct timespec walltime = {
		.tv_sec = (time_t)fmin(fmax(seconds, LONG_MIN), LONG_MAX),
		.tv_nsec = (long)fmin(fmax(frac * NSEC_PER_SEC, LONG_MIN), LONG_MAX)
	};

	return dispatch_walltime(&walltime, 0);
}

#pragma mark RACScheduler

- (RACDisposable *)schedule:(void (^)(void))block {
	NSCParameterAssert(block != NULL);

	RACDisposable *disposable = [[RACDisposable alloc] init];

	dispatch_async(self.queue, ^{
		if (disposable.disposed) return;
		[self performAsCurrentScheduler:block];
	});

	return disposable;
}

- (RACDisposable *)after:(NSDate *)date schedule:(void (^)(void))block {
	NSCParameterAssert(date != nil);
	NSCParameterAssert(block != NULL);

	RACDisposable *disposable = [[RACDisposable alloc] init];

    /*
     这样也就达到了节流的目的：原来每个信号都会创建一个delayScheduler，都会延迟interval的时间，在这个时间内，如果原信号再没有发送新值，即原信号没有disposed，就把原信号的值发出来；如果在这个时间内，原信号还发送了一个新值，那么第一个值就被丢弃。在发送过程中，每个信号都要判断一次predicate( )，这个是阀门的开关，如果随时都不节流了，原信号发的值就需要立即被发送出来。
     
     还有二点需要注意的是，第一点，正好在interval那一时刻，有新信号发送出来，原信号也会被丢弃，即只有在>=interval的时间之内，原信号没有发送新值，原来的这个值才能发送出来。第二点，原信号发送completed时，会立即执行flushNext(YES)，把原信号的最后一个值发送出来。
     */
	dispatch_after([self.class wallTimeWithDate:date], self.queue, ^{
		if (disposable.disposed) return;//这个判断就是用来判断从第一个信号发出，在间隔interval的时间之内，还有没有其他信号存在。如果有，第一个信号肯定会disposed，这里会执行return，所以也就不会把第一个信号发送出来了。
		[self performAsCurrentScheduler:block];
	});

	return disposable;
}

/*
 leeway这个参数是为dispatch source指定一个期望的定时器事件精度，让系统能够灵活地管理并唤醒内核。例如系统可以使用leeway值来提前或延迟触发定时器，使其更好地与其它系统事件结合。创建自己的定时器时，应该尽量指定一个leeway值。不过就算指定leeway值为0，也不能完完全全期望定时器能够按照精确的纳秒来触发事件。
 
 这里的实现就是用GCD在self.queue上创建了一个Timer，时间间隔是interval，修正时间是leeway。
 */
- (RACDisposable *)after:(NSDate *)date repeatingEvery:(NSTimeInterval)interval withLeeway:(NSTimeInterval)leeway schedule:(void (^)(void))block {
	NSCParameterAssert(date != nil);
	NSCParameterAssert(interval > 0.0 && interval < INT64_MAX / NSEC_PER_SEC);
	NSCParameterAssert(leeway >= 0.0 && leeway < INT64_MAX / NSEC_PER_SEC);
	NSCParameterAssert(block != NULL);

	uint64_t intervalInNanoSecs = (uint64_t)(interval * NSEC_PER_SEC);
	uint64_t leewayInNanoSecs = (uint64_t)(leeway * NSEC_PER_SEC);

    //这个定时器在interval执行sendNext操作，也就是发送原信号的值。
	dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.queue);
	dispatch_source_set_timer(timer, [self.class wallTimeWithDate:date], intervalInNanoSecs, leewayInNanoSecs);
	dispatch_source_set_event_handler(timer, block);
	dispatch_resume(timer);

	return [RACDisposable disposableWithBlock:^{
		dispatch_source_cancel(timer);
	}];
}

@end
