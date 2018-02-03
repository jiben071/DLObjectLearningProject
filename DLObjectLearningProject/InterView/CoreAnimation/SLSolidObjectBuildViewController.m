//
//  SLSolidObjectBuildViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 03/02/2018.
//  Copyright © 2018 long deng. All rights reserved.
//
#import "SLSolidObjectBuildViewController.h"


#import <QuartzCore/QuartzCore.h>
#import <GLKit/GLKit.h>

#define LIGHT_DIRECTION 0,1,-0.5
#define AMBIENT_LIGHT 0.5

@interface SLSolidObjectBuildViewController ()
@property(nonatomic, strong) IBOutletCollection(UIView) NSArray *faces;
@property(nonatomic, weak) IBOutlet UIView *containerView;
@end

@implementation SLSolidObjectBuildViewController


//妈了个蛋蛋的，这段代码没有生效  作用是：给立方体产生光影，形成最终的立体效果
- (void)applyLightingToFace:(CALayer *)face{
    //add lighting layer
    CALayer *layer = [CALayer layer];
    layer.frame = face.bounds;
    [face addSublayer:layer];
    
    //convert face transform to matrix
    //(GLKMatrix4 has the same structure as CATransform3D)
    CATransform3D transform = face.transform;
    GLKMatrix4 matrix4 = *(GLKMatrix4 *)&transform;
    GLKMatrix3 matrix3 = GLKMatrix4GetMatrix3(matrix4);
    
    //get face normal
    GLKVector3 normal = GLKVector3Make(0, 0, 1);
    normal = GLKMatrix3MultiplyVector3(matrix3, normal);
    normal = GLKVector3Normalize(normal);
    
    //get dot product with light direction
    GLKVector3 light = GLKVector3Normalize(GLKVector3Make(LIGHT_DIRECTION));
    float dotProduct = GLKVector3DotProduct(light, normal);
    
    //set lighting layer opacity
    CGFloat shadow = 1 + dotProduct - AMBIENT_LIGHT;
    UIColor *color = [UIColor colorWithWhite:0 alpha:shadow];
    layer.backgroundColor = color.CGColor;
}

- (void)addFace:(NSInteger)index withTransform:(CATransform3D)transform {
    //get the face view and add it to the container
    UIView *face = self.faces[index];
    [self.containerView addSubview:face];
    
    //center the face view within the container
    CGSize containerSize = self.containerView.bounds.size;
    face.center = CGPointMake(containerSize.width * 0.5, containerSize.height * 0.5);
    
    //apply the tranform
    face.layer.transform = transform;
    
    //apply lighting
    [self applyLightingToFace:face.layer];
}

- (void)addPersperctive:(UIView *)face{
    CATransform3D perspective = CATransform3DIdentity;
    perspective.m34 = -1.0 / 500.0;
//    perspective = CATransform3DRotate(perspective, -M_PI_4, 1, 0, 0);
//    perspective = CATransform3DRotate(perspective, -M_PI_4, 0, 1, 0);
    face.layer.sublayerTransform = perspective;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //添加一个立方体
//    [self setUpSolidObject];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setUpSolidObject];
}

- (void)setUpSolidObject{
    //set up thecontainer sublayer transform
    CATransform3D perspective = CATransform3DIdentity;
    perspective.m34 = -1.0 / 500.0;
    perspective = CATransform3DRotate(perspective, -M_PI_4, 1, 0, 0);
    perspective = CATransform3DRotate(perspective, -M_PI_4, 0, 1, 0);
    self.containerView.layer.sublayerTransform = perspective;
    
    //add cube face 1
    CATransform3D transform = CATransform3DMakeTranslation(0, 0, 50);
    [self addFace:0 withTransform:transform];
    
    //add cube face 2
    transform = CATransform3DMakeTranslation(50, 0, 0);
    transform = CATransform3DRotate(transform, M_PI_2, 0, 1, 0);
    [self addFace:1 withTransform:transform];
    
    //add cube face 3
    transform = CATransform3DMakeTranslation(0, -50, 0);
    transform = CATransform3DRotate(transform, M_PI_2, 1, 0, 0);
    [self addFace:2 withTransform:transform];
    
    //add cube face 4
    transform = CATransform3DMakeTranslation(0, 50, 0);
    transform = CATransform3DRotate(transform, -M_PI_2, 1, 0, 0);
    [self addFace:3 withTransform:transform];
    
    //add cube face 5
    transform = CATransform3DMakeTranslation(-50, 0, 0);
    transform = CATransform3DRotate(transform, -M_PI_2, 0, 1, 0);
    [self addFace:4 withTransform:transform];
    
    //add cube face 6
    transform = CATransform3DMakeTranslation(0, 0, -50);//沿着Z轴下沉
    transform = CATransform3DRotate(transform, M_PI, 0, 1, 0);
    [self addFace:5 withTransform:transform];
    
}

@end
