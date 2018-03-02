//
//  DLCaculator.h
//  DLObjectLearningProject
//
//  Created by denglong on 02/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DLCaculator : NSObject
@property(nonatomic, assign) BOOL isEqual;
@property(nonatomic, assign) int result;

- (DLCaculator *)caculator:(int(^)(int result))caculator;
- (DLCaculator *)equal:(BOOL(^)(int result))operation;
@end
