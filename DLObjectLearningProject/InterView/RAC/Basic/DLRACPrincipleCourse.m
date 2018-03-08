//
//  DLRACPrincipleCourse.m
//  DLObjectLearningProject
//
//  Created by denglong on 05/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  http://www.cocoachina.com/ios/20150702/12302.html
//  reactivecocoa 说明文档  中文翻译

#import "DLRACPrincipleCourse.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import <UIKit/UIKit.h>
#import "NSObject+extensionForRACDL.h"

@interface DLRACPrincipleCourse()
@property(nonatomic, copy) NSString *userName;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, copy) NSString *passwordConfirmation;
@property(nonatomic, assign) BOOL createEnabled;

@property(nonatomic, strong) UIButton *button;
@property(nonatomic, strong) UIButton *loginButton;
@property(nonatomic, strong) NSObject *client;
@property(nonatomic, strong) RACCommand *loginCommand;

@property(nonatomic, strong) UIImageView *imageView;
@end

@implementation DLRACPrincipleCourse
//rac的kvo方式
- (void)kvoTest{
    [[RACObserve(self, userName) filter:^BOOL(NSString  *_Nullable newValue) {
        return [newValue hasPrefix:@"long"];
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}

//联合信号kvo
- (void)conbineTest{
    RAC(self,createEnabled) = [RACSignal combineLatest:@[RACObserve(self, password),RACObserve(self, passwordConfirmation)] reduce:^(NSString *password,NSString *passwordConfirm){
        return @([passwordConfirm isEqualToString:password]);
    }];
}

//展示button presses
- (void)buttonTest{
    self.button.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        NSLog(@"button was pressed");
        return [RACSignal empty];
    }];
}

//异步网络操作：
- (void)asynchronousTest{
    self.loginCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        return [self.client logIn];
    }];
    
    [self.loginCommand.executionSignals subscribeNext:^(RACSignal  *_Nullable loginSignal) {
        [loginSignal subscribeCompleted:^{
            NSLog(@"Logged in successfully");
        }];
    }];
    
    self.loginButton.rac_command = self.loginCommand;
}

//合并请求
- (void)mergeRequest{
    [[RACSignal merge:@[[self.client fetchUserRepos],[self.client fetchOrgRepos]]] subscribeCompleted:^{
        NSLog(@"They're both done!");
    }];
}

//顺序的执行异步操作，而不用嵌套block
- (void)orderAsynchronousTest{
    [[[[self.client logInUser] flattenMap:^__kindof RACSignal * _Nullable(id  _Nullable value) {
        return [self.client loadCachedMessagesForUser];
    }] flattenMap:^__kindof RACSignal * _Nullable(id  _Nullable value) {
        return [self.client fetchMessagesAfterMessage];
    }]subscribeNext:^(id  _Nullable x) {
        NSLog(@"New messages: %@",x);
    }];
}

//简单的绑定异步操作的结果
- (void)bindTest{
    RAC(self.imageView,image) = [[[[self.client fetchUserWithUsername:@"john"] deliverOn:[RACScheduler scheduler]] map:^id _Nullable(id  _Nullable value) {
        return [[UIImage alloc] initWithContentsOfFile:@""];
    }]deliverOn:RACScheduler.mainThreadScheduler];
}


/*
 什么时候用ReactiveCocoa
 
 乍看上去,ReactiveCocoa是很抽象的,它可能很难理解如何将它应用到具体的问题.
 
 这里有一些RAC常用的地方.
 
 处理异步或者事件驱动数据源
 
 很多Cocoa编程集中在响应user events或者改变application state.这样写代码很快地会变得很复杂,就像一个意大利面,需要处理大量的回调和状态变量的问题.
 
 这个模式表面上看起来不同,像UI回调,网络响应,和KVO notifications,实际上有很多的共同之处。RACSignal统一了这些API,这样他们能够组装在一起然后用相同的方式操作.
 
 举例看一下下面的代码:
 
 
 static void *ObservationContext = &ObservationContext;
 - (void)viewDidLoad {
 [super viewDidLoad];
 [LoginManager.sharedManager addObserver:self forKeyPath:@"loggingIn" options:NSKeyValueObservingOptionInitial context:&ObservationContext];
 [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(loggedOut:) name:UserDidLogOutNotification object:LoginManager.sharedManager];
 [self.usernameTextField addTarget:self action:@selector(updateLogInButton) forControlEvents:UIControlEventEditingChanged];
 [self.passwordTextField addTarget:self action:@selector(updateLogInButton) forControlEvents:UIControlEventEditingChanged];
 [self.logInButton addTarget:self action:@selector(logInPressed:) forControlEvents:UIControlEventTouchUpInside];
 }
 - (void)dealloc {
 [LoginManager.sharedManager removeObserver:self forKeyPath:@"loggingIn" context:ObservationContext];
 [NSNotificationCenter.defaultCenter removeObserver:self];
 }
 - (void)updateLogInButton {
 BOOL textFieldsNonEmpty = self.usernameTextField.text.length > 0 && self.passwordTextField.text.length > 0;
 BOOL readyToLogIn = !LoginManager.sharedManager.isLoggingIn && !self.loggedIn;
 self.logInButton.enabled = textFieldsNonEmpty && readyToLogIn;
 }
 - (IBAction)logInPressed:(UIButton *)sender {
 [[LoginManager sharedManager]
 logInWithUsername:self.usernameTextField.text
 password:self.passwordTextField.text
 success:^{
 self.loggedIn = YES;
 } failure:^(NSError *error) {
 [self presentError:error];
 }];
 }
 - (void)loggedOut:(NSNotification *)notification {
 self.loggedIn = NO;
 }
 - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
 if (context == ObservationContext) {
 [self updateLogInButton];
 } else {
 [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
 }
 }
 … 用RAC表达的话就像下面这样:
 */

