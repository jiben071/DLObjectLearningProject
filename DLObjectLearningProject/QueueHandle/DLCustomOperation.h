//
//  DLCustomOperation.h
//  DLObjectLearningProject
//
//  Created by denglong on 30/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DLCustomOperation : NSOperation
/**
 10  类方法实例化自定义操作
 11
 12  @param urlString 图片地址
 13  @param finishBlock 完成回调
 14  @return 自定义操作
 15  */
+ (instancetype)downloadImageWithURLString:(NSString *)urlString andFinishBlock:(void(^)(UIImage*))finishBlock;
@end
