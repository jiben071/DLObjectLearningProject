//
//  RACSubject.h
//  ReactiveObjC
//
//  Created by Josh Abernathy on 3/9/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACSignal.h"
#import "RACSubscriber.h"

NS_ASSUME_NONNULL_BEGIN

/// A subject can be thought of as a signal that you can manually control by
/// sending next, completed, and error.
///subject可以被当成一个signal，你可以手动控制发送next completed error
/// They're most helpful in bridging the non-RAC world to RAC, since they let you
/// manually control the sending of events.
/// 对于桥接非FAC世界到RAC非常有用，从它可以让你手动控制发送事件
@interface RACSubject<ValueType> : RACSignal<ValueType> <RACSubscriber>

/// Returns a new subject.
+ (instancetype)subject;

// Redeclaration of the RACSubscriber method. Made in order to specify a generic type.覆写RACSubscriber的方法,可以指定一个通用类型
- (void)sendNext:(nullable ValueType)value;

@end

NS_ASSUME_NONNULL_END
