//
//  Result.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/13.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, Obj) {
    OBJ_CLOUD = 1,
    OBJ_ROBOT = 2,
};

typedef NS_ENUM(NSUInteger, Type) {
    TYPE_REPLACE = 0,
    TYPE_MERGE = 1,
};

typedef NS_ENUM(NSUInteger, Code) {
    FAILED = 0,
    SUCCESS = 1,
};

/*
typedef NS_ENUM(NSUInteger, State) {
    ALL_SUCCESS = 3,
    ROBOT_SUCCESS = 2,
    CLOUD_SUCCESS = 1,
    ALL_FAIL = 0,
};
*/



@interface Result : NSObject

@property (nonatomic, assign) Obj obj;
@property (nonatomic, assign) Type type;
@property (nonatomic, assign) long version;
@property (nonatomic, assign) int count;
@property (nonatomic, assign) Code code;
@property (nonatomic,strong) NSArray *resultArray;/**< 返回结果数据集 */

@end
