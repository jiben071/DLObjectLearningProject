/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIView+WebCacheOperation.h"

#if SD_UIKIT || SD_MAC

#import "objc/runtime.h"

static char loadOperationKey;

// key is copy, value is weak because operation instance is retained by SDWebImageManager's runningOperations property
// we should use lock to keep thread-safe because these method may not be acessed from main queue
typedef NSMapTable<NSString *, id<SDWebImageOperation>> SDOperationsDictionary;

@implementation UIView (WebCacheOperation)

- (SDOperationsDictionary *)sd_operationDictionary {
    @synchronized(self) {
        SDOperationsDictionary *operations = objc_getAssociatedObject(self, &loadOperationKey);
        if (operations) {
            return operations;
        }
        /*
         NSMapTable是可变的，没有不可变的类
         NSMapTable可以持有键和值的弱引用，当键或值当中的一个被释放时，整个这一项就会被移除掉
         NSMapTable可以在加入成员时进行copy操作
         NSMapTable可以存储任意的指针，通过指针来进行相等性和散列检查
         */
        /*
         对比
         
         传统的集合类型都有哪些短板：
         
         放到集合中的对象，只能强引用
         如果想要弱引用，要先用NSValue打包
         不能放入nil
         
         总结
         永远先从最高的抽象层次去尝试解决问题
         如果碰到的问题包含内存管理需求，那么NSHashTable和NSMapTable值得一试
         https://www.jianshu.com/p/cf4e15b26f64
         
         关键：NSPointerFunctionsWeakMemory  不会修改NSMapTable容器内对象元素的引用计数，并且对象释放后，会被自动移除
         */
        operations = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
        objc_setAssociatedObject(self, &loadOperationKey, operations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return operations;
    }
}

- (void)sd_setImageLoadOperation:(nullable id<SDWebImageOperation>)operation forKey:(nullable NSString *)key {
    if (key) {
        [self sd_cancelImageLoadOperationWithKey:key];
        if (operation) {
            SDOperationsDictionary *operationDictionary = [self sd_operationDictionary];
            @synchronized (self) {
                [operationDictionary setObject:operation forKey:key];
            }
        }
    }
}

- (void)sd_cancelImageLoadOperationWithKey:(nullable NSString *)key {
    // Cancel in progress downloader from queue
    SDOperationsDictionary *operationDictionary = [self sd_operationDictionary];
    id<SDWebImageOperation> operation;
    @synchronized (self) {
        operation = [operationDictionary objectForKey:key];
    }
    if (operation) {
        if ([operation conformsToProtocol:@protocol(SDWebImageOperation)]){//面向接口编程，不用指定某个类，以便实现自定义的下载操作类
            [operation cancel];
        }
        @synchronized (self) {
            [operationDictionary removeObjectForKey:key];
        }
    }
}

- (void)sd_removeImageLoadOperationWithKey:(nullable NSString *)key {
    if (key) {
        SDOperationsDictionary *operationDictionary = [self sd_operationDictionary];
        @synchronized (self) {
            [operationDictionary removeObjectForKey:key];
        }
    }
}

@end

#endif
