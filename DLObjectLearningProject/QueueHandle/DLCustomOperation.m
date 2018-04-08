//
//  DLCustomOperation.m
//  DLObjectLearningProject
//
//  Created by denglong on 30/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  http://www.cnblogs.com/panda1024/p/6274631.html  自定义NSOperation实现取消正在执行下载的操作

/*
 问题描述：
 直接使用系统的Operation，无论是挂起，还是取消全部，都无法取消正在执行的操作。
 NSOperationQueue *queue = [[NSOperationQueue alloc] init];
 
 // 移除队列里面所有的操作，但正在执行的操作无法移除
 [queue cancelAllOperations];
 
 // 挂起队列，使队列任务不再执行，但正在执行的操作无法挂起
 _queue.suspended = YES;
 */

/*
 解决办法：
 我们可以自定义NSOperation，实现取消正在执行的操作。其实就是拦截main方法。
 
 main方法：
 
 1、任何操作在执行时，首先会调用start方法，start方法会更新操作的状态（过滤操作,如过滤掉处于“取消”状态的操作）。
 2、经start方法过滤后，只有正常可执行的操作，就会调用main方法。
 3、重写操作的入口方法(main)，就可以在这个方法里面指定操作执行的任务。
 4、main方法默认是在子线程异步执行的。
 */

#import "DLCustomOperation.h"
@interface DLCustomOperation()
/**图片地址*/
@property(copy,nonatomic) NSString *urlString;

/**回调Block,在主线程执行*/
@property(copy,nonatomic) void(^finishBlock)(UIImage*);
@end

@implementation DLCustomOperation
/**
 重写自定义操作的入口方法
 任何操作在执行时都会默认调用这个方法
 默认在子线程执行
 当队列调度操作执行时，才会进入main方法
 */
- (void)main{
    NSAssert(self.urlString != nil, @"请传入图片地址");
    NSAssert(self.finishBlock != nil, @"请传入下载完成回调Block");
    
    //越晚执行越好，一般写在耗时操作后面（可以每行代码后面写一句）
    if (self.isCancelled) {
        return;
    }
    
    //下载图片
    NSURL *imgURL = [NSURL URLWithString:self.urlString];
    NSData *imgData = [NSData dataWithContentsOfURL:imgURL];
    UIImage *img = [UIImage imageWithData:imgData];
    
    
    //越晚执行越好，一般写在耗时操作后面（可以每行代码后面写一句）
    if (self.isCancelled) {
        return;
    }
    
    //传递至VC
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.finishBlock(img);
    }];
    
}

+ (instancetype)downloadImageWithURLString:(NSString *)urlString andFinishBlock:(void (^)(UIImage *))finishBlock{
    DLCustomOperation *op = [[self alloc] init];
    
    op.urlString = urlString;
    op.finishBlock = finishBlock;
    
    return op;
}
@end
