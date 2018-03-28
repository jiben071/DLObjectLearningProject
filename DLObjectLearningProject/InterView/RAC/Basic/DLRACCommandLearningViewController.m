//
//  DLRACCommandLearningViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 28/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  http://www.yiqivr.com/2015/10/19/译-ReactiveCocoa基础：理解并使用RACCommand/
//  http://blog.harrisonxi.com/2017/09/RAC中用RACCommand处理指令.html  （推荐）

#import "DLRACCommandLearningViewController.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import "NSString+EmailAdditions.h"

@interface DLRACCommandLearningViewController ()
@property(nonatomic, strong) SubscribeViewModel *viewModel;
@property(nonatomic, strong) UITextField *emailTextField;
@property(nonatomic, strong) UIButton *subscribeButton;
@property(nonatomic, strong) UILabel *statusLabel;
@end

@implementation DLRACCommandLearningViewController

- (SubscribeViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[SubscribeViewModel alloc] init];
    }
    return _viewModel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self addViews];
    [self defineLayout];
    [self bindWithViewModel];
}

- (void)addViews {
    [self.view addSubview:self.emailTextField];
    [self.view addSubview:self.subscribeButton];
    [self.view addSubview:self.statusLabel];
}

- (void)defineLayout {
    @weakify(self);
    
//    [self.emailTextField mas_makeConstraints:^(MASConstraintMaker *make) {
//        @strongify(self);
//        make.top.equalTo(self.view).with.offset(100.f);
//        make.left.equalTo(self.view).with.offset(20.f);
//        make.height.equalTo(@50.f);
//    }];
//
//    [self.subscribeButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        @strongify(self);
//        make.centerY.equalTo(self.emailTextField);
//        make.right.equalTo(self.view).with.offset(-25.f);
//        make.width.equalTo(@70.f);
//        make.height.equalTo(@30.f);
//        make.left.equalTo(self.emailTextField.mas_right).with.offset(20.f);
//    }];
//
//    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//        @strongify(self);
//        make.top.equalTo(self.emailTextField.mas_bottom).with.offset(20.f);
//        make.left.equalTo(self.emailTextField);
//        make.right.equalTo(self.subscribeButton);
//        make.height.equalTo(@30.f);
//    }];
}

- (UITextField *)emailTextField {
    if (!_emailTextField) {
        _emailTextField = [UITextField new];
        _emailTextField.borderStyle = UITextBorderStyleRoundedRect;
        _emailTextField.font = [UIFont boldSystemFontOfSize:16];
        _emailTextField.placeholder = NSLocalizedString(@"Email address", nil);
        _emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
        _emailTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }
    return _emailTextField;
}

- (UIButton *)subscribeButton {
    if (!_subscribeButton) {
        _subscribeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [_subscribeButton setTitle:NSLocalizedString(@"Subscribe", nil) forState:UIControlStateNormal];
    }
    return _subscribeButton;
}

- (UILabel *)statusLabel {
    if (!_statusLabel) {
        _statusLabel = [UILabel new];
    }
    return _statusLabel;
}

/*
 RACCommand代表着与交互后即将执行的一段流程。通常这个交互是UI层级的，比如你点击个Button。
 
 1)RACCommand可以方便的将Button与enable状态进行绑定，也就是当enable为NO的时候，这个RACCommand将不会执行。
 2)RACCommand还有一个常见的策略：allowsConcurrentExecution，默认为NO，也就是是当你这个command正在执行的话，你多次点击Button是没有用的。
 3)创建一个RACCommand的返回值是一个Signal，这个Signal会返回next或者complete或者error。
 */

/*
 RACCommand范例
 接下来我们将实现一个邮箱订阅的功能，只有一个输入框和一个订阅按钮，当用户在输入框输入正确的邮箱，点击订阅将向服务器发送订阅的邮箱号。虽然看起来是一个很简单的需求，但是我们需要处理的细节还是挺多的，比如用户快速的点击了两次订阅按钮、还有如何捕捉订阅失败、如果这个邮箱是非法的怎么办？如果我们用RACCommand来处理的话，其实是非常方便的。
 */


- (void)bindWithViewModel{
    RAC(self.viewModel,email) = self.emailTextField.rac_textSignal;
    /*
     因为在ReactiveCocoa中，UIButton的属性rac_command定义在了一个UIButtton+RACCommandSupport类别，UIButton的enable状态是与command的执行过程相关联绑定的。
     */
    self.subscribeButton.rac_command = self.viewModel.subscribeCommand;
    RAC(self.statusLabel,text) = RACObserve(self.viewModel, statusMessage);
    
    /*
     当你需要手动调用这个command的时候，可以调用-[RACCommand execute:]方法，传入的参数是可选的，我们在这个例子中将传入nil（其实是button把自己当做参数传入了-execute:方法），另外，这个方法也是一个监视执行流程的一个好地方，比如我们可以这么做：
     */
    [[self.viewModel.subscribeCommand execute:nil] subscribeCompleted:^{
        NSLog(@"The command executed");
    }];
}

