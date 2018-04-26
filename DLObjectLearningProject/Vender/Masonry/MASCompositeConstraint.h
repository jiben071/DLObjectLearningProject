//
//  MASCompositeConstraint.h
//  Masonry
//
//  Created by Jonas Budelmann on 21/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import "MASConstraint.h"
#import "MASUtilities.h"

/**
 *	A group of MASConstraint objects
 *  一组约束对象
 *  从MASCompositeConstraint的命名中我们就可以看出来MASCompositeConstraint是约束的一个组合，也就是其中存储的是一系列的约束。MASCompositeConstraint类的结构比较简单，其核心就是一个存储MASViewConstraint对象的数组，MASCompositeConstraint就是对该数组的一个封装而已。
 */
@interface MASCompositeConstraint : MASConstraint

/**
 *	Creates a composite with a predefined array of children
 *
 *	@param	children	child MASConstraints
 *
 *	@return	a composite constraint
 */
- (id)initWithChildren:(NSArray *)children;

@end
