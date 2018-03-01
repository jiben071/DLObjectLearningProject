//
//  DLRacBasicCourse.m
//  DLObjectLearningProject
//
//  Created by denglong on 28/02/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  参考链接：http://bbs.520it.com/forum.php?mod=viewthread&tid=257

#import "DLRacBasicCourse.h"
#import <UIKit/UIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <ReactiveObjC/RACReturnSignal.h>

@interface DLRacBasicCourse()
@property(nonatomic, strong) UITextField *textField;
@end

@implementation DLRacBasicCourse
/*
 1.ReactiveCocoa常见操作方法介绍
 
 1.1 ReactiveCocoa操作须知
 所有的信号（RACSignal）都可以进行操作处理，因为所有操作方法都定义在RACStream.h中，因此只要继承RACStream就有了操作处理方法。
 
 1.2 ReactiveCocoa操作思想
 运用的是Hook（钩子）思想，Hook是一种用于改变API(应用程序编程接口：方法)执行结果的技术.
 Hook用处：截获API调用的技术。
 Hook原理：在每次调用一个API返回结果之前，先执行你自己的方法，改变结果的输出。
 
 1.3 ReactiveCocoa核心方法bind
 ReactiveCocoa操作的核心方法是bind（绑定）,而且RAC中核心开发方式，也是绑定，之前的开发方式是赋值，而用RAC开发，应该把重心放在绑定，也就是可以在创建一个对象的时候，就绑定好以后想要做的事情，而不是等赋值之后在去做事情。
 列如：把数据展示到控件上，之前都是重写控件的setModel方法，用RAC就可以在一开始创建控件的时候，就绑定好数据。
 在开发中很少使用bind方法，bind属于RAC中的底层方法，RAC已经封装了很多好用的其他方法，底层都是调用bind，用法比bind简单.

 */

//bind方法简单介绍和使用。
- (void)testBind{
    // 假设想监听文本框的内容，并且在每次输出结果的时候，都在文本框的内容拼接一段文字“输出：”
    // 方式一:在返回结果后，拼接。
    [_textField.rac_textSignal subscribeNext:^(NSString * _Nullable x) {
        NSLog(@"输出:%@",x);
    }];
    
    // 方式二:在返回结果前，拼接，使用RAC中bind方法做处理。
    // bind方法参数:需要传入一个返回值是RACStreamBindBlock的block参数
    // RACStreamBindBlock是一个block的类型，返回值是信号，参数（value,stop），因此参数的block返回值也是一个block。
    // RACStreamBindBlock:
    // 参数一(value):表示接收到信号的原始值，还没做处理
    // 参数二(*stop):用来控制绑定Block，如果*stop = yes,那么就会结束绑定。
    // 返回值：信号，做好处理，在通过这个信号返回出去，一般使用RACReturnSignal,需要手动导入头文件RACReturnSignal.h。
    // bind方法使用步骤:
    // 1.传入一个返回值RACStreamBindBlock的block。
    // 2.描述一个RACStreamBindBlock类型的bindBlock作为block的返回值。
    // 3.描述一个返回结果的信号，作为bindBlock的返回值。
    // 注意：在bindBlock中做信号结果的处理。
    // 底层实现:
    // 1.源信号调用bind,会重新创建一个绑定信号。
    // 2.当绑定信号被订阅，就会调用绑定信号中的didSubscribe，生成一个bindingBlock。
    // 3.当源信号有内容发出，就会把内容传递到bindingBlock处理，调用bindingBlock(value,stop)
    // 4.调用bindingBlock(value,stop)，会返回一个内容处理完成的信号（RACReturnSignal）。
    // 5.订阅RACReturnSignal，就会拿到绑定信号的订阅者，把处理完成的信号内容发送出来。
    // 注意:不同订阅者，保存不同的nextBlock，看源码的时候，一定要看清楚订阅者是哪个。
    // 这里需要手动导入#import <ReactiveCocoa/RACReturnSignal.h>，才能使用RACReturnSignal。
    
    //总是报错  没有解决报错问题
//    [[_textField.rac_textSignal bind:^RACSignalBindBlock _Nonnull{
//        //什么时候调用
//        //block作用：表示绑定了一个信号
//        return ^RACStream *(id value,BOOL *stop){
//            //什么时候调用block：当信号有新的值发出，就会来到这个block。
//            //block作用：做返回值的处理
//            //做好处理，通过信号返回出去
//            return [RACReturnSignal return:[NSString stringWithFormat:@"输出:%@",value]];
//        };
//    }] subscribeNext:^(id  _Nullable x) {
//        NSLog(@"%@",x);
//    }];


    
}

