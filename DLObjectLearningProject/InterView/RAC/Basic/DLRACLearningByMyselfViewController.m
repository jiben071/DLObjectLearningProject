//
//  DLRACLearningByMyselfViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 17/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  参考链接：
//  https://github.com/shuaiwang007/RAC
//  http://zhz.io/2017/08/18/ReactiveCocoa信号类分析/

#import "DLRACLearningByMyselfViewController.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import <ReactiveObjC/RACReturnSignal.h>

@interface DLRACLearningByMyselfViewController ()
@property(nonatomic, strong) UILabel *lable;
@property(nonatomic, strong) UITextField *textField;
@property(nonatomic, strong) RACSignal *signal;
@property(nonatomic, strong) UITextField *accountField;
@property(nonatomic, strong) UITextField *pwdField;
@property(nonatomic, strong) UIButton *loginBtn;
@end

@implementation DLRACLearningByMyselfViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //    [self flattemMapTest2];
//    [self mapTest];
//    [self signalTest];
//    [self subjectTest];
//    [self racSequenceTest];
//    [self connectionTest];
    [self commandTest];
}




#pragma mark - bind测试
/*
 bind（绑定）的使用思想和Hook的一样——>都是拦截API从而可以对数据进行操作，从而影响返回数据。
 发送信号的时候回来到30行的block。在这个block里我们可以对数据进行一些操作，那么35行打印的value和订阅信号后的value就会变了。变成什么样随你喜欢
 */
- (void)bindTest{
    //1.创建信号
    RACSubject *subject = [RACSubject subject];
    //2.绑定信号
    RACSignal *bindSignal = [subject bind:^RACSignalBindBlock _Nonnull{
        //block调用时刻：只要绑定信号订阅就会调用。不做什么事情
        return ^RACSignal *(id value,BOOL *stop){
            //一般在这个block中做事，发数据的时候会来到这个block
            //只要源信号(subject)发送数据，就会调用block
            //block作用：处理源信号内容
            //value：源信号发送的内容
            value = @3;//如果在这里把value的值改了，那么订阅绑定信号的值即44行的x就变了
            NSLog(@"接受到源信号的内容：%@",value);
            //返回信号，不能为nil，如果非要返回空——则empty或alloc init
            return [RACReturnSignal return:value];
        };
    }];
    
    //3.订阅绑定信号
    [bindSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"接收到绑定信号处理完的信号：%@",x);
    }];
    //4.发送信号
    [subject sendNext:@"123"];
}

#pragma mark - map
- (void)mapTest{
    //创建信号
    RACSubject *subject = [RACSubject subject];
    //绑定信号
    RACSignal *bindSignal = [subject map:^id _Nullable(id  _Nullable value) {
        //返回的类型就是你需要映射的值
        return [NSString stringWithFormat:@"ws:%@",value];//这里将源信号发送的“123”前面拼接了ws：
    }];
    //订阅绑定信号
    [bindSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    //发送信号
    [subject sendNext:@"123"];
}

#pragma mark - flatMap
- (void)flatMapTest{
    //创建信号
    RACSubject *subject = [RACSubject subject];
    //绑定信号
    RACSignal *bindSignal = [subject flattenMap:^__kindof RACSignal * _Nullable(id  _Nullable value) {
        //block:只要源信号发送内容就会调用
        //value:就是源信号发送的内容
        //返回信号用来包装成修改内容的值
        return [RACReturnSignal return:value];//将value包装成一个signal
    }];
    
    //flattenMap中返回的是什么信号，订阅的就是什么信号（那么，x的值等于value的值，如果我们操纵value的值那么x也会随之而变）
    //订阅信号
    [bindSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //发送数据
    [subject sendNext:@"123"];
}

- (void)flattemMapTest2{
    //flattenMap 主要用于信号中的信号
    //创建信号
    RACSubject *signalOfSignals = [RACSubject subject];
    RACSubject *signal = [RACSubject subject];
    
    /*
     //订阅信号
     //方式1
     [signalOfSignals subscribeNext:^(id  _Nullable x) {
     [x subscribeNext:^(id  _Nullable x) {
     NSLog(@"%@",x);
     }];
     }];
     
     //方式2
     [signalOfSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
     NSLog(@"%@",x);
     }];
     
     //方式3
     RACSignal *bindSignal = [signalOfSignals flattenMap:^__kindof RACSignal * _Nullable(id  _Nullable value) {
     //value:就是源信号发送的内容
     return value;
     }];
     [bindSignal subscribeNext:^(id  _Nullable x) {
     NSLog(@"%@",x);
     }];
     */
    
    //方式4：也是开发中常用的
    // flattenMap作用:把源信号的内容映射成一个新的信号，信号可以是任意类型。
    [[signalOfSignals flattenMap:^__kindof RACSignal * _Nullable(id  _Nullable value) {
        return value;
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@", x);
    }];
    
    //发送信号
    [signalOfSignals sendNext:signal];
    [signal sendNext:@"123"];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //    [self flattemMapTest2];
//    [self mapTest];
//    [self signalTest];
//    [self subjectTest];
//    [self racSequenceTest];
//    [self connectionTest];
    [self commandTest];
}

#pragma mark - RACSignal
//疑问：sigal是如何管理生命周期的！？
- (void)signalTest{
    //1.创建信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //3.发送信号
        [subscriber sendNext:@"ws"];
        //4.取消信号，如果信号想要被取消，就必须返回一个RACDisposable
        //信号什么时候被取消：1.自动取消，当一个信号的订阅者被销毁的时候就会自动取消订阅，2.手动取消
        //block什么时候调用：一旦一个信号被取消订阅就会调用
        //block作用：当信号被取消时用于清空一些资源
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"取消订阅");
        }];
    }];
    
    //2.订阅信号
    //subscribeNext
    //把nextBlock保存到订阅者里面
    //只要订阅信号就会返回一个取消订阅信号的类
    RACDisposable *disposable = [signal subscribeNext:^(id  _Nullable x) {
        //block的调用时刻：只要信号内部发出数据就会调用这个block
        NSLog(@"=====%@",x);
    }];
    //取消订阅
    [disposable dispose];
}

