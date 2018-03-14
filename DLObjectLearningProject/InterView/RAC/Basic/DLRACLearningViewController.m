//
//  DLRACLearningViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 12/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  http://www.cocoachina.com/industry/20140621/8905.html

#import "DLRACLearningViewController.h"
#import <ReactiveObjC/ReactiveObjC.h>

@interface DLRACLearningViewController ()<UIScrollViewDelegate>
@property(nonatomic, strong) UILabel *outputLabel;
@property(nonatomic, strong) UITextField *inputTextField;
@property(nonatomic, strong) DLTestModel *model;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, strong) UIImageView *imageView;
@property(nonatomic, strong) UIButton *shareButton;
@property(nonatomic, strong) DLViewModel *viewModel;
@property(nonatomic, strong) UILabel *pinLikedCountLabel;
@property(nonatomic, strong) UIImageView *likePinImageView;
@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) UILabel *statusLabel;

@property(nonatomic, assign) BOOL availabilityStatus;
@end

@implementation DLRACLearningViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 先说说RAC中必须要知道的宏
- (void)macroTest{
    //RAC(TARGET, [KEYPATH, [NIL_VALUE]])
    RAC(self.outputLabel,text) = self.inputTextField.rac_textSignal;
    RAC(self.outputLabel,text,@"收到nil时就显示我") = self.inputTextField.rac_textSignal;
    
    /*
     这个宏是最常用的，RAC()总是出现在等号左边，等号右边是一个RACSignal，表示的意义是将一个对象的一个属性和一个signal绑定，signal每产生一个value（id类型），都会自动执行：
     [TARGET setValue:value ?: NIL_VALUE forKeyPath:KEYPATH];
     */
    
    
    /*
     RACObserve(TARGET, KEYPATH)
     数字值会升级为NSNumber *，当setValue:forKeyPath时会自动降级成基本类型（int, float ,BOOL等），所以RAC绑定一个基本类型的值是没有问题的
     作用是观察TARGET的KEYPATH属性，相当于KVO，产生一个RACSignal
     最常用的使用，和RAC宏绑定属性：
     */
    RAC(self.outputLabel,text) = RACObserve(self.model, name);
    //上面的代码将label的输出和model的name属性绑定，实现联动，name但凡有变化都会使得label输出
    
    /*
     @weakify(Obj);
     @strongify(Obj);
     他们的作用主要是在block内部管理对self的引用：
     */
    //这个宏为什么这么吊，前面加@，其实就是一个啥都没干的@autoreleasepool {}前面的那个@，为了显眼罢了。
    @weakify(self)
    [RACObserve(self, name) subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        self.outputLabel.text = x;
    }];
}


/*
 除了RAC中常用宏的使用，有一些宏的实现方法也很值得观摩。
 http://www.cocoachina.com/industry/20140621/8905.html
 */

/*
 使用方向：
 http://www.cocoachina.com/industry/20140609/8737.html
 */



//正常的写法可能是这样，很直观。
//- (void)configureWithItem:(HBItem *)item
//{
//    self.username.text = item.text;
//    [self.avatarImageView setImageWithURL: item.avatarURL];
//    // 其他的一些设置
//}


//但如果用RAC，可能就是这样
//- (id)init
//{
//    if (self = [super init]) {
//        @weakify(self);
//        [RACObserve(self, viewModel) subscribeNext:^(HBItemViewModel *viewModel) {
//            @strongify(self);
//            self.username.text = viewModel.item.text;
//            [self.avatarImageView setImageWithURL: viewModel.item.avatarURL];
//            // 其他的一些设置
//        }];
//    }
//}
/*
 也就是先把数据绑定，接下来只要数据有变化，就会自动响应变化。在这里，每次viewModel改变时，内容就会自动变成该viewModel的内容。
 */

