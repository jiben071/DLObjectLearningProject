//
//  RACSubscriptionScheduler.m
//  ReactiveObjC
//
//  Created by Josh Abernathy on 11/30/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACSubscriptionScheduler.h"
#import "RACScheduler+Private.h"

@interface RACSubscriptionScheduler ()

// A private background scheduler on which to subscribe if the +currentScheduler
// is unknown.
@property (nonatomic, strong, readonly) RACScheduler *backgroundScheduler;

@end

@implementation RACSubscriptionScheduler

#pragma mark Lifecycle

- (instancetype)init {
	self = [super initWithName:@"org.reactivecocoa.ReactiveObjC.RACScheduler.subscriptionScheduler"];

	_backgroundScheduler = [RACScheduler scheduler];

	return self;
}

#pragma mark RACScheduler

- (RACDisposable *)schedule:(void (^)(void))block {
	NSCParameterAssert(block != NULL);

    //在取currentScheduler的过程中，会判断currentScheduler是否存在，和是否在主线程中。如果都没有，那么就会调用后台backgroundScheduler去执行schedule。
    //在schedule的方法里面会判断当前currentScheduler是否为nil，如果是nil就调用backgroundScheduler去执行block( )闭包,如果不为nil，当前currentScheduler直接执行block( )闭包。
    if (RACScheduler.currentScheduler == nil) {
        return [self.backgroundScheduler schedule:block];
    }

	block();
	return nil;
}

- (RACDisposable *)after:(NSDate *)date schedule:(void (^)(void))block {
	RACScheduler *scheduler = RACScheduler.currentScheduler ?: self.backgroundScheduler;
	return [scheduler after:date schedule:block];
}

- (RACDisposable *)after:(NSDate *)date repeatingEvery:(NSTimeInterval)interval withLeeway:(NSTimeInterval)leeway schedule:(void (^)(void))block {
	RACScheduler *scheduler = RACScheduler.currentScheduler ?: self.backgroundScheduler;
	return [scheduler after:date repeatingEvery:interval withLeeway:leeway schedule:block];
}

@end