/*
 总结
 
 .核心：
 .核心：信号类
 .信号类的作用：只要有数据改变就会把数据包装成信号传递出去
 .只要有数据改变就会有信号发出
 .数据发出，并不是信号类发出，信号类不能发送数据
 .使用方法：
 .创建信号
 .订阅信号
 .实现思路：
 .当一个信号被订阅，创建订阅者，并把nextBlock保存到订阅者里面。
 .创建的时候会返回 [RACDynamicSignal createSignal:didSubscribe];
 .调用RACDynamicSignal的didSubscribe
 .发送信号[subscriber sendNext:value];
 .拿到订阅者的nextBlock调用
 */


/*
 https://www.ibm.com/developerworks/cn/linux/thread/posix_thread2/index.html
 pthread_mutex_unlock() 与 pthread_mutex_lock() 相配合，它把线程已经加锁的互斥对象解锁。
 */

#pragma mark - RACSubject
/*
 RACSubject
 
 RACSubject 在使用中我们可以完全代替代理，代码简介方法。具体代码请看demo中的RACSubject。
 
 总结
 
 我们完全可以用RACSubject代替代理/通知，确实方便许多 这里我们点击TwoViewController的pop的时候 将字符串"ws"传给了ViewController的button的title。
 */
- (void)subjectTest{
    //1.创建信号
    RACSubject *subject = [RACSubject subject];
    
    //2.订阅信号
    [subject subscribeNext:^(id  _Nullable x) {
        //block：当有数据发出的时候就会调用
        //block:处理数据
        NSLog(@"%@",x);
    }];
    
    //3.发送信号
    [subject sendNext:@2];
    
    /*
     注意 RACSubject和RACReplaySubject的区别 RACSubject必须要先订阅信号之后才能发送信号， 而RACReplaySubject可以先发送信号后订阅. RACSubject 代码中体现为：先走TwoViewController的sendNext，后走ViewController的subscribeNext订阅 RACReplaySubject 代码中体现为：先走ViewController的subscribeNext订阅，后走TwoViewController的sendNext 可按实际情况各取所需。
     */
}

#pragma mark - RACSequence
//使用场景：可以快速高效遍历数组和字典
- (void)racSequenceTest{
    /*
    NSString *path = [[NSBundle mainBundle] pathForResource:@"flags.plist" ofType:nil];
    NSArray *dictArr = [NSArray arrayWithContentsOfFile:path];
     */
    NSArray *dictArr = @[@{@"key":@1,@"key2":@2},@{@"key":@1,@"key2":@2}];
    [dictArr.rac_sequence.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"=====error======");
    } completed:^{
        NSLog(@"-----完毕");
    }];
}

