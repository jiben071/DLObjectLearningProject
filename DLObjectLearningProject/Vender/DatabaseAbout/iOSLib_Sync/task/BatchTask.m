//
//  BatchTask.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/13.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "BatchTask.h"

NSString *const BatcTaskQueueName = @"com.batchTaskQueue";

@interface BatchTask()
{
    dispatch_semaphore_t semphore;
    void *IsOnBatchTaskQueueOrTargetQueueKey;
}

@property (nonatomic, strong) dispatch_queue_t batchtaskQueue;

@property (nonatomic, strong)NSMutableArray *taskArray;

@property (nonatomic, strong)NSMutableArray *callbackArray;

@property (nonatomic, strong)NSMutableArray *resultArray;


@end

@implementation BatchTask

+(instancetype)shareBatchTask {
    static BatchTask *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BatchTask alloc] init];
    });
    return shareInstance;
}

-(id)init {
    self = [super init];
    if(self) {
        semphore = dispatch_semaphore_create(1);
        if(!self.batchtaskQueue) {
            self.batchtaskQueue = dispatch_queue_create([BatcTaskQueueName UTF8String], NULL);
            IsOnBatchTaskQueueOrTargetQueueKey = &IsOnBatchTaskQueueOrTargetQueueKey;
            void *nonNullUnusedPointer = (__bridge void *)self;
            dispatch_queue_set_specific(self.batchtaskQueue, IsOnBatchTaskQueueOrTargetQueueKey, nonNullUnusedPointer, NULL);
        }
    }
    return self;
}


-(void)startTask:(NSArray<SimpleTask *>*)taskArray withCallback:(BatchCallback)callback {
    __weak BatchTask *weakSelf = self;
    dispatch_block_t block = ^{
        dispatch_semaphore_wait(semphore, dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC));
        for (SimpleTask *task in taskArray) {
            if(!weakSelf.taskArray) {
                weakSelf.taskArray = [NSMutableArray array];
            }
            [weakSelf.taskArray addObject:task];
        }
        if(callback != nil) {
            if(!weakSelf.callbackArray) {
                weakSelf.callbackArray = [NSMutableArray array];
            }
            [weakSelf.callbackArray addObject:callback];
        }
        if(weakSelf.taskArray && weakSelf.taskArray.count > 0) {
            [weakSelf run];
        }else {
            [weakSelf clear];
            dispatch_semaphore_signal(semphore);
        }
    };
    
    if(dispatch_get_specific(IsOnBatchTaskQueueOrTargetQueueKey)) {
        block();
    }else {
        dispatch_async(self.batchtaskQueue, block);
    }
    
}


-(void)run {
    __weak BatchTask *weakSelf = self;
    dispatch_block_t block = ^{
        for (SimpleTask *task in weakSelf.taskArray) {
            [task start:^(Result *result, int code) {
                [weakSelf notify:result code:code];
            }];
        }
    };
    
    if(dispatch_get_specific(IsOnBatchTaskQueueOrTargetQueueKey)) {
        block();
    }else {
        dispatch_async(self.batchtaskQueue, block);
    }
  
}

-(int)size {
    if(!self.taskArray) return 0;
    else {
        return (int)self.taskArray.count;
    }
}

-(void)notify:(Result *)result code:(int)code {
    __weak BatchTask *weakSelf = self;
    dispatch_block_t block = ^{
        if(!weakSelf.resultArray) {
            weakSelf.resultArray = [NSMutableArray array];
        }
        [weakSelf.resultArray addObject:@[result, @(code)]];
        
        int finalCode = SUCCESS;
        
        if(weakSelf.resultArray.count >= [weakSelf size]) {
            NSMutableArray *results = [NSMutableArray array];
            for (int i = 0; i < weakSelf.resultArray.count; i++) {
                NSArray *array = weakSelf.resultArray[i];
                [results addObject:array[0]];
                finalCode &= [array[1] intValue];
            }
            
            NSLog(@"=====> finalCode = %d", finalCode);
            
            NSArray *array = [self.callbackArray copy];
            [self clear];
            for (BatchCallback callback in array) {
                if(callback != nil) {
                    callback(results, finalCode);
                }
            }
            
            dispatch_semaphore_signal(semphore);
            
            
        }
    };
    if(dispatch_get_specific(IsOnBatchTaskQueueOrTargetQueueKey)) {
        block();
    }else {
        dispatch_async(self.batchtaskQueue, block);
    }
}


-(void)clear {
    __weak BatchTask *weakSelf = self;
    dispatch_block_t block = ^{
        if(weakSelf.callbackArray) {
            [weakSelf.callbackArray removeAllObjects];
        }
        
        if(weakSelf.taskArray) {
            [weakSelf.taskArray removeAllObjects];
        }
        
        if(weakSelf.resultArray) {
            [weakSelf.resultArray removeAllObjects];
        }
    };
    if(dispatch_get_specific(IsOnBatchTaskQueueOrTargetQueueKey)) {
        block();
    }else {
        dispatch_async(self.batchtaskQueue, block);
    }
}

@end