/*
 通过这张图可以看到，这非常像中学时学的函数，比如 f(x) = y，某一个函数的输出又可以作为另一个函数的输入，比如 f(f(x)) = z，这也正是「函数响应式编程」(FRP)的核心。
 
 有些地方需要注意下，比如把signal作为local变量时，如果没有被subscribe，那么方法执行完后，该变量会被dealloc。但如果signal有被subscribe，那么subscriber会持有该signal，直到signal sendCompleted或sendError时，才会解除持有关系，signal才会被dealloc。
 */

#pragma mark - RACCommand
/*
 RACCommand 通常用来表示某个Action的执行，比如点击Button。它有几个比较重要的属性：executionSignals / errors / executing。
 RACCommand 通常用来表示某个Action的执行，比如点击Button。它有几个比较重要的属性：executionSignals / errors / executing。
 
 1、executionSignals是signal of signals，如果直接subscribe的话会得到一个signal，而不是我们想要的value，所以一般会配合switchToLatest。
 
 2、errors。跟正常的signal不一样，RACCommand的错误不是通过sendError来实现的，而是通过errors属性传递出来的。
 
 3、executing表示该command当前是否正在执行。
 */
//假设有这么个需求：当图片载入完后，分享按钮才可用。那么可以这样：
- (void)commandTest{
    RACSignal *imageAvailasbleSignal = [RACObserve(self, imageView.image) map:^id _Nullable(id  _Nullable value) {
        return value ? @YES:@NO;
    }];
    self.shareButton.rac_command = [[RACCommand alloc] initWithEnabled:imageAvailasbleSignal signalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        //do share logic
        return [RACSignal empty];
    }];
}

//手动执行某个command，比如双击图片点赞
- (void)praiseHandle{
    @weakify(self)
    [RACObserve(self, viewModel.hasLiked) subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        self.pinLikedCountLabel.text = self.viewModel.likedCount;
        self.likePinImageView.image = [UIImage imageNamed:self.viewModel.hasLiked ? @"pin_liked":@"pin_like"];
    }];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] init];
    tapGesture.numberOfTapsRequired = 2;
    [[tapGesture rac_gestureSignal] subscribeNext:^(__kindof UIGestureRecognizer * _Nullable x) {
        [self.viewModel.likeCommand execute:nil];
    }];
}

//再比如某个App要通过Twitter登录，同时允许取消登录，就可以这么做 (source)
//_twitterLoginCommand = [[RACCommand alloc] initWithSignalBlock:^(id _) {
//    @strongify(self);
//    return [[self
//             twitterSignInSignal]
//            takeUntil:self.cancelCommand.executionSignals];
//}];
//
//RAC(self.authenticatedUser) = [self.twitterLoginCommand.executionSignals switchToLatest];


//常用的模式
//map + switchToLatest
/*
 switchToLatest: 的作用是自动切换signal of signals到最后一个，比如之前的command.executionSignals就可以使用switchToLatest:。
 map:的作用很简单，对sendNext的value做一下处理，返回一个新的值。
 */

- (void)switchToLatestTest{
    NSArray *pins = @[@172230988, @172230947, @172230899, @172230777, @172230707];
    __block NSInteger index = 0;
    
    RACSignal *signal = [[[[RACSignal interval:0.1 onScheduler:[RACScheduler scheduler]]
                           take:pins.count]
                          map:^id(id value) {
//                              return [[[HBAPIManager sharedManager] fetchPinWithPinID:[pins[index++] intValue]] doNext:^(id x) {
//                                  NSLog(@"这里只会执行一次");
//                              }];
                              return nil;
                          }]
                         switchToLatest];
    
//    [signal subscribeNext:^(HBPin *pin) {
//        NSLog(@"pinID:%d", pin.pinID);
//    } completed:^{
//        NSLog(@"completed");
//    }];
    
    // output
    // 2014-06-05 17:40:49.851 这里只会执行一次
    // 2014-06-05 17:40:49.851 pinID:172230707
    // 2014-06-05 17:40:49.851 completed
}


//takeUntil
/*
 takeUntil:someSignal 的作用是当someSignal sendNext时，当前的signal就sendCompleted，someSignal就像一个拳击裁判，哨声响起就意味着比赛终止。
 它的常用场景之一是处理cell的button的点击事件，比如点击Cell的详情按钮，需要push一个VC，就可以这样：
 */
