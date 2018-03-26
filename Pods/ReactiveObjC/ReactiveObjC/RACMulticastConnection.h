//
//  RACMulticastConnection.h
//  ReactiveObjC
//
//  Created by Josh Abernathy on 4/11/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RACAnnotations.h"

@class RACDisposable;
@class RACSignal<__covariant ValueType>;

NS_ASSUME_NONNULL_BEGIN

/// A multicast connection encapsulates the idea of sharing one subscription to a
/// signal to many subscribers. This is most often needed if the subscription to
/// the underlying signal involves side-effects or shouldn't be called more than
/// once.
///
/// The multicasted signal is only subscribed to when
/// -[RACMulticastConnection connect] is called. Until that happens, no values
/// will be sent on `signal`. See -[RACMulticastConnection autoconnect] for how
/// -[RACMulticastConnection connect] can be called automatically.
///
/// Note that you shouldn't create RACMulticastConnection manually. Instead use
/// -[RACSignal publish] or -[RACSignal multicast:].
/// RACMulticastConnection不应该手动创建
/*
 看看RACMulticastConnection类的定义。最主要的是保存了两个信号，一个是RACSubject，一个是sourceSignal(RACSignal类型)。在.h中暴露给外面的是RACSignal，在.m中实际使用的是RACSubject。看它的定义就能猜到接下去它会做什么：用sourceSignal去发送信号，内部再用RACSubject去订阅sourceSignal，然后RACSubject会把sourceSignal的信号值依次发给它的订阅者们。
 */
@interface RACMulticastConnection<__covariant ValueType> : NSObject

/// The multicasted signal.
@property (nonatomic, strong, readonly) RACSignal<ValueType> *signal;

/// Connect to the underlying signal by subscribing to it. Calling this multiple
/// times does nothing but return the existing connection's disposable.
///
/// Returns the disposable for the subscription to the multicasted signal.
- (RACDisposable *)connect;

/// Connects to the underlying signal when the returned signal is first
/// subscribed to, and disposes of the subscription to the multicasted signal
/// when the returned signal has no subscribers.
///
/// If new subscribers show up after being disposed, they'll subscribe and then
/// be immediately disposed of. The returned signal will never re-connect to the
/// multicasted signal.
///
/// Returns the autoconnecting signal.
- (RACSignal<ValueType> *)autoconnect RAC_WARN_UNUSED_RESULT;

@end

NS_ASSUME_NONNULL_END
