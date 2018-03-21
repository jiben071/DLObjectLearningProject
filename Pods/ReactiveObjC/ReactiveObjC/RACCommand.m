//
//  RACCommand.m
//  ReactiveObjC
//
//  Created by Josh Abernathy on 3/3/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACCommand.h"
#import <ReactiveObjC/RACEXTScope.h>
#import "NSArray+RACSequenceAdditions.h"
#import "NSObject+RACDeallocating.h"
#import "NSObject+RACDescription.h"
#import "NSObject+RACPropertySubscribing.h"
#import "RACMulticastConnection.h"
#import "RACReplaySubject.h"
#import "RACScheduler.h"
#import "RACSequence.h"
#import "RACSignal+Operations.h"
#import <libkern/OSAtomic.h>

NSString * const RACCommandErrorDomain = @"RACCommandErrorDomain";
NSString * const RACUnderlyingCommandErrorKey = @"RACUnderlyingCommandErrorKey";

const NSInteger RACCommandErrorNotEnabled = 1;

@interface RACCommand () {
	// Atomic backing variable for `allowsConcurrentExecution`.
	volatile uint32_t _allowsConcurrentExecution;
}

/// A subject that sends added execution signals.
@property (nonatomic, strong, readonly) RACSubject *addedExecutionSignalsSubject;

/// A subject that sends the new value of `allowsConcurrentExecution` whenever it changes.
@property (nonatomic, strong, readonly) RACSubject *allowsConcurrentExecutionSubject;

// `enabled`, but without a hop to the main thread.
//
// Values from this signal may arrive on any thread.
@property (nonatomic, strong, readonly) RACSignal *immediateEnabled;

// The signal block that the receiver was initialized with.接收器初始化的信号块。
@property (nonatomic, copy, readonly) RACSignal * (^signalBlock)(id input);

@end

@implementation RACCommand

#pragma mark Properties
//allowsConcurrentExecution这个变量在具体实现中是用的volatile原子的操作，在实现中重写了它的get和set方法。
- (BOOL)allowsConcurrentExecution {
	return _allowsConcurrentExecution != 0;
}

/*
 OSAtomicOr32Barrier是原子运算，它的意义是进行逻辑的“或”运算。通过原子性操作访问被volatile修饰的_allowsConcurrentExecution对象即可保障函数只执行一次。
 相应的OSAtomicAnd32Barrier也是原子运算，它的意义是进行逻辑的“与”运算。
 */
- (void)setAllowsConcurrentExecution:(BOOL)allowed {
	if (allowed) {
		OSAtomicOr32Barrier(1, &_allowsConcurrentExecution);//在指定的32位值和32位掩码之间执行逻辑或。
	} else {
		OSAtomicAnd32Barrier(0, &_allowsConcurrentExecution);//在指定的32位值和32位掩码之间执行逻辑与。
	}

	[self.allowsConcurrentExecutionSubject sendNext:@(_allowsConcurrentExecution)];
}

#pragma mark Lifecycle

- (instancetype)init {
	NSCAssert(NO, @"Use -initWithSignalBlock: instead");
	return nil;
}

- (instancetype)initWithSignalBlock:(RACSignal<id> * (^)(id input))signalBlock {
	return [self initWithEnabled:nil signalBlock:signalBlock];
}

- (void)dealloc {
	[_addedExecutionSignalsSubject sendCompleted];
	[_allowsConcurrentExecutionSubject sendCompleted];
}

