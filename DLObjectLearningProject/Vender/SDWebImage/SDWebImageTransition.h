/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

#if SD_UIKIT || SD_MAC
#import "SDImageCache.h"

// This class is used to provide a transition animation after the view category load image finished. Use this on `sd_imageTransition` in UIView+WebCache.h
// 提供图片加载完成后的过渡动画
// for UIKit(iOS & tvOS), we use `+[UIView transitionWithView:duration:options:animations:completion]` for transition animation.
// for AppKit(macOS), we use `+[NSAnimationContext runAnimationGroup:completionHandler:]` for transition animation. You can call `+[NSAnimationContext currentContext]` to grab the context during animations block.
// These transition are provided for basic usage. If you need complicated animation, consider to directly use Core Animation or use `SDWebImageAvoidAutoSetImage` and implement your own after image load finished.

#if SD_UIKIT
typedef UIViewAnimationOptions SDWebImageAnimationOptions;
#else
typedef NS_OPTIONS(NSUInteger, SDWebImageAnimationOptions) {
    SDWebImageAnimationOptionAllowsImplicitAnimation = 1 << 0, // specify `allowsImplicitAnimation` for the `NSAnimationContext`  隐式动画
};
#endif

typedef void (^SDWebImageTransitionPreparesBlock)(__kindof UIView * _Nonnull view, UIImage * _Nullable image, NSData * _Nullable imageData, SDImageCacheType cacheType, NSURL * _Nullable imageURL);
typedef void (^SDWebImageTransitionAnimationsBlock)(__kindof UIView * _Nonnull view, UIImage * _Nullable image);
typedef void (^SDWebImageTransitionCompletionBlock)(BOOL finished);

@interface SDWebImageTransition : NSObject

/**
 By default, we set the image to the view at the beginning of the animtions. You can disable this and provide custom set image process
 默认情况下，我们将图像设置为动画开头的视图。 您可以禁用此功能并提供自定义设置的图像处理
 */
@property (nonatomic, assign) BOOL avoidAutoSetImage;
/**
 The duration of the transition animation, measured in seconds. Defaults to 0.5.
 */
@property (nonatomic, assign) NSTimeInterval duration;
/**
 The timing function used for all animations within this transition animation (macOS).
 此过渡动画中用于所有动画的计时功能
 */
@property (nonatomic, strong, nullable) CAMediaTimingFunction *timingFunction NS_AVAILABLE_MAC(10_7);
/**
 A mask of options indicating how you want to perform the animations.
 指示您想要如何执行动画的选项蒙版。
 */
@property (nonatomic, assign) SDWebImageAnimationOptions animationOptions;
/**
 A block object to be executed before the animation sequence starts.
 动画序列开始前的回调
 */
@property (nonatomic, copy, nullable) SDWebImageTransitionPreparesBlock prepares;
/**
 A block object that contains the changes you want to make to the specified view.
 一个块对象，其中包含要对指定视图进行的更改。
 */
@property (nonatomic, copy, nullable) SDWebImageTransitionAnimationsBlock animations;
/**
 A block object to be executed when the animation sequence ends.
 */
@property (nonatomic, copy, nullable) SDWebImageTransitionCompletionBlock completion;

@end

// Convenience way to create transition. Remember to specify the duration if needed.
// 便捷方式创建过渡动画。如需可自行指定过渡
// for UIKit, these transition just use the correspond `animationOptions`
// for AppKit, these transition use Core Animation in `animations`. So your view must be layer-backed. Set `wantsLayer = YES` before you apply it.

@interface SDWebImageTransition (Conveniences)

// class property is available in Xcode 8. We will drop the Xcode 7.3 support in 5.x
#if __has_feature(objc_class_property)
/// Fade transition.
@property (nonatomic, class, nonnull, readonly) SDWebImageTransition *fadeTransition;
/// Flip from left transition.
@property (nonatomic, class, nonnull, readonly) SDWebImageTransition *flipFromLeftTransition;
/// Flip from right transition.
@property (nonatomic, class, nonnull, readonly) SDWebImageTransition *flipFromRightTransition;
/// Flip from top transition.
@property (nonatomic, class, nonnull, readonly) SDWebImageTransition *flipFromTopTransition;
/// Flip from bottom transition.
@property (nonatomic, class, nonnull, readonly) SDWebImageTransition *flipFromBottomTransition;
/// Curl up transition.
@property (nonatomic, class, nonnull, readonly) SDWebImageTransition *curlUpTransition;
/// Curl down transition.
@property (nonatomic, class, nonnull, readonly) SDWebImageTransition *curlDownTransition;
#else
+ (nonnull instancetype)fadeTransition;
+ (nonnull instancetype)flipFromLeftTransition;
+ (nonnull instancetype)flipFromRightTransition;
+ (nonnull instancetype)flipFromTopTransition;
+ (nonnull instancetype)flipFromBottomTransition;
+ (nonnull instancetype)curlUpTransition;
+ (nonnull instancetype)curlDownTransition;
#endif

@end

#endif
