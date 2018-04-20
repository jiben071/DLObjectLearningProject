/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageManager.h"
#import "NSImage+WebCache.h"
#import <objc/message.h>

@interface SDWebImageCombinedOperation : NSObject <SDWebImageOperation>

@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;
@property (strong, nonatomic, nullable) SDWebImageDownloadToken *downloadToken;
@property (strong, nonatomic, nullable) NSOperation *cacheOperation;
@property (weak, nonatomic, nullable) SDWebImageManager *manager;

@end

@interface SDWebImageManager ()

@property (strong, nonatomic, readwrite, nonnull) SDImageCache *imageCache;
@property (strong, nonatomic, readwrite, nonnull) SDWebImageDownloader *imageDownloader;
@property (strong, nonatomic, nonnull) NSMutableSet<NSURL *> *failedURLs;
@property (strong, nonatomic, nonnull) NSMutableArray<SDWebImageCombinedOperation *> *runningOperations;

@end

@implementation SDWebImageManager
//单例模式
+ (nonnull instancetype)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

//初始化
- (nonnull instancetype)init {
    //初始化一个缓存管理器、下载控制器
    SDImageCache *cache = [SDImageCache sharedImageCache];
    SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
    return [self initWithCache:cache downloader:downloader];
}

- (nonnull instancetype)initWithCache:(nonnull SDImageCache *)cache downloader:(nonnull SDWebImageDownloader *)downloader {
    if ((self = [super init])) {
        _imageCache = cache;
        _imageDownloader = downloader;
        _failedURLs = [NSMutableSet new];//失败链接集合
        _runningOperations = [NSMutableArray new];//在进行的下载操作集合
    }
    return self;
}

- (nullable NSString *)cacheKeyForURL:(nullable NSURL *)url {
    if (!url) {
        return @"";
    }

    if (self.cacheKeyFilter) {
        return self.cacheKeyFilter(url);//如果外部有修改缓存key的block
    } else {
        return url.absoluteString;
    }
}

//压缩图片
- (nullable UIImage *)scaledImageForKey:(nullable NSString *)key image:(nullable UIImage *)image {
    return SDScaledImageForKey(key, image);//调用了内联函数
}

//判断是否存在于内存缓存中
- (void)cachedImageExistsForURL:(nullable NSURL *)url
                     completion:(nullable SDWebImageCheckCacheCompletionBlock)completionBlock {
    NSString *key = [self cacheKeyForURL:url];
    
    BOOL isInMemoryCache = ([self.imageCache imageFromMemoryCacheForKey:key] != nil);
    
    if (isInMemoryCache) {
        // making sure we call the completion block on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(YES);
            }
        });
        return;
    }
    
    //从硬盘中取出
    [self.imageCache diskImageExistsWithKey:key completion:^(BOOL isInDiskCache) {
        // the completion block of checkDiskCacheForImageWithKey:completion: is always called on the main queue, no need to further dispatch
        if (completionBlock) {
            completionBlock(isInDiskCache);
        }
    }];
}

//判断是否在硬盘中有缓存
- (void)diskImageExistsForURL:(nullable NSURL *)url
                   completion:(nullable SDWebImageCheckCacheCompletionBlock)completionBlock {
    NSString *key = [self cacheKeyForURL:url];
    
    [self.imageCache diskImageExistsWithKey:key completion:^(BOOL isInDiskCache) {
        // the completion block of checkDiskCacheForImageWithKey:completion: is always called on the main queue, no need to further dispatch
        if (completionBlock) {
            completionBlock(isInDiskCache);
        }
    }];
}