- (void)takeUntilTest{
//    [[[cell.detailButton rac_signalForControlEvents:UIControlEventTouchUpInside]
//      takeUntil:cell.rac_preparedForReuseSignal]
//     subscribeNext:^(id x){
//         // generate and push ViewController
//     }];
    
    //如果不加takeUntil:cell.rac_prepareForReuseSignal，那么每次Cell被重用时，该button都会被addTarget:selector。
}

//替换Delegate
/*
- (RACSignal *)rac_isActiveSignal {
    self.delegate = self;
    RACSignal *signal = objc_getAssociatedObject(self, _cmd);
    if (signal != nil) return signal;
    
    // Create two signals and merge them
    RACSignal *didBeginEditing = [[self rac_signalForSelector:@selector(searchDisplayControllerDidBeginSearch:)
                                                 fromProtocol:@protocol(UISearchDisplayDelegate)] mapReplace:@YES];
    RACSignal *didEndEditing = [[self rac_signalForSelector:@selector(searchDisplayControllerDidEndSearch:)
                                               fromProtocol:@protocol(UISearchDisplayDelegate)] mapReplace:@NO];
    signal = [RACSignal merge:@[didBeginEditing, didEndEditing]];
    
    
    objc_setAssociatedObject(self, _cmd, signal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return signal;
}
*/

/*
 使用ReactiveViewModel的didBecomActiveSignal
 
 ReactiveViewModel是另一个project， 后面的MVVM中会讲到，通常的做法是在VC里设置VM的active属性(RVMViewModel自带该属性)，然后在VM里subscribeNext didBecomActiveSignal，比如当Active时，获取TableView的最新数据。
 */

/*
 RACSubject的使用场景
 
 一般不推荐使用RACSubject，因为它过于灵活，滥用的话容易导致复杂度的增加。但有一些场景用一下还是比较方便的，比如ViewModel的errors。
 */



/*
 rac_signalForSelector
 
 rac_signalForSelector: 这个方法会返回一个signal，当selector执行完时，会sendNext，也就是当某个方法调用完后再额外做一些事情。用在category会比较方便，因为Category重写父类的方法时，不能再通过[super XXX]来调用父类的方法，当然也可以手写Swizzle来实现，不过有了rac_signalForSelector:就方便多了。
 
 rac_signalForSelector: fromProtocol: 可以直接实现对protocol的某个方法的实现（听着有点别扭呢），比如，我们想实现UIScrollViewDelegate的某些方法，可以这么写
 */

- (void)delegateTest{
    [[self rac_signalForSelector:@selector(scrollViewDidEndDecelerating:) fromProtocol:@protocol(UIScrollViewDelegate)] subscribeNext:^(RACTuple * _Nullable x) {
        //do something
    }];
    
    [[self rac_signalForSelector:@selector(scrollViewDidScroll:) fromProtocol:@protocol(UIScrollViewDelegate)] subscribeNext:^(RACTuple * _Nullable x) {
        //do something
    }];
   
    /*
     注意，这里的delegate需要先设置为nil，再设置为self，而不能直接设置为self，如果self已经是该scrollView的Delegate的话。
     */
    self.scrollView.delegate = nil;
    self.scrollView.delegate = self;
    
}


/*
 ViewModel中signal, property, command的使用
 
 初次使用RAC+MVVM时，往往会疑惑，什么时候用signal，什么时候用property，什么时候用command？
 
 一般来说可以使用property的就直接使用，没必要再转换成signal，外部RACObserve即可。使用signal的场景一般是涉及到多个property或多个signal合并为一个signal。command往往与UIControl/网络请求挂钩。
 */

/*
 常见场景的处理
 
 检查本地缓存，如果失效则去请求网络数据并缓存到本地
 */
