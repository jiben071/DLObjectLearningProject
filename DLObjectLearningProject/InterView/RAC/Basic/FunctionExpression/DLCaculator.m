//
//  DLCaculator.m
//  DLObjectLearningProject
//
//  Created by denglong on 02/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import "DLCaculator.h"

@implementation DLCaculator
- (DLCaculator *)caculator:(int(^)(int result))caculator{
    self.result = caculator(self.result);
    return self;
}

- (DLCaculator *)equal:(BOOL(^)(int result))operation{
    self.isEqual = operation(self.result);
    return self;
}
@end