- (void)mapTest{
    // 监听文本框的内容改变，把结构重新映射成一个新值.
    // Map作用:把源信号的值映射成一个新的值
    // Map使用步骤:
    // 1.传入一个block,类型是返回对象，参数是value
    // 2.value就是源信号的内容，直接拿到源信号的内容做处理
    // 3.把处理好的内容，直接返回就好了，不用包装成信号，返回的值，就是映射的值。
    // Map底层实现:
    // 0.Map底层其实是调用flatternMap,Map中block中的返回的值会作为flatternMap中block中的值。
    // 1.当订阅绑定信号，就会生成bindBlock。
    // 3.当源信号发送内容，就会调用bindBlock(value, *stop)
    // 4.调用bindBlock，内部就会调用flattenMap的block
    // 5.flattenMap的block内部会调用Map中的block，把Map中的block返回的内容包装成返回的信号。
    // 5.返回的信号最终会作为bindBlock中的返回信号，当做bindBlock的返回信号。
    // 6.订阅bindBlock的返回信号，就会拿到绑定信号的订阅者，把处理完成的信号内容发送出来。
    [[_textField.rac_textSignal map:^id _Nullable(NSString * _Nullable value) {
        //当源信号发出，就会调用这个block，修改源信号的内容
        //返回值：就是处理完信号的内容
        return [NSString stringWithFormat:@"输出:%@",value];
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}

/*
 FlatternMap和Map的区别
 1.FlatternMap中的Block返回信号。
 2.Map中的Block返回对象。
 3.开发中，如果信号发出的值不是信号，映射一般使用Map
 4.开发中，如果信号发出的值是信号，映射一般使用FlatternMap。
 总结：signalOfsignals用FlatternMap。
 */
- (void)flattenMapTest{
    //创建信号中的信号
    RACSubject *signalOfSignals = [RACSubject subject];
    RACSubject *signal = [RACSubject subject];
    
    [[signalOfSignals flattenMap:^__kindof RACSignal * _Nullable(id  _Nullable value) {
        //当signalOfSignals的signals发出信号才会调用
        return value;
    }] subscribeNext:^(id  _Nullable x) {
        //只有signalOfSignals的signal发出信号才会调用，因为内部订阅了bindBlock中返回的信号，也就是flattenMap返回的信号
        //也就是flattenMap返回的信号发出内容，才会调用
        NSLog(@"%@aaa",x);
    }];
    
    //信号的信号发送信号
    [signalOfSignals sendNext:signal];
    //信号发送内容
    [signal sendNext:@1];
}

// ReactiveCocoa操作方法之组合。
// concat:按一定顺序拼接信号，当多个信号发出的时候，有顺序的接收信号。
- (void)concatTest{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendCompleted];
        return nil;
    }];
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@2];
        return nil;
    }];
    
    //把signalA拼接到signalB后，signalA发送完成，signalB才会被激活
    RACSignal *concatSignal = [signalA concat:signalB];
    //以后只需要面对拼接信号开发
    //订阅拼接的信号，不需要单独订阅signalA,signalB
    //内部会自动订阅
    //注意：第一个信号必须发送完成，第二个信号才会被激活
    [concatSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //concat底层实现
    //1.当拼接信号被订阅，就会调用拼接信号的didSubscribe
    //2.didSubscribe中，会先订阅第一个源信号(signalA)
    //3.会执行第一个源信号(signalA)的didSubscribe
    //4.第一个原信号(signalA)didSubscribe中发送值，就会调用第一个源信号(signalA)订阅者的nextBlock，通过拼接信号的订阅者把值发出来
    // 5.第一个源信号（signalA）didSubscribe中发送完成，就会调用第一个源信号（signalA）订阅者的completedBlock,订阅第二个源信号（signalB）这时候才激活（signalB）。
    // 6.订阅第二个源信号（signalB）,执行第二个源信号（signalB）的didSubscribe
    // 7.第二个源信号（signalA）didSubscribe中发送值,就会通过拼接信号的订阅者把值发送出来.
}