/*
- (RACSignal *)loadData{
    return [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //If the cache is valid the we can just immediately send the cached data and be done
        if (self.cacheValid) {
            [subscriber sendNext:self.cachedData];
            [subscriber sendCompleted];
        }else{
            [subscriber sendError:self.stateCachedError];
        }
        return nil;
    }] subscribeOn:[RACScheduler scheduler]];
}

- (void)update{
    
    [[[[self loadData] catch:^RACSignal * _Nonnull(NSError * _Nonnull error) {
        // Catch the error from -loadData. It means our cache is stale. Update
        // our cache and save it.
        return [[self updateCachedData] doNext:^(id data){
            [self cacheData:data];
        }];
        // Our work up until now has been on a background scheduler. Get our
        // results delivered on the main thread so we can do UI work.
    }] deliverOn:RACScheduler.mainThreadScheduler] subscribeNext:^(id  _Nullable x) {
        // Update your UI based on `data`.
        
        // Update again after `updateInterval` seconds have passed.
        [[RACSignal interval:updateInterval] take:1] subscribeNext:^(id _) {
            [self update];
        }];
    }];
}
 */

//检查用户名是否可用
- (void)setupUsernameAvailabilityChecking {
    /*
    RAC(self, availabilityStatus) = [[[RACObserve(self.userTemplate, username)
                                       throttle:kUsernameCheckThrottleInterval] //throttle表示interval时间内如果有sendNext，则放弃该nextValue
                                      map:^(NSString *username) {
                                          if (username.length == 0) return [RACSignal return:@(UsernameAvailabilityCheckStatusEmpty)];
                                          return [[[[[FIBAPIClient sharedInstance]
                                                     getUsernameAvailabilityFor:username ignoreCache:NO]
                                                    map:^(NSDictionary *result) {
                                                        NSNumber *existsNumber = result[@"exists"];
                                                        if (!existsNumber) return @(UsernameAvailabilityCheckStatusFailed);
                                                        UsernameAvailabilityCheckStatus status = [existsNumber boolValue] ? UsernameAvailabilityCheckStatusUnavailable : UsernameAvailabilityCheckStatusAvailable;
                                                        return @(status);
                                                    }]
                                                   catch:^(NSError *error) {
                                                       return [RACSignal return:@(UsernameAvailabilityCheckStatusFailed)];
                                                   }] startWith:@(UsernameAvailabilityCheckStatusChecking)];//startWith的内部实现是concat，这里表示先将状态置为checking，然后再根据网络请求的结果设置状态。
                                      }]
                                     switchToLatest];//可以看到这里也使用了map + switchToLatest模式，这样就可以自动取消上一次的网络请求。
     */
}

//token过期后自动获取新的
/*
 开发APIClient时，会用到AccessToken，这个Token过一段时间会过期，需要去请求新的Token。比较好的用户体验是当token过期后，自动去获取新的Token，拿到后继续上一次的请求，这样对用户是透明的。
 */
- (void)tokenTest{
    RACSignal *requestSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // suppose first time send request, access token is expired or invalid
        // and next time it is correct.
        // the block will be triggered twice.
        static BOOL isFirstTime = 0;
        NSString *url = @"http://httpbin.org/ip";
        if (!isFirstTime) {
            url = @"http://nonexists.com/error";
            isFirstTime = 1;
        }
        NSLog(@"url:%@", url);
        /*
        [[AFHTTPRequestOperationManager manager] GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [subscriber sendNext:responseObject];
            [subscriber sendCompleted];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [subscriber sendError:error];
        }];
         */
        
        return nil;
    }];
    
    self.statusLabel.text = @"sending request...";
    [[requestSignal catch:^RACSignal *(NSError *error) {
        self.statusLabel.text = @"oops, invalid access token";
        
        // simulate network request, and we fetch the right access token
        return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            double delayInSeconds = 1.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [subscriber sendNext:@YES];
                [subscriber sendCompleted];
            });
            return nil;
        }] concat:requestSignal];// concat:按一定顺序拼接信号，当多个信号发出的时候，有顺序的接收信号。
    }] subscribeNext:^(id x) {
        if ([x isKindOfClass:[NSDictionary class]]) {
            self.statusLabel.text = [NSString stringWithFormat:@"result:%@", x[@"origin"]];
        }
    } completed:^{
        NSLog(@"completed");
    }];
}

