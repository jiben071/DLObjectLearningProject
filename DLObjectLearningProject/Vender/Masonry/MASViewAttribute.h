//
//  MASViewAttribute.h
//  Masonry
//
//  Created by Jonas Budelmann on 21/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import "MASUtilities.h"

/**
 *  An immutable tuple which stores the view and the related NSLayoutAttribute.
 *  Describes part of either the left or right hand side of a constraint equation
 *  存储视图和相关NSLayoutAttribute的不可变元组。
 *  描述约束方程的左侧或右侧的一部分
 */
@interface MASViewAttribute : NSObject

/**
 *  The view which the reciever relates to. Can be nil if item is not a view.
 *  关联reciever的视图
 */
@property (nonatomic, weak, readonly) MAS_VIEW *view;

/**
 *  The item which the reciever relates to.
 *  关联reciever的item
 */
@property (nonatomic, weak, readonly) id item;

/**
 *  The attribute which the reciever relates to
 *  关联reciever的约束属性
 */
@property (nonatomic, assign, readonly) NSLayoutAttribute layoutAttribute;

/**
 *  Convenience initializer.
 *  便捷初始化方法
 */
- (id)initWithView:(MAS_VIEW *)view layoutAttribute:(NSLayoutAttribute)layoutAttribute;

/**
 *  The designated initializer.
 *  指定的初始化方法
 */
- (id)initWithView:(MAS_VIEW *)view item:(id)item layoutAttribute:(NSLayoutAttribute)layoutAttribute;

/**
 *	Determine whether the layoutAttribute is a size attribute
 *  确定layoutAttribute是否为尺寸属性
 *  该方法用来判断MASViewAttribute类中的layoutAttribute属性是否是NSLayoutAttributeWidth或者NSLayoutAttributeHeight，如果是Width或者Height的话，那么约束就添加到当前View上，而不是添加在父视图上。
 *	@return	YES if layoutAttribute is equal to NSLayoutAttributeWidth or NSLayoutAttributeHeight
 */
- (BOOL)isSizeAttribute;

@end
