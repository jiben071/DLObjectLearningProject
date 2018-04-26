//
//  Header.h
//  CommandPattern
//
//  Created by HEYANG on 15/11/25.
//  Copyright © 2015年 HEYANG. All rights reserved.
//


/**
 *  单例模式宏抽取
 *
 *  @description
 *
 *  1、创建一个Singleton.h头文件然后输入以下所有的文件。
 *  2、使用：在需要设置为单例的类中，@interface里使用interfaceSingleton(类名)
 *                             @implementation里使用implementationSingleton(类名)
 *                      这样，即可直接就将所在的类设置为单例模式
 *
 */
// 以后就可以使用interfaceSingleton来替代后面的方法声明
// 这里宏抽取的是在interface的单例模式方法声明
#define interfaceSingleton(name)  +(instancetype)share##name



//这里宏抽取的是在implementation的单例模式
#if __has_feature(objc_arc)
// ARC
#define implementationSingleton(name)  \
+ (instancetype)share##name \
{ \
name *instance = [[self alloc] init]; \
return instance; \
} \
static name *_instance = nil; \
+ (instancetype)allocWithZone:(struct _NSZone *)zone \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [[super allocWithZone:zone] init]; \
}); \
return _instance; \
} \
- (id)copyWithZone:(NSZone *)zone{ \
return _instance; \
} \
- (id)mutableCopyWithZone:(NSZone *)zone \
{ \
return _instance; \
}
#else
// MRC

#define implementationSingleton(name)  \
+ (instancetype)share##name \
{ \
name *instance = [[self alloc] init]; \
return instance; \
} \
static name *_instance = nil; \
+ (instancetype)allocWithZone:(struct _NSZone *)zone \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [[super allocWithZone:zone] init]; \
}); \
return _instance; \
} \
- (id)copyWithZone:(NSZone *)zone{ \
return _instance; \
} \
- (id)mutableCopyWithZone:(NSZone *)zone \
{ \
return _instance; \
} \
- (oneway void)release \
{ \
} \
- (instancetype)retain \
{ \
return _instance; \
} \
- (NSUInteger)retainCount \
{ \
return  MAXFLOAT; \
}
#endif


