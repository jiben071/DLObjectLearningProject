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

@end

@implementation DLRACLearningByMyselfViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //    [self flattemMapTest2];
//    [self mapTest];
    [self signalTest];
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
    [self signalTest];
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


@end