#pragma mark - RACMulticastConnection
//当有多个订阅者，但是我们只想发送一个信号的时候怎么办？这时我们就可以用RACMulticastConnection，来实现。
- (void)connectionTest{
    //比较好的做法。使用RACMulticastConnection，无论有多少个订阅者，无论订阅多少次，我只发送一个。
    //1.发送请求，用一个信号包装，不管有多少个订阅者，只想发一次请求
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //发送信号
        [subscriber sendNext:@"ws"];
        return nil;
    }];
    
    //2.创建连接类
    RACMulticastConnection *connection = [signal publish];
    [connection.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    [connection.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    [connection.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //3.连接，只有连接了才会把信号源变为热信号
    [connection connect];
}

#pragma mark - RACCommand
/*
 RACCommand:RAC中用于处理事件的类，可以把事件如何处理，事件中的数据如何传递，包装到这个类中，他可以很方便的监控事件的执行过程，比如看事件有没有执行完毕
 使用场景：监听按钮点击，网络请求
 */
/*
 https://halfrost.com/reactivecocoa_raccommand/  RACCommand底层分析
 */
- (void)commandTest{
    //普通做法
    //RACCommand：处理事件
    //不能返回空的信号
    //1.创建命令
    /*
     RACCommand最常见的例子就是在注册登录的时候，点击获取验证码的按钮，这个按钮的点击事件和触发条件就可以用RACCommand来封装，触发条件是一个信号，它可以是验证手机号，验证邮箱，验证身份证等一些验证条件产生的enabledSignal。触发事件就是按钮点击之后执行的事件，可以是发送验证码的网络请求。
     */
    /*
     RACCommand在ReactiveCocoa中算是很特别的一种存在，因为它的实现并不是FRP实现的，是OOP实现的。RACCommand的本质就是一个对象，在这个对象里面封装了4个信号。
     */
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        //block调用，执行命令的时候就会调用
        NSLog(@"%@",input);//input 为执行命令传进来的参数
        //这里的返回值不允许为nil
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            [subscriber sendNext:@"执行命令产生的数据"];
            return nil;
        }];
    }];
    
    //如何拿到执行命令中产生的数据呢？
    //订阅命令内部的信号
    //** 方式一：直接订阅执行命令返回的信号
    
    //2.执行命令
    RACSignal *signal = [command execute:@2];//这里其实用到的是replaySubject 可以先发送命令再订阅
    //在这里就可以订阅信号了
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    
    /*
    - (void)removeActiveExecutionSignal:(RACSignal *)signal {
        NSCParameterAssert([signal isKindOfClass:RACSignal.class]);
        
        @synchronized (self) {
            NSIndexSet *indexes = [_activeExecutionSignals indexesOfObjectsPassingTest:^ BOOL (RACSignal *obj, NSUInteger index, BOOL *stop) {
                return obj == signal;
            }];
            
            if (indexes.count == 0) return;
            
            [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@keypath(self.activeExecutionSignals)];
            [_activeExecutionSignals removeObjectsAtIndexes:indexes];
            [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@keypath(self.activeExecutionSignals)];
        }
    }
     */
    
    //从上面增加和删除的操作中我们可以看见了RAC的作者在手动发送change notification，手动调用willChange: 和 didChange:方法。作者的目的在于防止一些不必要的swizzling可能会影响到增加和删除的操作，所以这里选择的手动发送通知的方式。
}

- (void)commandTest2{
    //一般做法
    //1.创建命令
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        //block调用，执行命令的时候就会调用
        NSLog(@"%@",input); // input 为执行命令传进来的参数
        // 这里的返回值不允许为nil
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            [subscriber sendNext:@"执行命令产生的数据"];
            return nil;
        }];
    }];
    
    //方式二：
    //订阅信号
    //注意：这里必须是先订阅才能发送命令
    // executionSignals：信号源，信号中信号，signalofsignals:信号，发送数据就是信号
    [command.executionSignals subscribeNext:^(RACSignal  *_Nullable x) {
        [x subscribeNext:^(id  _Nullable x) {
            NSLog(@"%@",x);
        }];
    }];
    
    //2.执行命令
    [command execute:@2];
}

- (void)commandTest3{
    //高级做法
    //1.创建命令
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        // block调用：执行命令的时候就会调用
        NSLog(@"%@", input);
        // 这里的返回值不允许为nil
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            [subscriber sendNext:@"发送信号"];
            return nil;
        }];
    }];
    
    //方式三
    // switchToLatest获取最新发送的信号，只能用于信号中信号。
    [command.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //2.执行命令
    [command execute:@3];
}

