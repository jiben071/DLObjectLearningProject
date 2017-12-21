//
//  Sync_Utils.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/13.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "Sync_Utils.h"

@implementation Sync_Utils

+(BOOL)isEmptyString:(NSString *)string {
    if(string == nil) return YES;
    else if([string isEqual:[NSNull null]]) return YES;
    else if(string.length == 0) return YES;
    else return NO;
}



@end
