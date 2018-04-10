//
//  DLButtonHandleViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 10/04/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  https://www.jianshu.com/p/672c0d4f435a

#import "DLButtonHandleViewController.h"

@interface DLButtonHandleViewController ()
@property(nonatomic, strong) UIButton *button;
@end

@implementation DLButtonHandleViewController

- (UIButton *)button{
    if (!_button) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return _button;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


#pragma mark - 防止按钮多次点击
//方式一：使用cancelPreviousPerformRequestsWithTarget
- (void)completeClicked:(UIButton *)sender{
    //这种方式是在0.2秒内取消之前的点击事件，以做到防止多次点击。
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(buttonClick:) object:sender];
    [self performSelector:@selector(buttonClick:) withObject:sender afterDelay:0.2f];
}
- (void)buttonClick:(id)sender{
    
}

//方式二：在点击后设为不可被点击的状态，1秒后恢复
- (void)buttonClicked2:(id)sender{
    self.button.enabled = NO;
    [self performSelector:@selector(changeButtonStatus) withObject:nil afterDelay:1.0f];//防止重复点击
}

- (void)changeButtonStatus{
    self.button.enabled = YES;
}

//方式三：RAC command
- (void)settingButton{
    //使用RACCommand绑定button
//    self.button.rac_command = XXX
}

//方式四：Runtime（方法交换） http://www.cocoachina.com/ios/20150911/13260.html


/*
在子线程中无法调用selector方法

在子线程中无法调用selector方法这种情况是只有使用以下方法的时候才出现:

- (void)performSelector:(SEL)aSelector withObject:(id)arg afterDelay:(NSTimeInterval)delay;

这是为什么呢？原因如下：

1、afterDelay方式是使用当前线程的Run Loop中根据afterDelay参数创建一个Timer定时器在一定时间后调用SEL，NO AfterDelay方式是直接调用SEL。

2、子线程中默认是没有runloop的，需要手动创建，只要调用获取当前线程RunLoop方法即可创建。

所以解决方法有两种：
 */

//1.创建子线程的runloop
- (void)afterDelayTest{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self performSelector:@selector(delayMethod) withObject:nil afterDelay:0];
        [[NSRunLoop currentRunLoop] run];
        NSLog(@"调用方法＝＝开始");
        sleep(5);
        NSLog(@"调用方法＝＝结束");
    });
}



//2.使用dispatch_after在子线程上执行
- (void)afterDelayTest2{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
        if ([self respondsToSelector:@selector(delayMethod)]) {
            [self performSelector:@selector(delayMethod) withObject:nil];
        }
    });
    
    NSLog(@"调用方法＝＝开始");
    sleep(5);
    NSLog(@"调用方法＝＝结束");
}

- (void)delayMethod{
    NSLog(@"delayMethod");
}




@end