- (void)switchToLatestTest{
    //switchToLatest——用于信号中的信号
    //创建信号中的信号
    RACSubject *signalOfSignals = [RACSubject subject];
    RACSubject *signalA = [RACSubject subject];
    //订阅信号
    [signalOfSignals subscribeNext:^(RACSignal  *_Nullable x) {
        [x subscribeNext:^(id  _Nullable x) {
            NSLog(@"%@",x);
        }];
    }];
    
    
    //switchToLatest:获取信号中信号发送的最新信号
    [signalOfSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //发送信号
    [signalOfSignals sendNext:signalA];
    [signalA sendNext:@4];
}

- (void)commandTest5{
    //监听事件有没有完成
    //注意：当前命令内部发送数据完成，一定要主动发送完成
    //1.创建命令
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        // block调用：执行命令的时候就会调用
        NSLog(@"%@", input);
        // 这里的返回值不允许为nil
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            //发送数据
            [subscriber sendNext:@"执行命令产生的数据"];
            //***发送完成****
            [subscriber sendCompleted];
            return nil;
        }];
    }];
    
    //监听事件有没有完成
    [command.executing subscribeNext:^(NSNumber * _Nullable x) {
        if ([x boolValue] == YES) {//正在执行
            NSLog(@"当前正在执行%@",x);
        }else{
            //执行完成/没有执行
            NSLog(@"执行完成/没有执行");
        }
    }];
    
    //执行命令
    [command execute:@1];
}

#pragma mark - macro
- (void)macroTest{
    
    //RAC：把一个对象的某个属性绑定一个信号，只要发出信号，就会把信号的内容给对象的属性赋值
    // 给label的text属性绑定了文本框改变的信号
    RAC(self.lable,text) = self.textField.rac_textSignal;
    
    //相当于：
    //    [self.textField.rac_textSignal subscribeNext:^(id x) {
    //        self.label.text = x;
    //    }];
    
    /**
     *  KVO
     *  RACObserveL:快速的监听某个对象的某个属性改变
     *  返回的是一个信号,对象的某个属性改变的信号
     */
    [RACObserve(self.view, center) subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //例 textField输入的值赋值给label，监听label文字改变,
    RAC(self.lable, text) = self.textField.rac_textSignal;
    [RACObserve(self.lable, text) subscribeNext:^(id x) {
        NSLog(@"====label的文字变了");
    }];
    
    /**
     *  循环引用问题
     *  使用 @weakify(self)和@strongify(self)来避免循环引用
     */
    @weakify(self)
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self)
        NSLog(@"%@",self.view);
        return nil;
    }];
    _signal = signal;
    
    /**
     * 元祖
     * 快速包装一个元组
     * 把包装的类型放在宏的参数里面,就会自动包装
     */
    RACTuple *tuple = RACTuplePack(@1,@2,@4);
    // 宏的参数类型要和元祖中元素类型一致， 右边为要解析的元祖。
    RACTupleUnpack(NSNumber *num1,NSNumber *num2,NSNumber *num3) = tuple;//4.元组
    NSLog(@"%@ %@ %@", num1, num2, num3);
}

