//
//  DLHollowOutTextViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 13/04/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  镂空文字处理
//  https://blog.csdn.net/allangold/article/details/53199819

#import "DLHollowOutTextViewController.h"

@interface DLHollowOutTextViewController ()

@end

@implementation DLHollowOutTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

/*
 实现起来也很简单,主要分3个步骤:
 
 1.创建一个镂空的路径:
 
 　　UIBezierPath 有个原生的方法- (void)appendPath:(UIBezierPath *)bezierPath, 这个方法作用是俩个路径有叠加的部分则会镂空.
 
 　　这个方法实现原理应该是path的FillRule 默认是FillRuleEvenOdd(CALayer 有一个fillRule属性的规则就有kCAFillRuleEvenOdd),
 而EvenOdd 是一个奇偶规则,奇数则显示,偶数则不显示.叠加则是偶数故不显示.
 
 2.创建CAShapeLayer 将镂空path赋值给shapeLayer
 
 3.将shapeLayer 设置为背景视图的Mask
 */
#pragma mark - 镂空文字
- (void)hollowOutText{
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.frame = self.view.bounds;
    backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    [self.view addSubview:backgroundView];
    
    //创建一个全屏大的path
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.view.bounds];
    
    //创建一个圆形path
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.view.center.x, self.view.center.y - 25) radius:50 startAngle:0 endAngle:2 * M_PI clockwise:NO];
    
    [path appendPath:circlePath];//作用是俩个路径有叠加的部分则会镂空.
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = path.CGPath;
    backgroundView.layer.mask = shapeLayer;
    
    
    /*
     顺便提下,在实际开发中可能遇到这种需求,当tableView 滑动到某个位置的时候才显示新手引导.
     
     这时候就需要将tableView上的坐标转化为相对于屏幕的坐标.  可用原生的方法:
     
     - (CGRect)convertRect:(CGRect)rect toView:(nullable UIView *)view;
     - (CGRect)convertRect:(CGRect)rect fromView:(nullable UIView *)view;
     
     渐变进度条：
     参考：http://www.cnblogs.com/gardenLee/archive/2016/04/09/5371377.html
     */
    
}


/*
 Mask 英文解释是蒙板/面罩,平时我们称为蒙层. 在苹果官方文档里如下图,意思是Mask是一个可选的Layer,它可以是根据透明度来掩盖Layer的内容.
 Layer的透明度决定了Layer内容是否可以显示,非透明的内容和背景可以显示,透明的则无法显示.
 */
#pragma mark - Mask属性
- (void)maskTest{
    //渐变色进度条
    //1.创建一个CALayer作为背景色进度条
    CALayer *bgLayer = [CALayer layer];
    bgLayer.frame = CGRectMake(<#CGFloat x#>, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)
}

@end
