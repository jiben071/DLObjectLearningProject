/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"
#import "SDWebImageOperation.h"

typedef NS_OPTIONS(NSUInteger, SDWebImageDownloaderOptions) {
    /**
     * Put the download in the low queue priority and task priority.  低优先级下载
     */
    SDWebImageDownloaderLowPriority = 1 << 0,
    
    /**
     * This flag enables progressive download, 渐进式下载 the image is displayed progressively during download as a browser would do. 下载过程中逐渐显示图片
     */
    SDWebImageDownloaderProgressiveDownload = 1 << 1,

    /**
     * By default, request prevent the use of NSURLCache. With this flag, NSURLCache
     * is used with default policies.  默认是没有NSURLCache的,标记这个才有
     */
    SDWebImageDownloaderUseNSURLCache = 1 << 2,

    /**
     * Call completion block with nil image/imageData if the image was read from NSURLCache
     * (to be combined with `SDWebImageDownloaderUseNSURLCache`).
     * 忽略NSURLCache的缓存
     */
    SDWebImageDownloaderIgnoreCachedResponse = 1 << 3,
    
    /**
     * In iOS 4+, continue the download of the image if the app goes to background. This is achieved by asking the system for
     * extra time in background to let the request finish. If the background task expires the operation will be cancelled.
     * 继续后台下载图片
     */
    SDWebImageDownloaderContinueInBackground = 1 << 4,

    /**
     * Handles cookies stored in NSHTTPCookieStore by setting 
     * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
     * 处理存储在NSHTTPCookieStore 中的cookie
     * http://jinqianchina.github.io/2016/01/07/Cookie机制以及cookie在iOS中使用介绍/
     * NSHTTPCookieStorage单件类提供了管理所有NSHTTPCookie对象的接口，在OS X里,cookie是在所有程序中共享的，而在iOS中,cookie只当当前应用中有效。
     */
    SDWebImageDownloaderHandleCookies = 1 << 5,

    /**
     * Enable to allow untrusted SSL certificates.
     * Useful for testing purposes. Use with caution in production.
     * 启用以允许不可信的SSL证书。
     * 用于测试目的。 在生产中谨慎使用。
     */
    SDWebImageDownloaderAllowInvalidSSLCertificates = 1 << 6,

    /**
     * Put the download in the high queue priority and task priority.
     * 高优先级
     */
    SDWebImageDownloaderHighPriority = 1 << 7,
    
    /**
     * Scale down the image
     * 缩小下载的图像
     */
    SDWebImageDownloaderScaleDownLargeImages = 1 << 8,
};

typedef NS_ENUM(NSInteger, SDWebImageDownloaderExecutionOrder) {
    /**
     * Default value. All download operations will execute in queue style (first-in-first-out).
     * 下载队列顺序（先进先出）
     */
    SDWebImageDownloaderFIFOExecutionOrder,

    /**
     * All download operations will execute in stack style (last-in-first-out).
     * 后进先出
     */
    SDWebImageDownloaderLIFOExecutionOrder
};

FOUNDATION_EXPORT NSString * _Nonnull const SDWebImageDownloadStartNotification;//开始下载通知
FOUNDATION_EXPORT NSString * _Nonnull const SDWebImageDownloadStopNotification;//停止下载通知

typedef void(^SDWebImageDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL);

typedef void(^SDWebImageDownloaderCompletedBlock)(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished);

typedef NSDictionary<NSString *, NSString *> SDHTTPHeadersDictionary;
typedef NSMutableDictionary<NSString *, NSString *> SDHTTPHeadersMutableDictionary;

typedef SDHTTPHeadersDictionary * _Nullable (^SDWebImageDownloaderHeadersFilterBlock)(NSURL * _Nullable url, SDHTTPHeadersDictionary * _Nullable headers);

/**
 *  A token associated with each download. Can be used to cancel a download
 *  与每个下载相关联的令牌。 可以用来取消下载
 */
@interface SDWebImageDownloadToken : NSObject <SDWebImageOperation>

/**
 The download's URL. This should be readonly and you should not modify
 下载的URL。 只读不改
 */
@property (nonatomic, strong, nullable) NSURL *url;
/**
 The cancel token taken from `addHandlersForProgress:completed`. This should be readonly and you should not modify
 取自'addHandlersForProgress：completed`的取消令牌。 只读不改
 @note use `-[SDWebImageDownloadToken cancel]` to cancel the token  取消方式
 */
@property (nonatomic, strong, nullable) id downloadOperationCancelToken;

@end


/**
 * Asynchronous downloader dedicated(专用) and optimized(优化) for image loading.
 * 异步下载器专用于图像加载并进行了优化。
 */
@interface SDWebImageDownloader : NSObject

/**
 * Decompressing images that are downloaded and cached can improve performance but can consume lot of memory.
 * Defaults to YES. Set this to NO if you are experiencing a crash due to excessive memory consumption.
 * 解压下载和缓存的图像可以提高性能，但会消耗大量内存。
 * 默认为YES。 如果由于内存消耗过多而导致崩溃，请将其设置为NO。
 */
@property (assign, nonatomic) BOOL shouldDecompressImages;

/**
 *  The maximum number of concurrent downloads
 *  最大下载数
 */
@property (assign, nonatomic) NSInteger maxConcurrentDownloads;

/**
 * Shows the current amount of downloads that still need to be downloaded
 * 当前仍需下载的下载数
 */
@property (readonly, nonatomic) NSUInteger currentDownloadCount;

