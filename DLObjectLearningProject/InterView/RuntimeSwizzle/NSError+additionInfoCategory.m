//
//  NSError+additionInfoCategory.m
//  AlphaMini
//
//  Created by denglong on 09/04/2018.
//  Copyright © 2018 denglong. All rights reserved.
//

#import "NSError+additionInfoCategory.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSError (additionInfoCategory)
static char kAssociatedObjectKey_additionInfo;
- (void)setAdditionInfo:(NSString *)additionInfo {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_additionInfo, additionInfo, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)additionInfo {
    return (NSString *)objc_getAssociatedObject(self, &kAssociatedObjectKey_additionInfo);
}
@end
