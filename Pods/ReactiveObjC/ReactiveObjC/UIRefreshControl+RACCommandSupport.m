//
//  UIRefreshControl+RACCommandSupport.m
//  ReactiveObjC
//
//  Created by Dave Lee on 2013-10-17.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "UIRefreshControl+RACCommandSupport.h"
#import <ReactiveObjC/RACEXTKeyPathCoding.h>
#import "RACCommand.h"
#import "RACCompoundDisposable.h"
#import "RACDisposable.h"
#import "RACSignal.h"
#import "RACSignal+Operations.h"
#import "UIControl+RACSignalSupport.h"
#import <objc/runtime.h>

static void *UIRefreshControlRACCommandKey = &UIRefreshControlRACCommandKey;
static void *UIRefreshControlDisposableKey = &UIRefreshControlDisposableKey;

@implementation UIRefreshControl (RACCommandSupport)

- (RACCommand *)rac_command {
	return objc_getAssociatedObject(self, UIRefreshControlRACCommandKey);
}

- (void)setRac_command:(RACCommand *)command {
	objc_setAssociatedObject(self, UIRefreshControlRACCommandKey, command, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

	// Dispose of any active command associations.
	[objc_getAssociatedObject(self, UIRefreshControlDisposableKey) dispose];

	if (command == nil) return;

	// Like RAC(self, enabled) = command.enabled; but with access to disposable.
	RACDisposable *enabledDisposable = [command.enabled setKeyPath:@keypath(self.enabled) onObject:self];

    //这里多了一个executionDisposable信号，这个信号是用来结束刷新操作的。
	RACDisposable *executionDisposable = [[[[[self
		rac_signalForControlEvents:UIControlEventValueChanged]
		map:^(UIRefreshControl *x) {//[self rac_signalForControlEvents:UIControlEventValueChanged]之后再map升阶为高阶信号
			return [[[command
				execute:x]//把RACCommand执行
				catchTo:[RACSignal empty]]//执行之后得到的结果信号剔除掉所有的错误
				then:^{//then操作就是忽略掉所有值
					return [RACSignal return:x];//在最后添加一个返回UIRefreshControl对象的信号。
				}];
		}]
		concat]//所以最后用concat降阶
		deliverOnMainThread]
		subscribeNext:^(UIRefreshControl *x) {//最后订阅这个信号，订阅只会收到一个值，
			[x endRefreshing];//command执行完毕之后的信号发送完所有的值的时候，即收到这个值的时刻就是最终刷新结束的时刻。所以最终的disposable信号还要加上executionDisposable。
		}];
 
	RACDisposable *commandDisposable = [RACCompoundDisposable compoundDisposableWithDisposables:@[ enabledDisposable, executionDisposable ]];
	objc_setAssociatedObject(self, UIRefreshControlDisposableKey, commandDisposable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