- (id <SDWebImageOperation>)loadImageWithURL:(nullable NSURL *)url
                                     options:(SDWebImageOptions)options
                                    progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                                   completed:(nullable SDInternalCompletionBlock)completedBlock {
    // Invoking this method without a completedBlock is pointless  没有完成回调，调用这个方法毫无意义
    NSAssert(completedBlock != nil, @"If you mean to prefetch the image, use -[SDWebImagePrefetcher prefetchURLs] instead");

    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, Xcode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    // 防止传进来的只是url字符串
    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
    }

    // Prevents app crashing on argument type error like sending NSNull instead of NSURL
    // 防止传空
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }

    //二合一的联合操作，包括查询缓存操作，下载操作  方便同时处理
    SDWebImageCombinedOperation *operation = [SDWebImageCombinedOperation new];
    operation.manager = self;//注入管理器

    BOOL isFailedUrl = NO;
    if (url) {
        @synchronized (self.failedURLs) {
            isFailedUrl = [self.failedURLs containsObject:url];
        }
    }

    //发生错误时的回调
    if (url.absoluteString.length == 0 || (!(options & SDWebImageRetryFailed) && isFailedUrl)) {
        [self callCompletionBlockForOperation:operation completion:completedBlock error:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil] url:url];
        return operation;
    }

    @synchronized (self.runningOperations) {
        [self.runningOperations addObject:operation];//记录操作
    }
    NSString *key = [self cacheKeyForURL:url];//url转换成key
    
    SDImageCacheOptions cacheOptions = 0;
    if (options & SDWebImageQueryDataWhenInMemory) cacheOptions |= SDImageCacheQueryDataWhenInMemory;
    if (options & SDWebImageQueryDiskSync) cacheOptions |= SDImageCacheQueryDiskSync;
    
    __weak SDWebImageCombinedOperation *weakOperation = operation;
    //记录查询缓存操作
    operation.cacheOperation = [self.imageCache queryCacheOperationForKey:key options:cacheOptions done:^(UIImage *cachedImage, NSData *cachedData, SDImageCacheType cacheType) {
        __strong __typeof(weakOperation) strongOperation = weakOperation;
        if (!strongOperation || strongOperation.isCancelled) {
            [self safelyRemoveOperationFromRunning:strongOperation];//安全移除
            return;
        }
        
        // Check whether we should download image from network
        //检查是否需要从网络下载图片
        BOOL shouldDownload = (!(options & SDWebImageFromCacheOnly))
            && (!cachedImage || options & SDWebImageRefreshCached)
            && (![self.delegate respondsToSelector:@selector(imageManager:shouldDownloadImageForURL:)] || [self.delegate imageManager:self shouldDownloadImageForURL:url]);
        if (shouldDownload) {
            if (cachedImage && options & SDWebImageRefreshCached) {
                // If image was found in the cache but SDWebImageRefreshCached is provided, notify about the cached image
                // AND try to re-download it in order to let a chance to NSURLCache to refresh it from server.
                // 如果有缓存，但指定了SDWebImageRefreshCached，回传缓存，并尝试重新向服务器请求刷新
                [self callCompletionBlockForOperation:strongOperation completion:completedBlock image:cachedImage data:cachedData error:nil cacheType:cacheType finished:YES url:url];
            }

            // download if no image or requested to refresh anyway, and download allowed by delegate
            //下载操作
            SDWebImageDownloaderOptions downloaderOptions = 0;
            if (options & SDWebImageLowPriority) downloaderOptions |= SDWebImageDownloaderLowPriority;
            if (options & SDWebImageProgressiveDownload) downloaderOptions |= SDWebImageDownloaderProgressiveDownload;
            if (options & SDWebImageRefreshCached) downloaderOptions |= SDWebImageDownloaderUseNSURLCache;
            if (options & SDWebImageContinueInBackground) downloaderOptions |= SDWebImageDownloaderContinueInBackground;
            if (options & SDWebImageHandleCookies) downloaderOptions |= SDWebImageDownloaderHandleCookies;
            if (options & SDWebImageAllowInvalidSSLCertificates) downloaderOptions |= SDWebImageDownloaderAllowInvalidSSLCertificates;
            if (options & SDWebImageHighPriority) downloaderOptions |= SDWebImageDownloaderHighPriority;
            if (options & SDWebImageScaleDownLargeImages) downloaderOptions |= SDWebImageDownloaderScaleDownLargeImages;
            
            if (cachedImage && options & SDWebImageRefreshCached) {
                // force progressive off if image already cached but forced refreshing
                //如果强制刷新，强制转成逐渐显示图片
                downloaderOptions &= ~SDWebImageDownloaderProgressiveDownload;
                // ignore image read from NSURLCache if image if cached but force refreshing
                //如果强制刷新，忽略NSURLCache缓存的图片
                downloaderOptions |= SDWebImageDownloaderIgnoreCachedResponse;
            }
            
            // `SDWebImageCombinedOperation` -> `SDWebImageDownloadToken` -> `downloadOperationCancelToken`, which is a `SDCallbacksDictionary` and retain the completed block below, so we need weak-strong again to avoid retain cycle
            __weak typeof(strongOperation) weakSubOperation = strongOperation;
            //保存下载操作的token
            strongOperation.downloadToken = [self.imageDownloader downloadImageWithURL:url options:downloaderOptions progress:progressBlock completed:^(UIImage *downloadedImage, NSData *downloadedData, NSError *error, BOOL finished) {
                __strong typeof(weakSubOperation) strongSubOperation = weakSubOperation;
                if (!strongSubOperation || strongSubOperation.isCancelled) {
                    // Do nothing if the operation was cancelled  不做任何事情
                    // See #699 for more details
                    // if we would call the completedBlock, there could be a race condition between this block and another completedBlock for the same object, so if this one is called second, we will overwrite the new data
                    //如果这里调用completedBlock,可能会与另外一个completedBlock竞争同一个对象,导致覆写
                } else if (error) {//发生了错误
                    [self callCompletionBlockForOperation:strongSubOperation completion:completedBlock error:error url:url];
                    BOOL shouldBlockFailedURL;
                    // Check whether we should block failed url
                    if ([self.delegate respondsToSelector:@selector(imageManager:shouldBlockFailedURL:withError:)]) {
                        shouldBlockFailedURL = [self.delegate imageManager:self shouldBlockFailedURL:url withError:error];
                    } else {
                        shouldBlockFailedURL = (   error.code != NSURLErrorNotConnectedToInternet
                                                && error.code != NSURLErrorCancelled
                                                && error.code != NSURLErrorTimedOut
                                                && error.code != NSURLErrorInternationalRoamingOff
                                                && error.code != NSURLErrorDataNotAllowed
                                                && error.code != NSURLErrorCannotFindHost
                                                && error.code != NSURLErrorCannotConnectToHost
                                                && error.code != NSURLErrorNetworkConnectionLost);
                    }
                    
                    if (shouldBlockFailedURL) {//判断是否要将此URL加入黑名单
                        @synchronized (self.failedURLs) {
                            [self.failedURLs addObject:url];
                        }
                    }
                }
                else {
                    if ((options & SDWebImageRetryFailed)) {//如果是指定重试
                        @synchronized (self.failedURLs) {
                            [self.failedURLs removeObject:url];//从黑名单中移除
                        }
                    }
                    
                    BOOL cacheOnDisk = !(options & SDWebImageCacheMemoryOnly);
                    
                    // We've done the scale process in SDWebImageDownloader with the shared manager, this is used for custom manager and avoid extra scale.
                    //避免再次缩放，这里用于自定义下载器
                    if (self != [SDWebImageManager sharedManager] && self.cacheKeyFilter && downloadedImage) {
                        downloadedImage = [self scaledImageForKey:key image:downloadedImage];
                    }

                    if (options & SDWebImageRefreshCached && cachedImage && !downloadedImage) {
                        // Image refresh hit the NSURLCache cache, do not call the completion block
                        // 图像刷新影响NSURLCache缓存，不要调用completionBlock
                    } else if (downloadedImage && (!downloadedImage.images || (options & SDWebImageTransformAnimatedImage)) && [self.delegate respondsToSelector:@selector(imageManager:transformDownloadedImage:withURL:)]) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            UIImage *transformedImage = [self.delegate imageManager:self transformDownloadedImage:downloadedImage withURL:url];

                            if (transformedImage && finished) {//判断是否已经在外部转换了图片
                                BOOL imageWasTransformed = ![transformedImage isEqual:downloadedImage];
                                NSData *cacheData;
                                // pass nil if the image was transformed, so we can recalculate the data from the image
                                // 如果图片经过了转换，传送nil，以便重新计算
                                if (self.cacheSerializer) {
                                    cacheData = self.cacheSerializer(transformedImage, (imageWasTransformed ? nil : downloadedData), url);
                                } else {
                                    cacheData = (imageWasTransformed ? nil : downloadedData);
                                }
                                //缓存data
                                [self.imageCache storeImage:transformedImage imageData:cacheData forKey:key toDisk:cacheOnDisk completion:nil];
                            }
                            
                            [self callCompletionBlockForOperation:strongSubOperation completion:completedBlock image:transformedImage data:downloadedData error:nil cacheType:SDImageCacheTypeNone finished:finished url:url];
                        });
                    } else {
                        if (downloadedImage && finished) {
                            if (self.cacheSerializer) {
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                    NSData *cacheData = self.cacheSerializer(downloadedImage, downloadedData, url);
                                    [self.imageCache storeImage:downloadedImage imageData:cacheData forKey:key toDisk:cacheOnDisk completion:nil];
                                });
                            } else {
                                [self.imageCache storeImage:downloadedImage imageData:downloadedData forKey:key toDisk:cacheOnDisk completion:nil];
                            }
                        }
                        [self callCompletionBlockForOperation:strongSubOperation completion:completedBlock image:downloadedImage data:downloadedData error:nil cacheType:SDImageCacheTypeNone finished:finished url:url];
                    }
                }

                if (finished) {
                    [self safelyRemoveOperationFromRunning:strongSubOperation];
                }
            }];
        } else if (cachedImage) {
            [self callCompletionBlockForOperation:strongOperation completion:completedBlock image:cachedImage data:cachedData error:nil cacheType:cacheType finished:YES url:url];
            [self safelyRemoveOperationFromRunning:strongOperation];
        } else {
            // Image not in cache and download disallowed by delegate
            // 图像不在缓存中并且不允许代理下载
            [self callCompletionBlockForOperation:strongOperation completion:completedBlock image:nil data:nil error:nil cacheType:SDImageCacheTypeNone finished:YES url:url];
            [self safelyRemoveOperationFromRunning:strongOperation];
        }
    }];

    return operation;
}