- (instancetype)initWithEnabled:(RACSignal *)enabledSignal signalBlock:(RACSignal<id> * (^)(id input))signalBlock {
	NSCParameterAssert(signalBlock != nil);

	self = [super init];

	_addedExecutionSignalsSubject = [RACSubject new];//添加可执行信号的信号
	_allowsConcurrentExecutionSubject = [RACSubject new];//允许并发执行信号的信号
	_signalBlock = [signalBlock copy];//需要执行的signal

    //需要执行的信号
	_executionSignals = [[[self.addedExecutionSignalsSubject
		map:^(RACSignal *signal) {//映射
            /*
             executionSignals把newActiveExecutionSignals中错误信号都换成空信号。经过map变换之后，executionSignals是newActiveExecutionSignals的无错误信号的版本。由于map只是变换并没有降阶，所以executionSignals还是一个二阶的高阶冷信号。
             */
            return [signal catchTo:[RACSignal empty]];//catchTo:发生错误时订阅给定的信号。
		}]
		deliverOn:RACScheduler.mainThreadScheduler]
		setNameWithFormat:@"%@ -executionSignals", self];
	// 错误需要可以多点传送
	// `errors` needs to be multicasted so that it picks up all
	// `activeExecutionSignals` that are added.
	//
	// In other words, if someone subscribes to `errors` _after_ an execution
	// has started, it should still receive any error from that execution.
    // 错误处理：
    
    /*
     在RACCommand中会搜集其所有的error信号，都装进自己的errors的信号中。这也是RACCommand的特点之一，能把错误统一处理。
     这里在errorsConnection的变换中，我们对这个二阶的热信号进行flattenMap:降阶操作，只留下所有的错误信号，最后把所有的错误信号都装在一个低阶的信号中，这个信号中每个值都是一个error。同样，变换中也追加了deliverOn:操作，回到主线程中去操作。最后把这个冷信号转换成热信号，但是注意，还没有connect。
     假设某个订阅者在RACCommand中的信号已经开始执行之后才订阅的，如果错误信号是一个冷信号，那么订阅之前的错误就接收不到了。所以错误应该是一个热信号，不管什么时候订阅都可以接收到所有的错误。
     */
	RACMulticastConnection *errorsConnection = [[[self.addedExecutionSignalsSubject
		flattenMap:^(RACSignal *signal) {
			return [[signal
				ignoreValues]
				catch:^(NSError *error) {
					return [RACSignal return:error];
				}];
		}]
		deliverOn:RACScheduler.mainThreadScheduler]
		publish];
	
    /*
     error信号就是热信号errorsConnection传出来的一个热信号。error信号每个值都是在主线程上发送的。
     */
	_errors = [errorsConnection.signal setNameWithFormat:@"%@ -errors", self];
	[errorsConnection connect];

    //立即执行的信号
	RACSignal *immediateExecuting = [[[[self.addedExecutionSignalsSubject
		flattenMap:^(RACSignal *signal) {
			return [[[signal
				catchTo:[RACSignal empty]]//发生错误时订阅给定的信号。
                     then:^{//忽略来自接收器的所有“next”，等待接收器完成，然后订阅一个新的信号。
					return [RACSignal return:@-1];
				}]
                    startWith:@1];//startWith:Returns a signal consisting of `value`
		}]
		scanWithStart:@0 reduce:^(NSNumber *running, NSNumber *next) {
			return @(running.integerValue + next.integerValue);//实现遍历累加的效果
		}]
		map:^(NSNumber *count) {
			return @(count.integerValue > 0);
		}]
		startWith:@NO];

    /*
     immediateExecuting信号表示当前是否有信号在执行。初始值为NO，一旦immediateExecuting不为NO的时候就会发出信号。最后通过replayLast转换成永远只保存最新的一个值的热信号。
     */
	_executing = [[[[[immediateExecuting
		deliverOn:RACScheduler.mainThreadScheduler]
		// This is useful before the first value arrives on the main thread.
		startWith:@NO]
		distinctUntilChanged]
		replayLast]
		setNameWithFormat:@"%@ -executing", self];
	
    // Switches between `trueSignal` and `falseSignal` based on the latest value sent by `boolSignal`.
    /*
     先监听self.allowsConcurrentExecution变量是否有变化，allowsConcurrentExecution默认值为NO。如果有变化，allowsConcurrentExecution为YES，就说明允许并发执行，那么就返回YES的RACSignal，allowsConcurrentExecution为NO，就说明不允许并发执行，那么就要看当前是否有正在执行的信号。immediateExecuting就是代表当前是否有在执行的信号，对这个信号取非，就是是否允许执行下一个信号的BOOL值。这就是moreExecutionsAllowed的信号。
     */
	RACSignal *moreExecutionsAllowed = [RACSignal
		if:[self.allowsConcurrentExecutionSubject startWith:@NO]
		then:[RACSignal return:@YES]
		else:[immediateExecuting not]];//Inverts each NSNumber-wrapped BOOL sent by the receiver.
	
	if (enabledSignal == nil) {
		enabledSignal = [RACSignal return:@YES];//默认允许执行
	} else {
        //如果enabledSignal不为nil，就在enabledSignal信号前面插入一个YES的信号，目的是为了防止传入的enabledSignal虽然不为nil，但是里面是没有信号的，比如[RACSignal never]，[RACSignal empty]，这些信号传进来也相当于是没用的，所以在开头加一个YES的初始值信号。
		enabledSignal = [enabledSignal startWith:@YES];
	}
	
    /*
     这个信号也是一个enabled信号，但是和之前的enabled信号不同的是，它并不能保证在main thread主线程上，它可以在任意一个线程上。
     immediateEnabled信号的意义就是每时每刻监听RACCommand是否可以enabled。它是由2个信号进行and操作得来的。每当allowsConcurrentExecution变化的时候就会产生一个信号，此时再加上enabledSignal信号，就能判断这一刻RACCommand是否能够enabled。每当enabledSignal变化的时候也会产生一个信号，再加上allowsConcurrentExecution是否允许并发，也能判断这一刻RACCommand是否能够enabled。所以immediateEnabled是由这两个信号combineLatest:之后再进行and操作得来的。
     */
	_immediateEnabled = [[[[RACSignal
		combineLatest:@[ enabledSignal, moreExecutionsAllowed ]]//combineLatest:的作用就是把后面数组里面传入的每个信号，不管是谁发送出来一个信号，都会把数组里面所有信号的最新的值组合到一个RACTuple里面。
		and]//immediateEnabled会把每个RACTuple里面的元素都进行逻辑and运算，这样immediateEnabled信号里面装的也都是BOOL值了。
		takeUntil:self.rac_willDeallocSignal]
		replayLast];//最后同样通过replayLast操作转换成只保存最新的一个值的热信号。
	
    /*
     concat
     通过查看文档，明白了作者的意图，作者的目的是为了让第一个值以后的每个值都发送在主线程上，所以这里skip:1之后接着deliverOn:RACScheduler.mainThreadScheduler。那第一个值呢？第一个值在一订阅的时候就发送出去了，同订阅者所在线程一致。
     从源码上看，enabled信号除去第一个值以外的每个值也都是在主线程上发送的。
     */
	_enabled = [[[[[self.immediateEnabled
		take:1]//表示这个信号只执行一次
        concat:[[self.immediateEnabled skip:1] deliverOn:RACScheduler.mainThreadScheduler]]//concat:当源信号完成时，订阅传入的信号。
		distinctUntilChanged]//distinctUntilChanged保证enabled信号每次状态变化的时候只取到一个状态值
		replayLast]//最后调用replayLast转换成只保存最新值的热信号。
		setNameWithFormat:@"%@ -enabled", self];

	return self;
}