//then:用于连接两个信号，当第一个信号完成，才会连接then返回的信号
- (void)thenTest{
    //注意使用then，之前信号的值会被忽略掉
    //底层实现：1.先过滤之前的信号发出的值 2.使用concat连接then返回的信号
    [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendCompleted];
        return nil;
    }] then:^RACSignal * _Nonnull{
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            [subscriber sendNext:@2];
            return nil;
        }];
    }] subscribeNext:^(id  _Nullable x) {
        //只能接受到第二个信号的值，也就是then返回信号的值
        NSLog(@"%@",x);
    }];
}

//merge:把多个信号合并为一个信号，任何一个信号有新值的时候就会调用
- (void)mergeTest{
    //创建多个信号
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@1];
        return nil;
    }];
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@2];
        return nil;
    }];
    
    //合并信号，任何一个信号发送数据，都能监听到
    RACSignal *mergeSignal = [signalA merge:signalB];
    [mergeSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //底层实现：
    //1.合并信号被订阅的时候，就会遍历所有信号，并且发出这些信号。
    //2.每发出一个信号，这个信号就被订阅
    //3.也就是合并信号一被订阅，就会订阅里面所有的信号
    //4.只要有一个信号被发出就会被监听
    
}

//zipWith:把两个信号压缩成一个信号，只有当两个信号同时发出信号内容时，并且把两个信号的内容合并成一个元组，才会触发压缩流的next事件。
- (void)zipWithTest{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@1];
        return nil;
    }];
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@2];
        return nil;
    }];
    //压缩信号A，信号B
    RACSignal *zipSignal = [signalA zipWith:signalB];
    [zipSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //底层实现
    //1.定义压缩信号，内部就会自动订阅signalA，signalB
    //2.每当signalA或者signalB发出信号，就会判断signalA，signalB有没有发出这个信号，有就会把最近发出的信号包装成元组发出。
}

//conbineLatest：将多个信号合并起来，并且拿到各个信号的最新的值，必须每个合并的signal至少都有过一次sendNext，才会触发合并的信号。
- (void)conbineLatestTest{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@1];
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@2];
        return nil;
    }];
    //把两个信号组合成一个信号，跟zip一样，没什么区别
    RACSignal *combineSignal = [signalA combineLatestWith:signalB];
    [combineSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    //底层实现：
    //1.当组合信号被订阅，内部就会自动订阅singalA，signalB，必须两个信号都发出内容，才会被触发。
    //2.并且把连个信号组成成元组发出
}

//reduce聚合：用于信号发出的内容是元组，把信号发出元组的值聚合成一个值
- (void)reduceTest{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@1];
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@2];
        return nil;
    }];
    
    //聚合
    //常见的用法，先组合再聚合  combineLatest:reduce
    //reduce中的block简介：
    //reduceblock中的参数，有多少信号，reduceblock就有多少参数，每个参数就是之前信号发出的内容
    //reduceblock的返回值：聚合信号之后的内容
    RACSignal *reduceSignal = [RACSignal combineLatest:@[signalA,signalB] reduce:^id (NSNumber *num1,NSNumber *num2){
        return [NSString stringWithFormat:@"%@ %@",num1,num2];
    }];
    [reduceSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //底层实现：
    //1.订阅聚合信号，每次有内容发出，就会执行reduceblock，把信号内容转换成reduceblock返回的值
}

//1.6 reactiveCocoa操作方法之过滤
//filter:过滤信号，使用它可以获取满足条件的信号
//过滤：
//每次信号发出，会先执行过滤条件判断
- (void)filterTest{
    [[self.textField.rac_textSignal filter:^BOOL(NSString * _Nullable value) {
        return value.length > 3;
    }] subscribeNext:^(NSString * _Nullable x) {
        NSLog(@"%@",x);
    }];
}

//ignore:忽略完某些值的信号
- (void)ignoreTest{
    //内部调用filter过滤，忽略掉ignore的值
    [[_textField.rac_textSignal ignore:@"1"] subscribeNext:^(NSString * _Nullable x) {
        NSLog(@"%@",x);
    }];
}

//distinctUntilChanged:当上一次的值和当前的值有明显的变化就会发出信号，否则会被忽略掉
- (void)distinctUntilChangedTest{
    //过滤，当上一次和当前的值不一样，就会发出内容
    //在开发中，刷新UI经常使用，只有两次数据不一样才需要刷新
    [[_textField.rac_textSignal distinctUntilChanged] subscribeNext:^(NSString * _Nullable x) {
        NSLog(@"%@",x);
    }];
}