/*
- (void)viewDidLoad {
    [super viewDidLoad];
    @weakify(self);
    RAC(self.logInButton, enabled) = [RACSignal
                                      combineLatest:@[
                                                      self.usernameTextField.rac_textSignal,
                                                      self.passwordTextField.rac_textSignal,
                                                      RACObserve(LoginManager.sharedManager, loggingIn),
                                                      RACObserve(self, loggedIn)
                                                      ] reduce:^(NSString *username, NSString *password, NSNumber *loggingIn, NSNumber *loggedIn) {
                                                          return @(username.length > 0 && password.length > 0 && !loggingIn.boolValue && !loggedIn.boolValue);
                                                      }];
    [[self.logInButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(UIButton *sender) {
        @strongify(self);
        RACSignal *loginSignal = [LoginManager.sharedManager
                                  logInWithUsername:self.usernameTextField.text
                                  password:self.passwordTextField.text];
        [loginSignal subscribeError:^(NSError *error) {
            @strongify(self);
            [self presentError:error];
        } completed:^{
            @strongify(self);
            self.loggedIn = YES;
        }];
    }];
    RAC(self, loggedIn) = [[NSNotificationCenter.defaultCenter
                            rac_addObserverForName:UserDidLogOutNotification object:nil]
                           mapReplace:@NO];
}
 */

/*
 连接依赖的操作
 
 依赖经常用在网络请求,当下一个对服务器网络请求需要构建在前一个完成时,可以看一下下面的代码:
 
 [client logInWithSuccess:^{
 [client loadCachedMessagesWithSuccess:^(NSArray *messages) {
 [client fetchMessagesAfterMessage:messages.lastObject success:^(NSArray *nextMessages) {
 NSLog(@"Fetched all messages.");
 } failure:^(NSError *error) {
 [self presentError:error];
 }];
 } failure:^(NSError *error) {
 [self presentError:error];
 }];
 } failure:^(NSError *error) {
 [self presentError:error];
 }];
 
 
 
 ReactiveCocoa 则让这种模式特别简单:
 [[[[client logIn]
 then:^{
 return [client loadCachedMessages];
 }]
 flattenMap:^(NSArray *messages) {
 return [client fetchMessagesAfterMessage:messages.lastObject];
 }]
 subscribeError:^(NSError *error) {
 [self presentError:error];
 } completed:^{
 NSLog(@"Fetched all messages.");
 }];
 */

/*
 并行地独立地工作
 
 与独立的数据集并行,然后将它们合并成一个最终的结果在Cocoa中是相当不简单的,并且还经常涉及大量的同步:
 __block NSArray *databaseObjects;
 __block NSArray *fileContents;
 NSOperationQueue *backgroundQueue = [[NSOperationQueue alloc] init];
 NSBlockOperation *databaseOperation = [NSBlockOperation blockOperationWithBlock:^{
 databaseObjects = [databaseClient fetchObjectsMatchingPredicate:predicate];
 }];
 NSBlockOperation *filesOperation = [NSBlockOperation blockOperationWithBlock:^{
 NSMutableArray *filesInProgress = [NSMutableArray array];
 for (NSString *path in files) {
 [filesInProgress addObject:[NSData dataWithContentsOfFile:path]];
 }
 fileContents = [filesInProgress copy];
 }];
 NSBlockOperation *finishOperation = [NSBlockOperation blockOperationWithBlock:^{
 [self finishProcessingDatabaseObjects:databaseObjects fileContents:fileContents];
 NSLog(@"Done processing");
 }];
 [finishOperation addDependency:databaseOperation];
 [finishOperation addDependency:filesOperation];
 [backgroundQueue addOperation:databaseOperation];
 [backgroundQueue addOperation:filesOperation];
 [backgroundQueue addOperation:finishOperation];
 */

- (void)queueTest{
    //上面的代码能够简单地用合成signals来清理和优化:
    /*
    RACSignal *databaseSignal = [[databaseClient
                                  fetchObjectsMatchingPredicate:predicate]
                                 subscribeOn:[RACScheduler scheduler]];
    RACSignal *fileSignal = [RACSignal startEagerlyWithScheduler:[RACScheduler scheduler] block:^(id subscriber) {
        NSMutableArray *filesInProgress = [NSMutableArray array];
        for (NSString *path in files) {
            [filesInProgress addObject:[NSData dataWithContentsOfFile:path]];
        }
        [subscriber sendNext:[filesInProgress copy]];
        [subscriber sendCompleted];
    }];
    [[RACSignal
      combineLatest:@[ databaseSignal, fileSignal ]
      reduce:^ id (NSArray *databaseObjects, NSArray *fileContents) {
          [self finishProcessingDatabaseObjects:databaseObjects fileContents:fileContents];
          return nil;
      }]
     subscribeCompleted:^{
         NSLog(@"Done processing");
     }];
     */
}

/*
 简化集合转换
 
 像map, filter, fold/reduce 这些高级功能在Foundation中是极度缺少的m导致了一些像下面这样循环集中的代码:
 RACSequence能够允许Cocoa集合用统一的方式操作:
 */
- (void)sequence{
    NSArray *strings = @[@"hello",@"yes"];
    RACSequence *results = [[strings.rac_sequence
                             filter:^ BOOL (NSString *str) {
                                 return str.length >= 2;
                             }]
                            map:^(NSString *str) {
                                return [str stringByAppendingString:@"foobar"];
                            }];
}

@end
