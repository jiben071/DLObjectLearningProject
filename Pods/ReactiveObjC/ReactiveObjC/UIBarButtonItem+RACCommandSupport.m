//
//  UIBarButtonItem+RACCommandSupport.m
//  ReactiveObjC
//
//  Created by Kyle LeNeau on 3/27/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "UIBarButtonItem+RACCommandSupport.h"
#import <ReactiveObjC/RACEXTKeyPathCoding.h>
#import "RACCommand.h"
#import "RACDisposable.h"
#import "RACSignal+Operations.h"
#import <objc/runtime.h>

static void *UIControlRACCommandKey = &UIControlRACCommandKey;
static void *UIControlEnabledDisposableKey = &UIControlEnabledDisposableKey;

@implementation UIBarButtonItem (RACCommandSupport)

- (RACCommand *)rac_command {
	return objc_getAssociatedObject(self, UIControlRACCommandKey);
}

- (void)setRac_command:(RACCommand *)command {
	objc_setAssociatedObject(self, UIControlRACCommandKey, command, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	// Check for stored signal in order to remove it and add a new one
    //检查已经存储过的信号，移除老的，添加一个新的
	RACDisposable *disposable = objc_getAssociatedObject(self, UIControlEnabledDisposableKey);
	[disposable dispose];
	
	if (command == nil) return;
	
	disposable = [command.enabled setKeyPath:@keypath(self.enabled) onObject:self];
	objc_setAssociatedObject(self, UIControlEnabledDisposableKey, disposable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	[self rac_hijackActionAndTargetIfNeeded];
}

//rac_hijackActionAndTargetIfNeeded方法是对当前UIBarButtonItem的target和action进行检查。
- (void)rac_hijackActionAndTargetIfNeeded {
	SEL hijackSelector = @selector(rac_commandPerformAction:);
    //如果当前UIBarButtonItem的target = self，并且action = @selector(rac_commandPerformAction:)，那么就算检查通过符合执行RACCommand的前提条件了，直接return。
	if (self.target == self && self.action == hijackSelector) return;
	
	if (self.target != nil) NSLog(@"WARNING: UIBarButtonItem.rac_command hijacks the control's existing target and action.");
	
    //如果上述条件不符合，就强制改变UIBarButtonItem的target = self，并且action = @selector(rac_commandPerformAction:)，所以这里需要注意的就是，UIBarButtonItem调用rac_command，会被强制改变它的target和action。
	self.target = self;
	self.action = hijackSelector;
}

- (void)rac_commandPerformAction:(id)sender {
	[self.rac_command execute:sender];
}

@end
