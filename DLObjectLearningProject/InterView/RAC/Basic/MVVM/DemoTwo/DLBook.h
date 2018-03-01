//
//  DLBook.h
//  DLObjectLearningProject
//
//  Created by denglong on 01/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DLBook : NSObject
+ (instancetype)bookWithDict:(NSDictionary *)dictionary;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *subtitle;
@end