/*
 信号流 - 即RACSignal，一组next / error / completed信号组成，本文称之为信号流。
 
 发送信号 - sendNext / sendError / sendCompleted，统称为发送信号。
 
 主流程信号流 - execute:成功执行一次指令产生的指令流程信号流。
 
 因为将RACSignal也称为信号，容易引起理解的困难，而其通常就是一组信号组成，所以在这里称之为信号流。
 */

/*
 RACCommand的用途
 
 通常来说我们的App中会存在很多UI指令需要等待异步处理完成（比如等待网络请求返回结果），处理这些UI指令时如果我们手动去处理逻辑的话，一般需要完成以下内容：
 
 保证指令不会在正在执行时被重复执行。
 维护指令是否在执行中的状态，方便外界监视，用来确定是否需要展示loading界面。
 维护指令是否可以执行的状态，方便和外界UI状态进行同步。
 提供执行指令的入口和指令执行的信号流供处理后续逻辑。
 
 而RACCommand的出现就是为了将以上大部分逻辑封装起来，方便大家使用。
 */

/*
 RACCommand的公开属性和方法
 
 executionSignals & errors
 在指令成功开始执行后executionSignals会发送一个信号，信号内包含的数据是一个信号流。对，这是一个信号流的信号流，和指针的指针一样绕口。后面介绍内部实现的时候再详细介绍这个属性。
 
 在指令开始执行但遇到错误时errors会发送一个next信号，信号的数据是一个NSError。这里不能发送error信号，因为发送error信号后这整个信号流就会终止了。
 
 
 
 allowsConcurrentExecution
 是否支持同时多次执行指令，通常来说都会使用默认值NO。在本文里，我们暂不讨论此属性值为YES的情况。
 
 
 
 executing & enabled
 executing用来标记指令是否正在运行，通常用于绑定到loading界面的hidden属性上。
 
 enabled用来标记指令是否可以运行，通常用于绑定到UIButton的enabled属性上。
 
 一般来说以下两种情况下enabled为NO：
 
 指令禁止同时多次运行，且指令正在运行中时。
 初始化RACCommand时传入了enabledSignal，且enabledSignal返回NO的时候。
 
 
 
 初始化方法 - initWithEnabled:signalBlock:
 enabledSignal参数在上面提到了，用于控制指令是否可执行。
 
 而signalBlock参数是为了传递数据和执行指令流程用的，先看一下这个block的类型：
 
 RACSignal<ValueType> * (^)(InputType _Nullable input)
 返回一个信号流，要求输入一个input值。这里返回的信号流就是给之前的executionSignals用的，而这里的输入值就是后面的execute:方法要用的。具体为什么要用这种方式，会在后面的单独章节里介绍。
 
 
 执行指令方法 - execute:
 
 execute:方法用于执行指令，input用于传递一些自定义的数据，这个输入值可以为空。
 
 在指令可以执行时，会通过executionSignals发出成功开始执行指令的主流程信号流并将之返回，否则会直接返回一个RACErrorSignal，另外在执行指令过程中遇到的错误信号会由errors信号流收集后统一发出。
 
 如果想要获得单次执行的内部信号流，特别是想要获得信号流里的原始错误，可以从execute:方法的返回值获得对应信号流。
 
 */

/*
 为什么一定要使用『主流程信号流』的形式
 
 很多人要问，为什么不是直接发送一个执行成功或一个执行失败两种信号就可以了。
 
 这里要说下执行的流程，这个流程不一定是单步的，所以使用RACCommand的时候是需要了解每一步执行的情况的。比如以下载文件为例：整个流程可能分为获得文件地址列表，逐个下载文件，全部下载完成，下载失败等各种步骤和状态。
 
 这种时候每一个单独的执行流程就作为一个整体封装起来就更合理，而封装『流程』最合适的当然就是信号流了。
 
 为什么要单独封装errors信号流
 
 这样可以使得我们处理问题时更专注，在executionSignals信号流里只处理流程状态相关的逻辑，在errors信号流里专注于各种错误的处理。
 
 当然不得不承认这在某些情况下也会带来问题：比如某些流程状态和错误状态很强相关的场景下，可能将代码写在一起反而会更容易理解。不过总体来说目前的设计更为通用一点。
 
 另外一个重点是这样可以保证executionSignals能使用switchToLatest方法。这个后文会介绍。
 
 为什么主流程信号流执行时还需要一个input参数
 
 这个一定意义上来说和UIButton的点击事件- (void)clickAction:(id)sender为什么需要sender差不多。
 
 展开来说的话就是函数需要消除副作用成为纯函数，所以我们的主流程信号流也要具有这个特性，使得每一次的执行流程更独立。
 
 通常来说这个input是用来区分调用者的，当然也可以用来传递一些其它的关键参数。
 */




@end

