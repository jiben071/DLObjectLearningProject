//
//  DLRequestViewModel.m
//  DLObjectLearningProject
//
//  Created by denglong on 01/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import "DLRequestViewModel.h"

@implementation DLRequestViewModel
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialBind];
    }
    return self;
}

- (void)initialBind{
    _reqeustCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        RACSignal *requestSignal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
            parameters[@"q"] = @"基础";
            //发送请求
            [[AFHTT]]
            return nil;
        }]
    }]
}
@end
