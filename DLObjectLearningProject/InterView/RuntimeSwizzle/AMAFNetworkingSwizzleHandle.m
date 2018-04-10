//
//  AMAFNetworkingSwizzleHandle.m
//  AlphaMini
//
//  Created by denglong on 09/04/2018.
//  Copyright © 2018 denglong. All rights reserved.
//  参考链接：http://tech.yunyingxbs.com/article/detail/id/229.html  method_invoke

#import "AMAFNetworkingSwizzleHandle.h"
#import "NSError+additionInfoCategory.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <AFNetworking/AFNetworking.h>

@implementation AMAFNetworkingSwizzleHandle
+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleOriginalSEL];
    });
}

- (NSURLSessionDataTask *)am_dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                  uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgress
                                downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgress
                                         success:(void (^)(NSURLSessionDataTask *, id))success
                                         failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSError *serializationError = nil;
    AFHTTPRequestSerializer *requestSerizlizer;
    
    Ivar ivar = class_getInstanceVariable([AFHTTPSessionManager class], "_requestSerializer");
    requestSerizlizer = object_getIvar(self, ivar);
    
    NSURL *baseUrl;
    ivar = class_getInstanceVariable([AFHTTPSessionManager class], "_baseURL");
    baseUrl = object_getIvar(self, ivar);
    
    dispatch_queue_t mainQueue;
    ivar = class_getInstanceVariable([AFHTTPSessionManager class], "_completionQueue");
    mainQueue = object_getIvar(self, ivar);
    
    
    NSMutableURLRequest *request = [requestSerizlizer requestWithMethod:method URLString:[[NSURL URLWithString:URLString relativeToURL:baseUrl] absoluteString] parameters:parameters error:&serializationError];
    if (serializationError) {
        if (failure) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(mainQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
#pragma clang diagnostic pop
        }
        
        return nil;
    }
    
    __block NSURLSessionDataTask *dataTask = nil;
    
    // 获取方法
    Method dataMethod = class_getInstanceMethod([AFHTTPSessionManager class], @selector(dataTaskWithRequest:uploadProgress:downloadProgress:completionHandler:));
    
    // 调用函数
    
    dataTask = ((NSURLSessionDataTask * (*)(id, Method,
                            NSURLRequest *,
                            void (^)(NSProgress *uploadProgress),
                            void (^)(NSProgress *downloadProgress),
                            void (^)(NSURLResponse *response, id _Nullable responseObject,  NSError * _Nullable error)
                         ))method_invoke)((id)(self),
                                          dataMethod,
                                          request,
                                          uploadProgress,
                                          downloadProgress,
                                          ^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                                   if (error) {
                                       if (failure) {
//                                           NSString *responseJsonStr = [responseObject mj_JSONString];
//                                           error.additionInfo = responseJsonStr;
                                           failure(dataTask, error);
                                       }
                                   } else {
                                       if (success) {
                                           success(dataTask, responseObject);
                                       }
                                   }
                               });
    NSLog(@"call return vlaue is %@", dataTask);
    
    return dataTask;
}


//- (AFHTTPRequestSerializer *)gainRequestSerizlizer{
//    id request;
//    Ivar ivar = class_getInstanceVariable([AFHTTPSessionManager class], "_requestSerializer");
//    request = object_getIvar([AFHTTPSessionManager manager], ivar);
//    return request;
//}

//- (NSURL *)gainBaseUrl{
//    id url;
//    Ivar ivar = class_getInstanceVariable([AFHTTPSessionManager class], "_baseURL");
//    url = object_getIvar([AFHTTPSessionManager manager], ivar);
//    return url;
//}

//- (dispatch_queue_t)gainMainQueue{
//    id queue;
//    Ivar ivar = class_getInstanceVariable([AFHTTPSessionManager class], "_completionQueue");
//    queue = object_getIvar([AFHTTPSessionManager manager], ivar);
//    return queue;
//}

+ (void)swizzleOriginalSEL{
    SEL originalSEL = @selector(dataTaskWithHTTPMethod:URLString:parameters:uploadProgress:downloadProgress:success:failure:);
    SEL swizzlingSEL = @selector(am_dataTaskWithHTTPMethod:URLString:parameters:uploadProgress:downloadProgress:success:failure:);
    
    Method originalMethod = class_getInstanceMethod([AFHTTPSessionManager class], originalSEL);
    Method swizzlingMethod = class_getInstanceMethod([self class], swizzlingSEL);
    
    Boolean isAddMethod = class_addMethod([AFHTTPSessionManager class], originalSEL,
                                            method_getImplementation(swizzlingMethod),
                                            method_getTypeEncoding(swizzlingMethod));
    if (isAddMethod) {
        class_replaceMethod([self class], swizzlingSEL,
                              method_getImplementation(originalMethod),
                              method_getTypeEncoding(originalMethod));
    } else {
         method_exchangeImplementations(originalMethod, swizzlingMethod);
    }
}


@end