/*
 RAC我自己感觉遇到的几个难点是: 1) 理解RAC的理念。 2) 熟悉常用的API。3) 针对某些特定的场景，想出比较合理的RAC处理方式。不过看多了，写多了，想多了就会慢慢适应。下面是我在实践过程中遇到的一些小坑。
 */

/*
 ReactiveCocoaLayout
 
 有时Cell的内容涉及到动态的高度，就会想到用Autolayout来布局，但RAC已经为我们准备好了ReactiveCocoaLayout，所以我想不妨就拿来用一下。
 
 ReactiveCocoaLayout的使用好比「批地」和「盖房」，先通过insetWidth:height:nullRect从某个View中划出一小块，拿到之后还可以通过divideWithAmount:padding:fromEdge 再分成两块，或sliceWithAmount:fromEdge再分出一块。这些方法返回的都是signal，所以可以通过RAC(self.view, frame) = someRectSignal 这样来实现绑定。但在实践中发现性能不是很好，多批了几块地就容易造成主线程卡顿。
 
 所以ReactiveCocoaLayout最好不用或少用。
 */

/*
 调试
 
 刚开始写RAC时，往往会遇到这种情况，满屏的调用栈信息都是RAC的，要找出真正出现问题的地方不容易。曾经有一次在使用[RACSignal combineLatest: reduce:^id{}]时，忘了在Block里返回value，而Xcode也没有提示warning，然后就是莫名其妙地挂起了，跳到了汇编上，也没有调用栈信息，这时就只能通过最古老的注释代码的方式来找到问题的根源。
 
 不过写多了之后，一般不太会犯这种低级错误。
 */

/*
 strongify / weakify dance
 
 因为RAC很多操作都是在Block中完成的，这块最常见的问题就是在block直接把self拿来用，造成block和self的retain cycle。所以需要通过@strongify和@weakify来消除循环引用。
 
 有些地方很容易被忽略，比如RACObserve(thing, keypath)，看上去并没有引用self，所以在subscribeNext时就忘记了weakify/strongify。但事实上RACObserve总是会引用self，即使target不是self，所以只要有RACObserve的地方都要使用weakify/strongify。
 */




@end

@implementation DLTestModel
@end

@implementation DLViewModel
- (instancetype)init
{
    self = [super init];
    if (self) {
        void (^updatePinLikeStatus)(void) = ^{
            self.pin.likedCount = self.pin.hasLiked ? self.pin.likedCount - 1 : self.pin.likedCount + 1;
            self.pin.hasLiked = !self.pin.hasLiked;
        };
        
        _likeCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
            //先展示效果，再发送请求
            updatePinLikeStatus();
            //                return [[HBAPIManager sharedManager] likePinWithPinID:self.pin.pinID];
            return [RACSignal empty];
        }];
        
        [_likeCommand.errors subscribeNext:^(NSError * _Nullable x) {
            //发生错误时，回滚
            updatePinLikeStatus();
        }];
        
        
    }
    return self;
}
@end

@interface HBCViewModel()
@property(nonatomic, strong) RACCommand *fetchLatestCommand;
@property(nonatomic, strong) RACCommand *fetchMoreCommand;
@end

@implementation HBCViewModel
- (instancetype)init
{
    self = [super init];
    if (self) {
        _errors = [RACSubject subject];
    }
    return self;
}

- (void)dealloc{
    [_errors sendCompleted];
}

- (void)initWork{
    _fetchLatestCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        //fetch latest data
        return [RACSignal empty];
    }];
    
    _fetchMoreCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        //fetch more data
        return [RACSignal empty];
    }];
    
    @weakify(self)
    [self.didBecomeActiveSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        [self.fetchMoreCommand execute:nil];
    }];
    
    [[RACSignal merge:@[_fetchMoreCommand,_fetchLatestCommand]] subscribe:self.errors];
    
}
@end