#pragma mark - RAC-过滤
- (void)filterTest{
    //跳跃：如下，skip传入2 跳过前面两个值
    //实际用处：在实际开发中比如后台返回的数据前面几个没用，我们想跳跃过去，便可以用skip
    RACSubject *subject = [RACSubject subject];
    [[subject skip:2] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@", x);
    }];
    [subject sendNext:@1];
    [subject sendNext:@2];
    [subject sendNext:@3];
    
    //distinctUntilChanged:-- 如果当前的值跟上一次的值一样，就不会被订阅到
    [[subject distinctUntilChanged] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@", x);
    }];
    // 发送信号
    [subject sendNext:@1];
    [subject sendNext:@2];
    [subject sendNext:@2]; // 不会被订阅
    
    //take：可以屏蔽一些值，去掉前面几个值——这里take为2，则只拿到前面两个值
    RACSubject *subject3 = [RACSubject subject];
    [[subject3 take:2] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    // 发送信号
    [subject3 sendNext:@1];
    [subject3 sendNext:@2];
    [subject3 sendNext:@3];
    [subject3 sendCompleted];
    
    // 一般和文本框一起用，添加过滤条件
    // 只有当文本框的内容长度大于5，才获取文本框里的内容
    [[self.textField.rac_textSignal filter:^BOOL(id value) {
        // value 源信号的内容
        return [value length] > 5;
        // 返回值 就是过滤条件。只有满足这个条件才能获取到内容
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

- (void)takeUntilTest{
    //takeUntil:——给takeUntil传的是哪个信号，那么当这个信号发送信号或sendCompleted,就不能再接受源信号的内容了。
    RACSubject *subject = [RACSubject subject];
    RACSubject *subject2 = [RACSubject subject];
    [[subject takeUntil:subject2] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    //发送信号
    [subject sendNext:@1];
    [subject sendNext:@2];
    [subject2 sendNext:@3];  // 1
    //    [subject2 sendCompleted]; // 或2
    [subject sendNext:@4];
}

- (void)ignoreTest {
    // ignore: 忽略掉一些值
    //ignore:忽略一些值
    //ignoreValues:表示忽略所有的值
    //1.创建信号
    RACSubject *subject = [RACSubject subject];
    //2.忽略一些值
    RACSignal *ignoreSignal = [subject ignore:@2];//ignoreValues:表示忽略所有的值
    //3.订阅信号
    [ignoreSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    //4.发送数据
    [subject sendNext:@2];
}

#pragma mark - RAC-组合
//把多个信号聚合成你想要的信号，使用场景：比如，当多个输入框都有值的时候按钮才可点击
- (void)combineTest{
    //思路：就是把输入框输入值的信号都聚合成按钮是否能点击的信号
    RACSignal *combineSignal = [RACSignal combineLatest:@[self.accountField.rac_textSignal,self.pwdField.rac_textSignal] reduce:^id (NSString *account,NSString *pwd){
        // block: 只要源信号发送内容，就会调用，组合成一个新值。
        NSLog(@"%@ %@", account, pwd);
        return @(account.length && pwd.length);
    }];
    
    //    // 订阅信号
    //    [combinSignal subscribeNext:^(id x) {
    //        self.loginBtn.enabled = [x boolValue];
    //    }];    // ----这样写有些麻烦，可以直接用RAC宏
    RAC(self.loginBtn,enabled) = combineSignal;
}

- (void)zipWith {
    //zipWith:把两个信号压缩成一个信号，只有当两个信号同时发出信号内容时，并且把两个信号的内容合并成一个元组，才会触发压缩流的next事件
    //创建信号A
    RACSubject *signalA = [RACSubject subject];
    RACSubject *signalB = [RACSubject subject];
    //压缩成一个信号
    // **-zipWith-**: 当一个界面多个请求的时候，要等所有请求完成才更新UI
    // 等所有信号都发送内容的时候才会调用
    RACSignal *zipSignal = [signalA zipWith:signalB];
    [zipSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);//所有的值都被包装成了元组
    }];
    // 发送信号 交互顺序，元组内元素的顺序不会变，跟发送的顺序无关，而是跟压缩的顺序有关[signalA zipWith:signalB]---先是A后是B
    [signalA sendNext:@1];
    [signalB sendNext:@2];
}

- (void)mergeTest {
    // 任何一个信号请求完成都会被订阅到
    // merge:多个信号合并成一个信号，任何一个信号有新值就会调用
    //创建信号
    RACSubject *signalA = [RACSubject subject];
    RACSubject *signalB = [RACSubject subject];
    //组合信号
    RACSignal *mergeSignal = [signalA merge:signalB];
    //订阅信号
    [mergeSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    // 发送信号---交换位置则数据结果顺序也会交换
    [signalB sendNext:@"下部分"];
    [signalA sendNext:@"上部分"];
}

//then——使用需求：有两部分数据：想让上部分先进行网络请求但是过滤掉数据，然后进行下部分的，拿到下部分数据
- (void)thenTest {
    //创建信号A
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //发送请求
        NSLog(@"——发送上部分请求——afn");
        [subscriber sendNext:@"上部分数据"];
        [subscriber sendCompleted]; // 必须要调用sendCompleted方法！
        return nil;
    }];
    
    //创建信号B
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 发送请求
        NSLog(@"--发送下部分请求--afn");
        [subscriber sendNext:@"下部分数据"];
        return nil;
    }];
    
    //创建组合信号
    //then：忽略掉第一个信号的所有值
    RACSignal *thenSignal = [signalA then:^RACSignal * _Nonnull{
        return signalB;// 返回的信号就是要组合的信号
    }];
    
    //订阅信号
    [thenSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}

// concat----- 使用需求：有两部分数据：想让上部分先执行，完了之后再让下部分执行（都可获取值）
- (void)concatTest {
    //组合
    // 创建信号A
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // 发送请求
        //        NSLog(@"----发送上部分请求---afn");
        
        [subscriber sendNext:@"上部分数据"];
        [subscriber sendCompleted]; // 必须要调用sendCompleted方法！
        return nil;
    }];
    
    // 创建信号B，
    RACSignal *signalsB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // 发送请求
        //        NSLog(@"--发送下部分请求--afn");
        [subscriber sendNext:@"下部分数据"];
        return nil;
    }];
    
    //concat:按顺序去链接
    //**-注意-**：concat，第一个信号必须要调用sendCompleted
    //创建组合信号
    RACSignal *concatSignal = [signalA concat:signalsB];
    //订阅组合信号
    [concatSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}




@end