/**
 *  The timeout value (in seconds) for the download operation. Default: 15.0.
 *  下载超时时间
 */
@property (assign, nonatomic) NSTimeInterval downloadTimeout;

/**
 * The configuration in use by the internal NSURLSession.
 * Mutating this object directly has no effect.
 * 仅供NSURLSession内部使用,直接操作无效
 *
 * @see createNewSessionWithConfiguration:
 */
@property (readonly, nonatomic, nonnull) NSURLSessionConfiguration *sessionConfiguration;


/**
 * Changes download operations execution order. Default value is `SDWebImageDownloaderFIFOExecutionOrder`.
 * 变更下载执行顺序
 */
@property (assign, nonatomic) SDWebImageDownloaderExecutionOrder executionOrder;

/**
 *  Singleton method, returns the shared instance
 *
 *  @return global shared instance of downloader class
 *  单例模式
 */
+ (nonnull instancetype)sharedDownloader;

/**
 *  Set the default URL credential to be set for request operations.
 *  请求操作的url凭据
 */
@property (strong, nonatomic, nullable) NSURLCredential *urlCredential;

/**
 * Set username
 */
@property (strong, nonatomic, nullable) NSString *username;

/**
 * Set password
 */
@property (strong, nonatomic, nullable) NSString *password;

/**
 * Set filter to pick headers for downloading image HTTP request.
 * 设置过滤器以选择用于下载图像HTTP请求的header。
 * This block will be invoked for each downloading image request, returned
 * NSDictionary will be used as headers in corresponding HTTP request.
 * 该回调将在每个下载图像请求调用，同时返回的NSDictionary将在相应的HTTP请求中用作header。
 */
@property (nonatomic, copy, nullable) SDWebImageDownloaderHeadersFilterBlock headersFilter;

/**
 * Creates an instance of a downloader with specified session configuration.
 * 使用指定的sesseion配置创建下载器
 * @note `timeoutIntervalForRequest` is going to be overwritten.
 * @return new instance of downloader class
 */
- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)sessionConfiguration NS_DESIGNATED_INITIALIZER;

/**
 * Set a value for a HTTP header to be appended to each download HTTP request.
 *
 * @param value The value for the header field. Use `nil` value to remove the header.
 * @param field The name of the header field to set.
 */
- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(nullable NSString *)field;

/**
 * Returns the value of the specified HTTP header field.
 *
 * @return The value associated with the header field field, or `nil` if there is no corresponding header field.
 */
- (nullable NSString *)valueForHTTPHeaderField:(nullable NSString *)field;

/**
 * Sets a subclass of `SDWebImageDownloaderOperation` as the default
 * `NSOperation` to be used each time SDWebImage constructs a request
 * operation to download an image.
 *
 * @param operationClass The subclass of `SDWebImageDownloaderOperation` to set 
 *        as default. Passing `nil` will revert to `SDWebImageDownloaderOperation`.
 */
- (void)setOperationClass:(nullable Class)operationClass;

/**
 * Creates a SDWebImageDownloader async downloader instance with a given URL
 *
 * The delegate will be informed when the image is finish downloaded or an error has happen.
 *
 * @see SDWebImageDownloaderDelegate
 *
 * @param url            The URL to the image to download
 * @param options        The options to be used for this download
 * @param progressBlock  A block called repeatedly while the image is downloading
 *                       @note the progress block is executed on a background queue
 * @param completedBlock A block called once the download is completed.
 *                       If the download succeeded, the image parameter is set, in case of error,
 *                       error parameter is set with the error. The last parameter is always YES
 *                       if SDWebImageDownloaderProgressiveDownload isn't use. With the
 *                       SDWebImageDownloaderProgressiveDownload option, this block is called
 *                       repeatedly with the partial image object and the finished argument set to NO
 *                       before to be called a last time with the full image and finished argument
 *                       set to YES. In case of error, the finished argument is always YES.
 *
 * @return A token (SDWebImageDownloadToken) that can be passed to -cancel: to cancel this operation
 */
- (nullable SDWebImageDownloadToken *)downloadImageWithURL:(nullable NSURL *)url
                                                   options:(SDWebImageDownloaderOptions)options
                                                  progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                                                 completed:(nullable SDWebImageDownloaderCompletedBlock)completedBlock;

/**
 * Cancels a download that was previously queued using -downloadImageWithURL:options:progress:completed:
 *
 * @param token The token received from -downloadImageWithURL:options:progress:completed: that should be canceled.
 */
- (void)cancel:(nullable SDWebImageDownloadToken *)token;

/**
 * Sets the download queue suspension state
 */
- (void)setSuspended:(BOOL)suspended;

/**
 * Cancels all download operations in the queue
 */
- (void)cancelAllDownloads;

/**
 * Forces SDWebImageDownloader to create and use a new NSURLSession that is
 * initialized with the given configuration.
 * @note All existing download operations in the queue will be cancelled.
 * @note `timeoutIntervalForRequest` is going to be overwritten.
 *
 * @param sessionConfiguration The configuration to use for the new NSURLSession
 */
- (void)createNewSessionWithConfiguration:(nonnull NSURLSessionConfiguration *)sessionConfiguration;

/**
 * Invalidates the managed session, optionally canceling pending operations.
 * @note If you use custom downloader instead of the shared downloader, you need call this method when you do not use it to avoid memory leak
 * @param cancelPendingOperations Whether or not to cancel pending operations.
 * @note Calling this method on the shared downloader has no effect.
 */
- (void)invalidateSessionAndCancel:(BOOL)cancelPendingOperations;

@end
