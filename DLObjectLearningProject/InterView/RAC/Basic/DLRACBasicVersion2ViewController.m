//
//  DLRACBasicVersion2ViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 13/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  http://www.cocoachina.com/industry/20140115/7702.html

#import "DLRACBasicVersion2ViewController.h"
#import <ReactiveObjC/ReactiveObjC.h>

@interface DLRACBasicVersion2ViewController ()
@property(nonatomic, strong) UIButton *logInButton;
@property(nonatomic, strong) UITextField *usernameTextField;
@property(nonatomic, strong) UITextField *passwordTextField;
@property(nonatomic, assign) BOOL loggedIn;
@end

@implementation DLRACBasicVersion2ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

//联合信号，减少代码复杂度
- (void)handleCompletedSituation{
    RAC(self.logInButton,enabled) = [RACSignal
                                     combineLatest:@[
                                       self.usernameTextField.rac_textSignal,
                                       self.passwordTextField.rac_textSignal,
                                       RACObserve(self, loggedIn)
                                       ] reduce:^id (NSString *userName,NSString *password,NSNumber *loggedIn){
                                           return @(userName.length > 0 && password.length > 0 && !loggedIn.boolValue);
                                       }];
}

//冷信号(Cold)和热信号(Hot)
//上面提到过这两个概念，冷信号默认什么也不干，比如下面这段代码
- (void)coldSignalTest{
    RACSignal *signal = [RACSignal createSignal:^ RACDisposable * (id<RACSubscriber> subscriber) {
        NSLog(@"triggered");
        [subscriber sendNext:@"foobar"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    //我们创建了一个Signal，但因为没有被subscribe，所以什么也不会发生。加了下面这段代码后，signal就处于Hot的状态了，block里的代码就会被执行。
//    [signal subscribeCompleted:^{
//        NSLog(@"subscription %u", subscriptions);
//    }];
    
}
//或许你会问，那如果这时又有一个新的subscriber了，signal的block还会被执行吗？这就牵扯到了另一个概念：Side Effect
/*
 Side Effect
 还是上面那段代码，如果有多个subscriber，那么signal就会又一次被触发，控制台里会输出两次triggered。这或许是你想要的，或许不是。如果要避免这种情况的发生，可以使用 replay 方法，它的作用是保证signal只被触发一次，然后把sendNext的value存起来，下次再有新的subscriber时，直接发送缓存的数据。
 */


//UIView Categories
- (void)alertTest{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Alert" delegate:nil cancelButtonTitle:@"YES" otherButtonTitles:@"NO", nil];
    [[alertView rac_buttonClickedSignal] subscribeNext:^(NSNumber *indexNumber) {
        if ([indexNumber intValue] == 1) {
            NSLog(@"you touched NO");
        } else {
            NSLog(@"you touched YES");
        }
    }];
    [alertView show];
}

/*
 或许你会想，可不可以subscribe NSMutableArray.rac_sequence.signal，这样每次有新的object或旧的object被移除时都能知道，UITableViewController就可以根据dataSource的变化，来reloadData。但很可惜这样不行，因为RAC是基于KVO的，而NSMutableArray并不会在调用addObject或removeObject时发送通知，所以不可行。不过可以使用NSArray作为UITableView的dataSource，只要dataSource有变动就换成新的Array，这样就可以了。
 */

/*
 说到UITableView，再说一下UITableViewCell，RAC给UITableViewCell提供了一个方法：rac_prepareForReuseSignal，它的作用是当Cell即将要被重用时，告诉Cell。想象Cell上有多个button，Cell在初始化时给每个button都addTarget:action:forControlEvents，被重用时需要先移除这些target，下面这段代码就可以很方便地解决这个问题：

 */
//[[[self.cancelButton
//   rac_signalForControlEvents:UIControlEventTouchUpInside]
//  takeUntil:self.rac_prepareForReuseSignal]
// subscribeNext:^(UIButton *x) {
//     // do other things
// }];

/*
 还有一个很常用的category就是UIButton+RACCommandSupport.h，它提供了一个property：rac_command，就是当button被按下时会执行的一个命令，命令被执行完后可以返回一个signal，有了signal就有了灵活性。比如点击投票按钮，先判断一下有没有登录，如果有就发HTTP请求，没有就弹出登陆框，可以这么实现。
 */

- (void)testLoginPregress{
    /*
    voteButton.rac_command = [[RACCommand alloc] initWithEnabled:self.viewModel.voteCommand.enabled signalBlock:^RACSignal *(id input) {
        // Assume that we're logged in at first. We'll replace this signal later if not.
        RACSignal *authSignal = [RACSignal empty];
        
        if ([[PXRequest apiHelper] authMode] == PXAPIHelperModeNoAuth) {
            // Not logged in. Replace signal.
            authSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                @strongify(self);
                
                FRPLoginViewController *viewController = [[FRPLoginViewController alloc] initWithNibName:@"FRPLoginViewController" bundle:nil];
                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
                
                [self presentViewController:navigationController animated:YES completion:^{
                    [subscriber sendCompleted];
                }];
                
                return nil;
            }]];
        }
        
        return [authSignal then:^RACSignal *{//先执行authSignal判断是否登录，然后再发送投票请求
            @strongify(self);
            return [[self.viewModel.voteCommand execute:nil] ignoreValues];
        }];
    }];
    
    //处理错误
    [voteButton.rac_command.errors subscribeNext:^(id x) {
        [x subscribeNext:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        }];
    }];
     */
    
}




/*
 Data Structure Categories
 常用的数据结构，如NSArray, NSDictionary也都有添加相应的category，比如NSArray添加了rac_sequence，可以将NSArray转换为RACSequence，顺便说一下RACSequence, RACSequence是一组immutable且有序的values，不过这些values是运行时计算的，所以对性能提升有一定的帮助。RACSequence提供了一些方法，如array转换为NSArray，any:检查是否有Value符合要求，all:检查是不是所有的value都符合要求，这里的符合要求的，block返回YES，不符合要求的就返回NO。
 */

/*
 NotificationCenter Category
 NSNotificationCenter, 默认情况下NSNotificationCenter使用Target-Action方式来处理Notification，这样就需要另外定义一个方法，这就涉及到编程领域的两大难题之一：起名字。有了RAC，就有Signal，有了Signal就可以subscribe，于是NotificationCenter就可以这么来处理，还不用担心移除observer的问题。
 */
- (void)testNotification{
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"notification" object:nil] subscribeNext:^(NSNotification * _Nullable x) {
        NSLog(@"Notification Received");
    }];
}

/*
 NSObject Categories
 NSObject有不少的Category，我觉得比较有用的有这么几个
 */
//NSObject+RACDeallocating.h
//顾名思义就是在一个object的dealloc被触发时，执行的一段代码。
- (void)deallocSignalcategoryTest{
    NSArray *array = @[@"foo"];
    [[array rac_willDeallocSignal] subscribeCompleted:^{
        NSLog(@"oops, i will be gone");
    }];
    array = nil;//触发rac
}


/*
 NSObject+RACLifting.h
 有时我们希望满足一定条件时，自动触发某个方法，有了这个category就可以这么办
 */
- (void)liftingTest{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            [subscriber sendNext:@"A"];
        });
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"B"];
        [subscriber sendNext:@"Another B"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    //这里的rac_liftSelector:withSignals 就是干这件事的，它的意思是当signalA和signalB都至少sendNext过一次，接下来只要其中任意一个signal有了新的内容，doA:withB这个方法就会自动被触发。
    [self rac_liftSelector:@selector(doA:withB:) withSignals:signalA,signalB, nil];
    
}

