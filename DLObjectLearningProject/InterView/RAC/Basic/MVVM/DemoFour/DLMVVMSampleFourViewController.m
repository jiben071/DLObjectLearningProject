//
//  DLMVVMSampleFourViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 28/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import "DLMVVMSampleFourViewController.h"
#import "DLMVVMViewModel.h"

@interface DLMVVMSampleFourViewController ()
@property (nonatomic, strong) IBOutlet UITextField *usernameTextField;
@property (nonatomic, strong) IBOutlet UITextField *passwordTextField;
@property (nonatomic, strong) IBOutlet UIButton    *loginButton;
@property(nonatomic, strong) DLMVVMViewModel *viewModel;
@end

@implementation DLMVVMSampleFourViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.viewModel = [ViewModel new];
    // bind input signals
    RAC(self.viewModel, username) = self.usernameTextField.rac_textSignal;
    RAC(self.viewModel, password) = self.passwordTextField.rac_textSignal;
    // bind output signals
    RAC(self.usernameTextField, backgroundColor) = ConvertInputStateToColor(RACObserve(self.viewModel, usernameInputState));
    RAC(self.passwordTextField, backgroundColor) = ConvertInputStateToColor(RACObserve(self.viewModel, passwordInputState));
    RAC(self.loginButton, enabled) = RACObserve(self.viewModel, loginEnabled);
}

@end
