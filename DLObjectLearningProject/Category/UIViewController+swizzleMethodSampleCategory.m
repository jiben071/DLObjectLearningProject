//
//  UIViewController+swizzleMethodSampleCategory.m
//  DLObjectLearningProject
//
//  Created by denglong on 10/04/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  http://nshipster.cn/method-swizzling/
//  使用运行时实现方法交换，并且进行日志追踪

#import "UIViewController+swizzleMethodSampleCategory.h"
#import <objc/runtime.h>

@implementation UIViewController (swizzleMethodSampleCategory)

/*
 Method swizzling 用于改变一个已经存在的 selector 的实现。这项技术使得在运行时通过改变 selector 在类的消息分发列表中的映射从而改变方法的掉用成为可能。
 
 计算机科学里，交换指针指向用来交换基于名字或者位置的指针引用。如果你对 Objective-C 这方面的特性不是很了解的话，这是很值得推荐使用的一个特性，因为 method swizzling 可以通过交换 selector 来改变函数指针的引用。
 
 记住：方法交换的本质——method swizzling 可以通过交换 selector 来改变函数指针的引用
 
 
 */


/*
 swizzling应该只在+load中完成。 在 Objective-C 的运行时中，每个类有两个方法都会自动调用。+load 是在一个类被初始装载时调用，+initialize 是在应用第一次调用该类的类方法或实例方法前调用的。两个方法都是可选的，并且只有在方法被实现的情况下才会被调用。
 */
+ (void)load {
    static dispatch_once_t onceToken;
    //** swizzling 应该只在 dispatch_once 中完成**
    /*
     由于 swizzling 改变了全局的状态，所以我们需要确保每个预防措施在运行时都是可用的。原子操作就是这样一个用于确保代码只会被执行一次的预防措施，就算是在不同的线程中也能确保代码只执行一次。Grand Central Dispatch 的 dispatch_once 满足了所需要的需求，并且应该被当做使用 swizzling 的初始化单例方法的标准。
     */
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        //这里是交换实例方法
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(xxx_viewWillAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        // When swizzling a class method, use the following:  交换类方法
        // Class class = object_getClass((id)self);
        // ...
        // Method originalMethod = class_getClassMethod(class, originalSelector);
        // Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

#pragma mark - Method Swizzling
//记住给需要转换的所有方法加个前缀以区别原生方法。
- (void)xxx_viewWillAppear:(BOOL)animated {
    /*
     在交换方法实现后记得要调用原生方法的实现（除非你非常确定可以不用调用原生方法的实现）：APIs 提供了输入输出的规则，而在输入输出中间的方法实现就是一个看不见的黑盒。交换了方法实现并且一些回调方法不会调用原生方法的实现这可能会造成底层实现的崩溃。
     */
    [self xxx_viewWillAppear:animated];//在交换了方法的实现后，xxx_viewWillAppear:方法的实现已经被替换为了 UIViewController -viewWillAppear：的原生实现，所以这里并不是在递归调用。
    NSLog(@"viewWillAppear: %@", self);
}

/*
 Selectors, Methods, & Implementations
 
 在 Objective-C 的运行时中，selectors, methods, implementations 指代了不同概念，然而我们通常会说在消息发送过程中，这三个概念是可以相互转换的。 下面是苹果 Objective-C Runtime Reference中的描述：
 
 Selector（typedef struct objc_selector *SEL）:在运行时 Selectors 用来代表一个方法的名字。Selector 是一个在运行时被注册（或映射）的C类型字符串。Selector由编译器产生并且在当类被加载进内存时由运行时自动进行名字和实现的映射。
 
 Method（typedef struct objc_method *Method）:方法是一个不透明的用来代表一个方法的定义的类型。
 
 Implementation（typedef id (*IMP)(id, SEL,...)）:这个数据类型指向一个方法的实现的最开始的地方。该方法为当前CPU架构使用标准的C方法调用来实现。该方法的第一个参数指向调用方法的自身（即内存中类的实例对象，若是调用类方法，该指针则是指向元类对象metaclass）。第二个参数是这个方法的名字selector，该方法的真正参数紧随其后。
 
 理解 selector, method, implementation 这三个概念之间关系的最好方式是：
 
 在运行时，类（Class）维护了一个消息分发列表来解决消息的正确发送。每一个消息列表的入口是一个方法（Method），这个方法映射了一对键值对，其中键值是这个方法的名字 selector（SEL），值是指向这个方法实现的函数指针 implementation（IMP）。
 
 Method swizzling 修改了类的消息分发列表使得已经存在的 selector 映射了另一个实现 implementation，同时重命名了原生方法的实现为一个新的 selector。
 */

/*
 然而采取了以下预防措施后, method swizzling 会变得很可靠：
 
 在交换方法实现后记得要调用原生方法的实现（除非你非常确定可以不用调用原生方法的实现）：APIs 提供了输入输出的规则，而在输入输出中间的方法实现就是一个看不见的黑盒。交换了方法实现并且一些回调方法不会调用原生方法的实现这可能会造成底层实现的崩溃。
 
 避免冲突：为分类的方法加前缀，一定要确保调用了原生方法的所有地方不会因为你交换了方法的实现而出现意想不到的结果。
 
 理解实现原理：只是简单的拷贝粘贴交换方法实现的代码而不去理解实现原理不仅会让 App 很脆弱，并且浪费了学习 Objective-C 运行时的机会。阅读 Objective-C Runtime Reference 并且浏览 能够让你更好理解实现原理。
 
 持续的预防：不管你对你理解 swlzzling 框架，UIKit 或者其他内嵌框架有多自信，一定要记住所有东西在下一个发行版本都可能变得不再好使。做好准备，在使用这个黑魔法中走得更远，不要让程序反而出现不可思议的行为。
 */
@end
