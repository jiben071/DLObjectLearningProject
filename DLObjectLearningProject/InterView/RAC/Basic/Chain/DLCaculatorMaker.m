//
//  DLCaculatorMaker.m
//  DLObjectLearningProject
//
//  Created by denglong on 02/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import "DLCaculatorMaker.h"

@implementation DLCaculatorMaker
- (DLCaculatorMaker *(^)(int))add{
    return ^DLCaculatorMaker *(int value){
        _result += value;
        return self;
    };
}
- (DLCaculatorMaker *(^)(int))sub{
    return ^DLCaculatorMaker *(int value){
        _result -= value;
        return self;
    };
}
- (DLCaculatorMaker *(^)(int))mult{
    return ^DLCaculatorMaker *(int value){
        _result *= value;
        return self;
    };
}
- (DLCaculatorMaker *(^)(int))divide{
    return ^DLCaculatorMaker *(int value){
        _result /= value;
        return self;
    };
}
@end