- (void)saveImageToCache:(nullable UIImage *)image forURL:(nullable NSURL *)url {
    if (image && url) {
        NSString *key = [self cacheKeyForURL:url];
        [self.imageCache storeImage:image forKey:key toDisk:YES completion:nil];
    }
}

- (void)cancelAll {
    @synchronized (self.runningOperations) {
        NSArray<SDWebImageCombinedOperation *> *copiedOperations = [self.runningOperations copy];
        [copiedOperations makeObjectsPerformSelector:@selector(cancel)];
        [self.runningOperations removeObjectsInArray:copiedOperations];
    }
}

- (BOOL)isRunning {
    BOOL isRunning = NO;
    @synchronized (self.runningOperations) {
        isRunning = (self.runningOperations.count > 0);
    }
    return isRunning;
}

- (void)safelyRemoveOperationFromRunning:(nullable SDWebImageCombinedOperation*)operation {
    @synchronized (self.runningOperations) {
        if (operation) {
            [self.runningOperations removeObject:operation];
        }
    }
}

- (void)callCompletionBlockForOperation:(nullable SDWebImageCombinedOperation*)operation
                             completion:(nullable SDInternalCompletionBlock)completionBlock
                                  error:(nullable NSError *)error
                                    url:(nullable NSURL *)url {
    [self callCompletionBlockForOperation:operation completion:completionBlock image:nil data:nil error:error cacheType:SDImageCacheTypeNone finished:YES url:url];
}

