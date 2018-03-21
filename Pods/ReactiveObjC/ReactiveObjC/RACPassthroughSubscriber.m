//
//  RACPassthroughSubscriber.m
//  ReactiveObjC
//
//  Created by Justin Spahr-Summers on 2013-06-13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "RACPassthroughSubscriber.h"
#import "RACCompoundDisposable.h"
#import "RACSignal.h"
#import "RACSignalProvider.h"

#if !defined(DTRACE_PROBES_DISABLED) || !DTRACE_PROBES_DISABLED

static const char *cleanedDTraceString(NSString *original) {
	return [original stringByReplacingOccurrencesOfString:@"\\s+" withString:@" " options:NSRegularExpressionSearch range:NSMakeRange(0, original.length)].UTF8String;
}

static const char *cleanedSignalDescription(RACSignal *signal) {
	NSString *desc = signal.description;

	NSRange range = [desc rangeOfString:@" name:"];
	if (range.location != NSNotFound) {
		desc = [desc stringByReplacingCharactersInRange:range withString:@""];
	}

	return cleanedDTraceString(desc);
}

#endif

@interface RACPassthroughSubscriber ()

// The subscriber to which events should be forwarded.
@property (nonatomic, strong, readonly) id<RACSubscriber> innerSubscriber;

// The signal sending events to this subscriber.
//
// This property isn't `weak` because it's only used for DTrace probes, so
// a zeroing weak reference would incur an unnecessary performance penalty in
// normal usage.
// 这里需要注意的是内部还保存了一个RACSignal，并且它的属性是unsafe_unretained。这里和其他两个属性有区别， 其他两个属性都是strong的。这里之所以不是weak，是因为引用RACSignal仅仅只是一个DTrace probes动态跟踪技术的探针。如果设置成weak，会造成没必要的性能损失。所以这里仅仅是unsafe_unretained就够了。
@property (nonatomic, unsafe_unretained, readonly) RACSignal *signal;

// A disposable representing the subscription. When disposed, no further events
// should be sent to the `innerSubscriber`.
@property (nonatomic, strong, readonly) RACCompoundDisposable *disposable;

@end

@implementation RACPassthroughSubscriber

#pragma mark Lifecycle

- (instancetype)initWithSubscriber:(id<RACSubscriber>)subscriber signal:(RACSignal *)signal disposable:(RACCompoundDisposable *)disposable {
	NSCParameterAssert(subscriber != nil);

	self = [super init];

	_innerSubscriber = subscriber;//待转发的信号的订阅者subscriber。
	_signal = signal;
	_disposable = disposable;//订阅者的销毁对象，一旦它被disposed了，innerSubscriber就再也接受不到事件流了。

	[self.innerSubscriber didSubscribeWithDisposable:self.disposable];
	return self;
}

#pragma mark RACSubscriber

- (void)sendNext:(id)value {
	if (self.disposable.disposed) return;

	if (RACSIGNAL_NEXT_ENABLED()) {
		RACSIGNAL_NEXT(cleanedSignalDescription(self.signal), cleanedDTraceString(self.innerSubscriber.description), cleanedDTraceString([value description]));
	}

	[self.innerSubscriber sendNext:value];
}

- (void)sendError:(NSError *)error {
	if (self.disposable.disposed) return;

	if (RACSIGNAL_ERROR_ENABLED()) {
		RACSIGNAL_ERROR(cleanedSignalDescription(self.signal), cleanedDTraceString(self.innerSubscriber.description), cleanedDTraceString(error.description));
	}

	[self.innerSubscriber sendError:error];
}

- (void)sendCompleted {
	if (self.disposable.disposed) return;

	if (RACSIGNAL_COMPLETED_ENABLED()) {
		RACSIGNAL_COMPLETED(cleanedSignalDescription(self.signal), cleanedDTraceString(self.innerSubscriber.description));
	}

	[self.innerSubscriber sendCompleted];
}

- (void)didSubscribeWithDisposable:(RACCompoundDisposable *)disposable {
	if (disposable != self.disposable) {
		[self.disposable addDisposable:disposable];
	}
}

@end
