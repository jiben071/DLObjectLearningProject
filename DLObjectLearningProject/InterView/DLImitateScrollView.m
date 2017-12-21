//
//  DLImitateScrollView.m
//  DLObjectLearningProject
//
//  Created by long deng on 2017/12/20.
//  Copyright © 2017年 long deng. All rights reserved.
//  好像有点失败，需要再调试

#import "DLImitateScrollView.h"

@implementation DLImitateScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGesture:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)awakeFromNib{
    [super awakeFromNib];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGesture:)];
    [self addGestureRecognizer:pan];
}

- (void)panGesture:(UIPanGestureRecognizer *)gestureRecognizer{
    //改变bounds
    CGPoint transition = [gestureRecognizer translationInView:self];
    CGRect bounds = self.bounds;
    
    CGFloat newBoundsOrignX = bounds.origin.x - transition.x;
    CGFloat minBoundsOriginX = 0.0;
    CGFloat maxBoundsOriginX = self.contentSize.width - bounds.size.width;
    bounds.origin.x = fmax(minBoundsOriginX, fmin(newBoundsOrignX, maxBoundsOriginX));
    
    CGFloat newBoundsOriginY = bounds.origin.y - transition.y;
    CGFloat minBoundsOriginY = 0.0;
    CGFloat maxBoundsOriginY = self.contentSize.height - bounds.size.height;
    bounds.origin.y = fmax(minBoundsOriginY, fmin(newBoundsOriginY, maxBoundsOriginY));
    
    self.bounds = bounds;
    [gestureRecognizer setTranslation:CGPointZero inView:self];
}



@end
