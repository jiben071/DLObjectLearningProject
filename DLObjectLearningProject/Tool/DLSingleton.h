//
//  DLSingleton.h
//  DLInterviewTest
//
//  Created by 邓 龙 on 9/5/15.
//  Copyright (c) 2015 dl. All rights reserved.
//  简便创建单例的宏

#ifndef DLInterviewTest_DLSingleton_h
#define DLInterviewTest_DLSingleton_h

// .h文件
#define DLSingletonH(name) + (instancetype)shared##name;

// .m文件
#define DLSingletonM(name) \
static id _instance; \
\
+ (instancetype)allocWithZone:(struct _NSZone *)zone \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [super allocWithZone:zone]; \
}); \
return _instance; \
} \
\
+ (instancetype)shared##name \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [[self alloc] init]; \
}); \
return _instance; \
} \
\
- (id)copyWithZone:(NSZone *)zone \
{ \
return _instance; \
}

#endif
