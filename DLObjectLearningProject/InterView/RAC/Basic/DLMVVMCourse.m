//
//  DLMVVMCourse.m
//  DLObjectLearningProject
//
//  Created by denglong on 01/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  参考链接：http://bbs.520it.com/forum.php?mod=viewthread&tid=257

#import "DLMVVMCourse.h"

@implementation DLMVVMCourse
//2.介绍MVVM架构思想
//2.1 程序为什么要架构：便于程序员开发和维护代码

//2.2 常见的架构思想：
//MVC  M：模型 V：视图 C：控制器
//MVVM M:模型 V:视图+控制器 VM:视图模型
//MVCS M:模型 V:视图 C:控制器 S:服务类
//VIPER V:视图 I:交互器 P:展示器 E:实体 R:路由
//PS:VIPER架构思想

//2.3MVVM介绍
//模型（M)：保存视图数据
//视图+控制器（V)：展示内容+如何展示
//视图模型（VM）：处理展示的业务逻辑，包括按钮的点击，数据的请求和解析等等。

//3.ReactiveCocoa + MVVM 实战一：登录界面
//3.1 需求+分析+步骤
/*
 需求：
 1.监听两个文本框的内容，有内容才允许按钮点击
 2.默认登录请求.
 用MVVM：实现，之前界面的所有业务逻辑
 
 分析：
 1.之前界面的所有业务逻辑都交给控制器做处理
 2.在MVVM架构中把控制器的业务全部搬去VM模型，也就是每个控制器对应一个VM模型.
 
 步骤：
 1.创建LoginViewModel类，处理登录界面业务逻辑.
 2.这个类里面应该保存着账号的信息，创建一个账号Account模型
 3.LoginViewModel应该保存着账号信息Account模型。
 4.需要时刻监听Account模型中的账号和密码的改变，怎么监听？
 5.在非RAC开发中，都是习惯赋值，在RAC开发中，需要改变开发思维，由赋值转变为绑定，可以在一开始初始化的时候，就给Account模型中的属性绑定，并不需要重写set方法。
 6.每次Account模型的值改变，就需要判断按钮能否点击，在VM模型中做处理，给外界提供一个能否点击按钮的信号.
 7.这个登录信号需要判断Account中账号和密码是否有值，用KVO监听这两个值的改变，把他们聚合成登录信号.
 8.监听按钮的点击，由VM处理，应该给VM声明一个RACCommand，专门处理登录业务逻辑.
 9.执行命令，把数据包装成信号传递出去
 10.监听命令中信号的数据传递
 11.监听命令的执行时刻
 */


/*
 4.ReactiveCocoa + MVVM 实战二：网络请求数据
 
 4.1 接口：
 这里先给朋友介绍一个免费的网络数据接口，豆瓣。可以经常用来练习一些网络请求的小Demo.
 
 4.2 需求+分析+步骤
 */
/*
 需求：请求豆瓣图书信息，url:https://api.douban.com/v2/book/search?q=基础
 分析：请求一样，交给VM模型管理
 步骤:
 1.控制器提供一个视图模型（requesViewModel），处理界面的业务逻辑
 2.VM提供一个命令，处理请求业务逻辑
 3.在创建命令的block中，会把请求包装成一个信号，等请求成功的时候，就会把数据传递出去。
 4.请求数据成功，应该把字典转换成模型，保存到视图模型中，控制器想用就直接从视图模型中获取。
 5.假设控制器想展示内容到tableView，直接让视图模型成为tableView的数据源，把所有的业务逻辑交给视图模型去做，这样控制器的代码就非常少了。
 */
@end
