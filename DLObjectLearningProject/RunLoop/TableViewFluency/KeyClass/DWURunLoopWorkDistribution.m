//
//  DWURunLoopWorkDistribution.m
//  RunLoopWorkDistribution
//
//  Created by Di Wu on 9/19/15.
//  Copyright © 2015 Di Wu. All rights reserved.
//  优化耗时任务的关键类：核心在于runloop的运用
//  优秀的解释CFRunLoopObserver：http://www.jianshu.com/p/4c783dbc7ef3
//  作用：将tableview中的耗时任务放入runloop的default的模式中，以达到流畅优化的目的
//  参考文章：http://blog.csdn.net/zzzzzdddddxxxxx/article/details/53670065
//  源码：https://github.com/diwu/RunLoopWorkDistribution

//首先创建一个单例，单例中定义了几个数组，用来存要在runloop循环中执行的任务，然后为主线程的runloop添加一个CFRunLoopObserver,当主线程在NSDefaultRunLoopMode中执行完任务，即将睡眠前，执行一个单例中保存的一次图片渲染任务。关键代码看DWURunLoopWorkDistribution类即可。

#import "DWURunLoopWorkDistribution.h"
#import <objc/runtime.h>

#define DWURunLoopWorkDistribution_DEBUG 1

@interface DWURunLoopWorkDistribution ()

@property (nonatomic, strong) NSMutableArray *tasks;//任务数组

@property (nonatomic, strong) NSMutableArray *tasksKeys;//任务索引数组

@property (nonatomic, strong) NSTimer *timer;//定时器

@end

@implementation DWURunLoopWorkDistribution

- (void)removeAllTasks {
    [self.tasks removeAllObjects];
    [self.tasksKeys removeAllObjects];
}

- (void)addTask:(DWURunLoopWorkDistributionUnit)unit withKey:(id)key{
    [self.tasks addObject:unit];
    [self.tasksKeys addObject:key];
    if (self.tasks.count > self.maximumQueueLength) {//有任务池数量限制  超过限制，则将第一个任务移除
        [self.tasks removeObjectAtIndex:0];
        [self.tasksKeys removeObjectAtIndex:0];
    }
}

- (void)_timerFiredMethod:(NSTimer *)timer {
    //We do nothing here
}

- (instancetype)init
{
    if ((self = [super init])) {
        _maximumQueueLength = 30;//默认限制30个任务
        _tasks = [NSMutableArray array];
        _tasksKeys = [NSMutableArray array];
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_timerFiredMethod:) userInfo:nil repeats:YES];
    }
    return self;
}

//单例模式
+ (instancetype)sharedRunLoopWorkDistribution {
    static DWURunLoopWorkDistribution *singleton;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        singleton = [[DWURunLoopWorkDistribution alloc] init];
        [self _registerRunLoopWorkDistributionAsMainRunloopObserver:singleton];
    });
    return singleton;
}



+ (void)_registerRunLoopWorkDistributionAsMainRunloopObserver:(DWURunLoopWorkDistribution *)runLoopWorkDistribution {
    static CFRunLoopObserverRef defaultModeObserver;
    _registerObserver(kCFRunLoopBeforeWaiting, defaultModeObserver, NSIntegerMax - 999, kCFRunLoopDefaultMode, (__bridge void *)runLoopWorkDistribution, &_defaultModeRunLoopWorkDistributionCallback);
}


/*
 一个CFRunLoopObserver可以提供一个回调函数，使这个函数能在Runloop中运行。对比CFRunLoopSource，当Runloop中发生某些事时（如，sources触发，runloop进入睡眠），CFRunLoopObserver就会被调用。 CFRunLoopObserver可以在Runloop中一次或在循环调用。
 */
static void _registerObserver(CFOptionFlags activities, CFRunLoopObserverRef observer, CFIndex order, CFStringRef mode, void *info, CFRunLoopObserverCallBack callback) {
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    
    //context：CFRunLoopObserver结构体里面的一个结构体，它主要使用来传递消息的，在回调函数外面代码生成的信息可以传进回调函数内进行使用，形成了一个消息传递。
    CFRunLoopObserverContext context = {
        0,
        info,
        &CFRetain,
        &CFRelease,
        NULL
    };
    observer = CFRunLoopObserverCreate(     NULL,
                                            activities,
                                            YES,
                                            order,
                                            callback,
                                            &context);
    CFRunLoopAddObserver(runLoop, observer, mode);
    CFRelease(observer);
    
    /*
     CFRunLoopObserverDoesRepeat
     返回一个布尔值来查看所检测的CFRunLoopObserver是否循环调用。
     */
    
    /*
     CFRunLoopAddObserver
     添加一个CFRunLoopObserver到一个run loop mode中。
     一个CFRunLoopObserver仅可以注册在Runloop中一次，但它可以注册在多个Runloop Mode中。
     */
}

static void _runLoopWorkDistributionCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    DWURunLoopWorkDistribution *runLoopWorkDistribution = (__bridge DWURunLoopWorkDistribution *)info;
    if (runLoopWorkDistribution.tasks.count == 0) {
        return;
    }
    BOOL result = NO;
    while (result == NO && runLoopWorkDistribution.tasks.count) {
        DWURunLoopWorkDistributionUnit unit  = runLoopWorkDistribution.tasks.firstObject;
        result = unit();
        [runLoopWorkDistribution.tasks removeObjectAtIndex:0];
        [runLoopWorkDistribution.tasksKeys removeObjectAtIndex:0];
    }
}

static void _defaultModeRunLoopWorkDistributionCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    _runLoopWorkDistributionCallback(observer, activity, info);
}

@end

@implementation UITableViewCell (DWURunLoopWorkDistribution)

@dynamic currentIndexPath;

- (NSIndexPath *)currentIndexPath {
    NSIndexPath *indexPath = objc_getAssociatedObject(self, @selector(currentIndexPath));
    return indexPath;
}

- (void)setCurrentIndexPath:(NSIndexPath *)currentIndexPath {
    objc_setAssociatedObject(self, @selector(currentIndexPath), currentIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