- (void)doA:(NSString *)A withB:(NSString *)B{
    NSLog(@"A:%@ and B:%@", A, B);
}

/*
 NSObject+RACSelectorSignal.h
 这个category有rac_signalForSelector:和rac_signalForSelector:fromProtocol: 这两个方法。先来看前一个，它的意思是当某个selector被调用时，再执行一段指定的代码，相当于hook。比如点击某个按钮后，记个日志。后者表示该selector实现了某个协议，所以可以用它来实现Delegate。
 */

/*
 使用ViewModel的好处是，可以让Controller更加简单和轻便，而且ViewModel相对独立，也更加方便测试和重用。那Controller这时又该做哪些事呢？在MVVM体系中，Controller可以被看成View，所以它的主要工作是处理布局、动画、接收系统事件、展示UI。
 
 MVVM还有一个很重要的概念是 data binding，view的呈现需要data，这个data就是由ViewModel提供的，将view的data与ViewModel的data绑定后，将来双方的数据只要一方有变化，另一方就能收到。
 */

/*
 当一个signal被一个subscriber subscribe后，这个subscriber何时会被移除？答案是当subscriber被sendComplete或sendError时，或者手动调用[disposable dispose]。
 
 当subscriber被dispose后，所有该subscriber相关的工作都会被停止或取消，如http请求，资源也会被释放。
 
 Signal events是线性的，不会出现并发的情况，除非显示地指定Scheduler。所以-subscribeNext:error:completed:里的block不需要锁定或者synchronized等操作，其他的events会依次排队，直到block处理完成。
 
 Errors有优先权，如果有多个signals被同时监听，只要其中一个signal sendError，那么error就会立刻被传送给subscriber，并导致signals终止执行。相当于Exception。
 
 生成Signal时，最好指定Name, -setNameWithFormat: 方便调试。
 
 block代码中不要阻塞。
 */



@end
