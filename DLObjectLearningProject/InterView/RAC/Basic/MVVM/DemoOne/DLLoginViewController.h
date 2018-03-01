//
//  DLLoginViewController.h
//  DLObjectLearningProject
//
//  Created by denglong on 01/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import "DLLoginViewModel.h"

@interface DLLoginViewController : UIViewController
@property(nonatomic, strong) DLLoginViewModel *loginViewModel;

@property (weak, nonatomic) IBOutlet UITextField *accountField;
@property (weak, nonatomic) IBOutlet UITextField *pwdField;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@end