@interface SubscribeViewModel()
@property(nonatomic, strong) RACSignal *emailValidSignal;
@end
@implementation SubscribeViewModel
- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)mapSubscribeCommandStateToStatusMessage{
    /*
     初始化一个Signal来表示每当command开始执行的时候返回一个表示开始的字符串：
     */
    RACSignal *startedMessageSource = [self.subscribeCommand.executionSignals map:^id _Nullable(id  _Nullable value) {
        return NSLocalizedString(@"Sending request...", nil);
    }];
    
    /*
     实现一个类似的Signal来表示每当command执行完毕时候转换返回一个字符串：
     */
    RACSignal *completedMessageSource = [self.subscribeCommand.executionSignals flattenMap:^__kindof RACSignal * _Nullable(RACSignal  *_Nullable subcribeSignal) {
        /*materialize操作符允许我们将Signal转换成RACEvent，接下来我们就可以过滤这些事件，只允许成功事件通过，并且将成功事件转换成一个代表成功的字符串。*/
        return [[[subcribeSignal materialize] filter:^BOOL(RACEvent  *_Nullable event) {
            return event.eventType == RACEventTypeCompleted;
        }] map:^id _Nullable(id  _Nullable value) {
            return NSLocalizedString(@"Thanks", nil);
        }];
    }];
    
    /*
    @weakify(self);
    [self.subscribeCommand.executionSignals subscribeNext:^(RACSignal *subscribeSignal) {
        [subscribeSignal subscribeCompleted:^{
            @strongify(self);
            self.statusMessage = @"Thanks";
        }];
    }];
    //然而，我并不喜欢上面的实现方式，不仅是因为有副作用，而且对self的引用也很不方便，我们不得不使用@weakify和@strongify来避免循环引用。
    */
    
    /*
     这儿还有一个关于executionSignals属性比较重要的知识点，它并不包含error事件，因此有一个专门的errors属性的Signal，这个Signal会在执行command的任何阶段调用next:发送错误信息，它并不会发送error:，因为error:会终止信号。因此我们可以轻松的转换这个错误信息：
     */
    RACSignal *failedMessageSource = [[self.subscribeCommand.errors subscribeOn:[RACScheduler mainThreadScheduler]] map:^id _Nullable(NSError * _Nullable value) {
        return NSLocalizedString(@"Error :(", nil);
    }];
    
    //到现在为止，我们已经有了三个带有返回信息的Signal，因此我们将它们合并到一个新的Signal，并且绑定到view model的statusMessage属性：
    RAC(self,statusMessage) = [RACSignal merge:@[startedMessageSource,completedMessageSource,failedMessageSource]];
    
    //到这儿，整个RACCommand的流程就差不多结束了，我认为这种实现方式有很多的优势比起在view controller中使用UITextFieldDelegate和保存过多的变量或属性。
}

/*
 关于RACCommand的其他兴趣点
 
 RACCommand有一个executingSignal属性，当execute:调用的时候它会发送YES，而当command终止的时候它会发送NO。如果你只是想得到当前的值可以这么做：
 BOOL commandIsExecuting = [[command.executing first] boolValue];

 如果你在command enabled状态为NO的时候手动调用了-execute:，那么它会立刻发送一个错误，但是这个错误并不会发送到errorsSignal。
 -execute:方法会自动订阅Signal并且多播它，也就是说你不用订阅返回的Signal，但是如果你订阅的话也不用担心会产生副作用，也就是执行两次。
 */

- (RACCommand *)subscribeCommand{
    if (!_subscribeCommand) {
        @weakify(self)
        /*
         传入了一个enabledSignal参数，这个参数决定了command什么时候可以执行。在这个范例中，表示的是当我们输入的邮箱地址合法的时候才能执行。self.emailValidSignal是一个返回YES或者NO的Signal。
         */
        _subscribeCommand = [[RACCommand alloc] initWithEnabled:self.emailValidSignal signalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
            /*
             signalBlock参数将在每次我们需要执行command的时候调用，这个block返回一个Signal，这个Signal代表了之前所说的执行流程。我们之前保持了默认的allowsConcurrentExecution属性为NO，这就保证了我们在完成执行block之前不会再次执行这个block。
             */
            @strongify(self);
            return [SubscribeViewModel postEmail:self.email];
        }];
    }
    return _subscribeCommand;
}

+ (RACSignal *)postEmail:(NSString *)email{
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    manager.requestSerializer = [AFJSONRequestSerializer new];
//    NSDictionary *body = @{@"email": email ?: @""};
//    return [[[manager rac_POST:kSubscribeURL parameters:body] logError] replayLazily];
    return [RACSignal empty];
}

- (RACSignal *)emailValidSignal{
    if (!_emailValidSignal) {
        _emailValidSignal = [RACObserve(self, email) map:^id _Nullable(NSString  *_Nullable email) {
            return @([email isValidEmail]);
        }];
    }
    
    return _emailValidSignal;
}
@end
