//
//  DWURunLoopWorkDistribution.h
//  RunLoopWorkDistribution
//
//  Created by Di Wu on 9/19/15.
//  Copyright © 2015 Di Wu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef BOOL(^DWURunLoopWorkDistributionUnit)(void);

@interface DWURunLoopWorkDistribution : NSObject

@property (nonatomic, assign) NSUInteger maximumQueueLength;

+ (instancetype)sharedRunLoopWorkDistribution;//单例模式

- (void)addTask:(DWURunLoopWorkDistributionUnit)unit withKey:(id)key;//添加任务

- (void)removeAllTasks;//移除所有任务

@end



//cell定义
@interface UITableViewCell (DWURunLoopWorkDistribution)

@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@end
