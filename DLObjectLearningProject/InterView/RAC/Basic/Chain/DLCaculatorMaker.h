//
//  DLCaculatorMaker.h
//  DLObjectLearningProject
//
//  Created by denglong on 02/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DLCaculatorMaker : NSObject
@property(nonatomic, assign) int result;
//加法
- (DLCaculatorMaker *(^)(int))add;
- (DLCaculatorMaker *(^)(int))sub;
- (DLCaculatorMaker *(^)(int))mult;
- (DLCaculatorMaker *(^)(int))divide;
@end