- (void)callCompletionBlockForOperation:(nullable SDWebImageCombinedOperation*)operation
                             completion:(nullable SDInternalCompletionBlock)completionBlock
                                  image:(nullable UIImage *)image
                                   data:(nullable NSData *)data
                                  error:(nullable NSError *)error
                              cacheType:(SDImageCacheType)cacheType
                               finished:(BOOL)finished
                                    url:(nullable NSURL *)url {
    dispatch_main_async_safe(^{
        if (operation && !operation.isCancelled && completionBlock) {
            completionBlock(image, data, error, cacheType, finished, url);
        }
    });
}

@end


@implementation SDWebImageCombinedOperation

/*
 在里面封装一个NSOperation，这么做的目的应该是为了使代码更简洁。因为下载操作需要查询缓存的operation和实际下载的operation，这个类的cancel方法可以同时cancel两个operation，同时还可以维护一个状态cancelled。
 */
- (void)cancel {
    @synchronized(self) {
        self.cancelled = YES;
        if (self.cacheOperation) {//查询缓存的operation
            [self.cacheOperation cancel];
            self.cacheOperation = nil;
        }
        if (self.downloadToken) {//实际下载的operation
            [self.manager.imageDownloader cancel:self.downloadToken];
        }
        [self.manager safelyRemoveOperationFromRunning:self];
    }
}

@end