//take:从开始一共取N次的信号
- (void)takeTest{
    //1.创建信号
    RACSubject *signal = [RACSubject subject];
    //2.处理信号，订阅信号
    [[signal take:1] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    //3.发送信号
    [signal sendNext:@1];
    [signal sendNext:@2];
}

//tackLast：取最后N次的信号，前提条件，订阅者必须调用完成，因为只有完成，就知道总共有多少信号
- (void)takeLastTest{
    //1.创建信号
    RACSubject *signal = [RACSubject subject];
    //2.处理信号，订阅信号
    [[signal takeLast:1] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    //3.发送信号
    [signal sendNext:@1];
    [signal sendNext:@2];
    [signal sendCompleted];
}

//takeUntil:(RACSignal *)：获取信号直到某个信号执行完成
- (void)takeUntil{
    //监听文本框的改变直到当前对象被销毁
    [_textField.rac_textSignal takeUntil:self.rac_willDeallocSignal];
}

//skip:(NSUInteger:)跳过几个信号，不接受
- (void)skipTest{
    //表示输入第一次，不会被监听到，跳过第一次发出的信号
    [[_textField.rac_textSignal skip:1] subscribeNext:^(NSString * _Nullable x) {
        NSLog(@"%@",x);
    }];
}
//switchToLast：用于signalOfSignals（信号的信号），有时候信号也会发出信号，会在signalOfSignals中，获取signalOfSignals发送的最新信号
- (void)switchToLastTest{
    RACSubject *signalOfSignals = [RACSubject subject];
    RACSubject *signal = [RACSubject subject];
    //获取信号中信号最近发出信号，订阅最近发出的信号
    //注意switchToLatest：只能用于信号中的信号
    [signalOfSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    [signalOfSignals sendNext:signal];
    [signal sendNext:@1];
}

//1.7 ReactiveCocoa操作方法之秩序
//doNext:执行Next之前，会先执行这个Block
//doCompleted:执行sendCompleted之前，会先执行这个Block

//1.8 ReactiveCocoa操作方法之线程
//deliverOn:内容传递切换到指定线程中，副作用在原来线程中，把在创建信号的block中的代码称之为副作用。
//subscribeOn:内容传递和副作用都会切换到指定线程中

//1.9 ReactiveCocoa操作方法之时间
//timeout:超时，可以让一个信号在一定的时间后，自动报错
- (void)timeOutTest{
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        return nil;
    }] timeout:1 onScheduler:[RACScheduler currentScheduler]];
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    } error:^(NSError * _Nullable error) {
        //1秒后会自动调用
        NSLog(@"%@",error);
    }];
}

//interfal:定时：每隔一段时间发出信号
- (void)intervalTest{
    [[RACSignal interval:1 onScheduler:[RACScheduler currentScheduler]] subscribeNext:^(NSDate * _Nullable x) {
        NSLog(@"%@",x);
    }];
}

//delay延迟发送next
- (void)delayTest{
    RACSignal *signal = [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@1];
        return nil;
    }] delay:2] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}

//1.10 ReactiveCocoa操作方法之重复
//retry重试：只要失败，就会重新执行创建信号中的block，直到成功。
- (void)retryTest{
    __block int i = 0;
    [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        if (i == 10) {
            [subscriber sendNext:@1];
        }else{
            NSLog(@"接收到错误");
            [subscriber sendError:nil];
        }
        i++;
        return nil;
    }] retry] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    } error:^(NSError * _Nullable error) {
        
    }];
}

//replay重放：当一个信号被多次订阅，反复播放内容
- (void)replayTest{
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        return nil;
    }] replay];
    
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"第一个订阅者%@",x);
    }];
    
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"第二个订阅者%@",x);
    }];
}

//throttle节流：当某个信号发送比较频繁时，可以使用节流，在某一段时间不发送信号内容，过了一段时间获取信号的最新内容发出
- (void)throttleTest{
    RACSubject *signal = [RACSubject subject];
    //节流，在一定时间（1秒）内，不接收任何信号内容，过了这个时间（1秒）获取最后发送的信号内容发出。
    [[signal throttle:1] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}


@end
