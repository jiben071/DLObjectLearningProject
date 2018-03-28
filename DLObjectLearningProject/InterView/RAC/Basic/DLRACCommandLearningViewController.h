//
//  DLRACCommandLearningViewController.h
//  DLObjectLearningProject
//
//  Created by denglong on 28/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>

@interface DLRACCommandLearningViewController : UIViewController

@end

@interface SubscribeViewModel:NSObject
@property(nonatomic, copy) NSString *email;
@property(nonatomic, copy) NSString *statusMessage;
@property(nonatomic, strong) RACCommand *subscribeCommand;
@end
