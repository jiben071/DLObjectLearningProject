//
//  RACCommand.h
//  ReactiveObjC
//
//  Created by Josh Abernathy on 3/3/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACSignal<__covariant ValueType>;

NS_ASSUME_NONNULL_BEGIN

/// The domain for errors originating within `RACCommand`.
/// 错误域
extern NSString * const RACCommandErrorDomain;

/// -execute: was invoked while the command was disabled.
extern const NSInteger RACCommandErrorNotEnabled;

/// A `userInfo` key for an error, associated with the `RACCommand` that the
/// error originated from.
///
/// This is included only when the error code is `RACCommandErrorNotEnabled`.
extern NSString * const RACUnderlyingCommandErrorKey;

/// A command is a signal triggered in response to some action, typically
/// UI-related.
///
/*
 covariant && contravariant
 __covariant : 子类型可以强转到父类型（里氏替换原则）
 __contravariant : 父类型可以强转到子类型（WTF?）
 */
@interface RACCommand<__contravariant InputType, __covariant ValueType> : NSObject

/// A signal of the signals returned by successful invocations of -execute:
/// (i.e., while the receiver is `enabled`).
///
/// Errors will be automatically caught upon the inner signals, and sent upon
/// `errors` instead. If you _want_ to receive inner errors, use -execute: or
/// -[RACSignal materialize].
/// 
/// Only executions that begin _after_ subscription will be sent upon this
/// signal. All inner signals will arrive upon the main thread.//主线程执行
/*
 executionSignals是一个高阶信号，所以在使用的时候需要进行降阶操作，降价操作在前面分析过了，在ReactiveCocoa v2.5中只支持3种降阶方式，flatten，switchToLatest，concat。降阶的方式就根据需求来选取。
 
 还有选择原则是，如果在不允许Concurrent并发的RACCommand中一般使用switchToLatest。如果在允许Concurrent并发的RACCommand中一般使用flatten。
 */
@property (nonatomic, strong, readonly) RACSignal<RACSignal<ValueType> *> *executionSignals;

/// A signal of whether this command is currently executing.
///
/// This will send YES whenever -execute: is invoked and the created signal has
/// not yet terminated. Once all executions have terminated, `executing` will
/// send NO.
///
/// This signal will send its current value upon subscription, and then all
/// future values on the main thread.
/*
 executing这个信号就表示了当前RACCommand是否在执行，信号里面的值都是BOOL类型的。YES表示的是RACCommand正在执行过程中，命名也说明的是正在进行时ing。NO表示的是RACCommand没有被执行或者已经执行结束。
 */
@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *executing;

/// A signal of whether this command is able to execute.
///
/// This will send NO if:
///
///  - The command was created with an `enabledSignal`, and NO is sent upon that
///    signal, or
///  - `allowsConcurrentExecution` is NO and the command has started executing.
///
/// Once the above conditions are no longer met, the signal will send YES.
///
/// This signal will send its current value upon subscription, and then all
/// future values on the main thread.
/*
 enabled信号就是一个开关，RACCommand是否可用。这个信号除去以下2种情况会返回NO：
 
 RACCommand 初始化传入的enabledSignal信号，如果返回NO，那么enabled信号就返回NO。
 RACCommand开始执行中，allowsConcurrentExecution为NO，那么enabled信号就返回NO。
 除去以上2种情况以外，enabled信号基本都是返回YES。
 */
@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *enabled;

/// Forwards any errors that occur within signals returned by -execute:.
///
/// When an error occurs on a signal returned from -execute:, this signal will
/// send the associated NSError value as a `next` event (since an `error` event
/// would terminate the stream).
///
/// After subscription, this signal will send all future errors on the main
/// thread.
/*
 errors信号就是RACCommand执行过程中产生的错误信号。这里特别需要注意的是：在对RACCommand进行错误处理的时候，我们不应该使用subscribeError:对RACCommand的executionSignals
 进行错误的订阅，因为executionSignals这个信号是不会发送error事件的，那当RACCommand包裹的信号发送error事件时，我们要怎样去订阅到它呢？应该用subscribeNext:去订阅错误信号。
 */
@property (nonatomic, strong, readonly) RACSignal<NSError *> *errors;

/// Whether the command allows multiple executions to proceed concurrently.
///
/// The default value for this property is NO.
/*
 allowsConcurrentExecution是一个BOOL变量，它是用来表示当前RACCommand是否允许并发执行。默认值是NO。
 如果allowsConcurrentExecution为NO，那么RACCommand在执行过程中，enabled信号就一定都返回NO，不允许并发执行。如果allowsConcurrentExecution为YES，允许并发执行。
 
 如果是允许并发执行的话，就会出现多个信号就会出现一起发送值的情况。那么这种情况产生的高阶信号一般可以采取flatten(等效于flatten:0，+merge:)的方式进行降阶。
 */
@property (atomic, assign) BOOL allowsConcurrentExecution;

/// Invokes -initWithEnabled:signalBlock: with a nil `enabledSignal`.
- (instancetype)initWithSignalBlock:(RACSignal<ValueType> * (^)(InputType _Nullable input))signalBlock;

/// Initializes a command that is conditionally enabled.
///
/// This is the designated initializer for this class.
///
/// 触发条件
/// enabledSignal - A signal of BOOLs which indicate whether the command should
///                 be enabled. `enabled` will be based on the latest value sent
///                 from this signal. Before any values are sent, `enabled` will
///                 default to YES. This argument may be nil.
/// 触发事件
/// signalBlock   - A block which will map each input value (passed to -execute:)
///                 to a signal of work. The returned signal will be multicasted
///                 to a replay subject, sent on `executionSignals`, then
///                 subscribed to synchronously. Neither the block nor the
///                 returned signal may be nil.
- (instancetype)initWithEnabled:(nullable RACSignal<NSNumber *> *)enabledSignal signalBlock:(RACSignal<ValueType> * (^)(InputType _Nullable input))signalBlock;

/// If the receiver is enabled, this method will:
///
///  1. Invoke the `signalBlock` given at the time of initialization.
///  2. Multicast the returned signal to a RACReplaySubject.
///  3. Send the multicasted signal on `executionSignals`.
///  4. Subscribe (connect) to the original signal on the main thread.
///
/// input - The input value to pass to the receiver's `signalBlock`. This may be
///         nil.
///
/// Returns the multicasted signal, after subscription. If the receiver is not
/// enabled, returns a signal that will send an error with code
/// RACCommandErrorNotEnabled.
- (RACSignal<ValueType> *)execute:(nullable InputType)input;

@end

NS_ASSUME_NONNULL_END
