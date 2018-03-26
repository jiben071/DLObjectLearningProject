//
//  RACBlockTrampoline.h
//  ReactiveObjC
//
//  Created by Josh Abernathy on 10/21/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACTuple;

// A private class that allows a limited type of dynamic block invocation.
// 一个允许有限类型的动态块调用的私有类。
//RACBlockTrampoline就是一个保存了一个block闭包的对象，它会根据传进来的参数，动态的构造一个NSInvocation，并执行。
@interface RACBlockTrampoline : NSObject

// Invokes the given block with the given arguments. All of the block's
// argument types must be objects and it must be typed to return an object.//并且必须键入它才能返回对象。
//
// At this time, it only supports blocks that take up to 15 arguments. Any more
// is just cray.
//
// block     - The block to invoke. Must accept as many arguments as are given in
//             the arguments array. Cannot be nil.
// arguments - The arguments with which to invoke the block. `RACTupleNil`s will
//             be passed as nils.
//
// Returns the return value of invoking the block.
+ (id)invokeBlock:(id)block withArguments:(RACTuple *)arguments;

@end