#pragma mark Execution

- (RACSignal *)execute:(id)input {
	// `immediateEnabled` is guaranteed to send a value upon subscription, so
	// -first is acceptable here.
    /*
     self.immediateEnabled为了保证第一个值能正常的发送给订阅者，所以这里用了同步的first的方法，也是可以接受的。调用了first方法之后，根据这第一个值来判断RACCommand是否可以开始执行。如果不能执行就返回一个错误信号。
     */
	BOOL enabled = [[self.immediateEnabled first] boolValue];//first获取第一个next的值
	if (!enabled) {
		NSError *error = [NSError errorWithDomain:RACCommandErrorDomain code:RACCommandErrorNotEnabled userInfo:@{
			NSLocalizedDescriptionKey: NSLocalizedString(@"The command is disabled and cannot be executed", nil),
			RACUnderlyingCommandErrorKey: self
		}];

		return [RACSignal error:error];
	}

    /*
     这里就是RACCommand开始执行的地方。self.signalBlock是RACCommand在初始化的时候传入的一个参数，RACSignal * (^signalBlock)(id input)这个闭包的入参是一个id input，返回值是一个信号。这里正好把execute的入参input传进来。
     */
	RACSignal *signal = self.signalBlock(input);
	NSCAssert(signal != nil, @"nil signal returned from signal block for value: %@", input);

	// We subscribe to the signal on the main thread so that it occurs _after_
	// -addActiveExecutionSignal: completes below.
	//
	// This means that `executing` and `enabled` will send updated values before
	// the signal actually starts performing work.
	RACMulticastConnection *connection = [[signal
		subscribeOn:RACScheduler.mainThreadScheduler]//把RACCommand执行之后的信号先调用subscribeOn:保证didSubscribe block( )闭包在主线程中执行
		multicast:[RACReplaySubject subject]];//转换成RACMulticastConnection，准备转换成热信号。
	
    //在最终的信号被订阅者订阅之前，我们需要优先更新RACCommand里面的executing和enabled信号，所以这里要先把connection.signal加入到self.activeExecutionSignals数组里面。
	[self.addedExecutionSignalsSubject sendNext:connection.signal];

	[connection connect];
    /*
     executionSignals虽然是一个冷信号，但是它是由内部的addedExecutionSignalsSubject的产生的，这是一个热信号，订阅者订阅它的时候需要在execute:执行之前去订阅，否则这个addedExecutionSignalsSubject热信号对已保存的所有的订阅者发送完信号以后，再订阅就收不到任何信号了。所以需要在热信号发送信号之前订阅，把自己保存到热信号的订阅者数组里。所以executionSignals的订阅要在execute:执行之前。
     
     而execute:返回的信号是RACReplaySubject热信号，它会把订阅者保存起来，即使先发送信号，再订阅，订阅者也可以收到之前发送的值。
     这里想说明的是，最终的execute:返回的信号，和executionSignals是一样的。
     两个信号虽然信号内容都相同，但是订阅的先后次序不同，executionSignals必须在execute:执行之前去订阅，而execute:返回的信号是在execute:执行之后去订阅的。
     */

	return [connection.signal setNameWithFormat:@"%@ -execute: %@", self, RACDescription(input)];
}

@end
