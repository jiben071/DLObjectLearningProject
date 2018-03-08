//
//  NSObject+extensionForRACDL.h
//  DLObjectLearningProject
//
//  Created by denglong on 05/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>

@interface NSObject (extensionForRACDL)
- (RACSignal *)logIn;//异步登录操作
- (RACSignal *)fetchUserRepos;
- (RACSignal *)fetchOrgRepos;
- (RACSignal *)logInUser;
- (RACSignal *)loadCachedMessagesForUser;
- (RACSignal *)fetchMessagesAfterMessage;
- (RACSignal *)fetchUserWithUsername:(NSString *)userName;
@end
