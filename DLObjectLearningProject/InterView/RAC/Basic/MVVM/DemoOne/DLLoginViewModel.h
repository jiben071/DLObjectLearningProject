//
//  DLLoginViewModel.h
//  DLObjectLearningProject
//
//  Created by denglong on 01/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import "DLAccount.h"

@interface DLLoginViewModel : NSObject
@property(nonatomic, strong) DLAccount *account;
@property(nonatomic, strong, readonly) RACSignal *enableLoginSignal;//是否允许登录的信号
@property(nonatomic, strong, readonly) RACCommand *loginCommand;
@end
