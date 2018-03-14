//
//  DLRACLearningViewController.h
//  DLObjectLearningProject
//
//  Created by denglong on 12/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import "ReactiveViewModel.h"

@interface DLRACLearningViewController : UIViewController

@end

@interface DLTestModel:NSObject
@property(nonatomic, copy) NSString *name;
@end

@interface DLPin:NSObject
@property(nonatomic, assign) BOOL hasLiked;
@property(nonatomic, assign) NSInteger likedCount;
@end

@interface DLViewModel:NSObject
@property(nonatomic, strong) DLPin *pin;
@property(nonatomic, strong) RACCommand *likeCommand;
@property(nonatomic, assign) BOOL hasLiked;
@property(nonatomic, copy) NSString *likedCount;
@end


@interface HBCViewModel : RVMViewModel
@property (nonatomic) RACSubject *errors;
@end 
