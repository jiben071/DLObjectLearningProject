//
//  DLTransformViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 02/02/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import "DLTransformViewController.h"

@interface DLTransformViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *layerOne;
@property (weak, nonatomic) IBOutlet UIImageView *layerTwo;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet UIView *outerLayer;
@property (weak, nonatomic) IBOutlet UIView *innerLayer;

@end

@implementation DLTransformViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    [self testTransform];
//    [self recombinationTransform];
//    [self transform3DTest];
//    [self applyPerspective];
//    [self unifySettingPerspective];
//    [self flatTest];
    [self flatTest2];
}

- (void)testTransform {
    //rotate the layer 45 degree
    CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_4);
    self.imageView.layer.affineTransform = transform;
}

//注意：上一个变换的结果将会影响之后的变换，所以更改顺序可能会导致结果不一样
- (void)recombinationTransform {
    //create a new transform
    CGAffineTransform transform = CGAffineTransformIdentity;
    //scale by 50%
    transform = CGAffineTransformScale(transform, 0.5, 0.5);
    //rotate by 30 degrees
    transform = CGAffineTransformRotate(transform, M_PI / 180.0 * 30.0);
    //tranlate by 200 points
    transform = CGAffineTransformTranslate(transform, 200, 0);
    //apply transform to layer
    self.imageView.layer.affineTransform = transform;
}

- (void)transform3DTest {
    //rotate the layer 45 degrees along the Y axis
    CATransform3D transform = CATransform3DMakeRotation(M_PI_4, 0, 1, 0);
    self.imageView.layer.transform = transform;
}

/*
 注意：
 当改变一个图层的position，你也改变了它的灭点，做3D变换的时候要时刻记住这一点，当你视图通过调整m34来让它更加有3D效果，应该首先把它放置于屏幕中央，然后通过平移来把它移动到指定位置（而不是直接改变它的position），这样所有的3D图层都共享一个灭点。
 */
- (void)applyPerspective{
    //create a new transform
    CATransform3D transform = CATransform3DIdentity;
    //applly perspective
    transform.m34 = -1.0 / 500.0;
    //rotate by 45 degrees along the Y axis
    transform = CATransform3DRotate(transform, M_PI_4, 0, 1, 0);
    //apply to layer
    self.imageView.layer.transform = transform;
}

- (void)unifySettingPerspective{
    //apply perspective transform to container
    CATransform3D perspective = CATransform3DIdentity;
    perspective.m34 = - 1.0 / 500.0f;
    self.containerView.layer.sublayerTransform = perspective;
    //rotate layerView1 by 45 degrees along the Y axis
    CATransform3D transform1 = CATransform3DMakeRotation(M_PI_4, 0, 1, 0);
    self.layerOne.layer.transform = transform1;
    
    //roate layerView2 by 45 degrees along the Y axis
    CATransform3D transform2 = CATransform3DMakeRotation(M_PI, 0, 1, 0);
    self.layerTwo.layer.transform = transform2;
    //self.layerTwo.layer.doubleSided = NO;//CALayer有一个叫做doubleSided的属性来控制图层的背面是否要被绘制。这是一个BOOL类型，默认为YES，如果设置为NO，那么当图层正面从相机视角消失的时候，它将不会被绘制。
}

- (void)flatTest{
    //rotate the outer layer 45 degree
    CATransform3D outer = CATransform3DMakeRotation(M_PI_4, 0, 0, 1);
    self.outerLayer.layer.transform = outer;
    
    //rotate the inner layer -45 degrees
//    CATransform3D inner = CATransform3DMakeRotation(-M_PI_4, 0, 0, 1);
//    self.innerLayer.layer.transform = inner;
}

- (void)flatTest2 {
    //rotate the outer layer 45 degrees
    CATransform3D outer = CATransform3DIdentity;
    outer.m34 = -1.0 / 500.0;
    outer = CATransform3DRotate(outer, M_PI_4, 0, 1, 0);
    self.outerLayer.layer.transform = outer;
    
    //rotate ther inner layer -45 degrees
    CATransform3D inner = CATransform3DIdentity;
    inner.m34 = - 1.0 /500;
    inner = CATransform3DRotate(inner, -M_PI_4, 0, 1, 0);
    self.innerLayer.layer.transform = inner;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
