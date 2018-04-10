//
//  NSError+additionInfoCategory.h
//  AlphaMini
//
//  Created by denglong on 09/04/2018.
//  Copyright © 2018 denglong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (additionInfoCategory)
@property(nonatomic, copy) NSString *additionInfo;/*目的：附加一些信息*/
@end
