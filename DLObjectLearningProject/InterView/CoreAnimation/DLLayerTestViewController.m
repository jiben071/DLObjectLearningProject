//
//  DLLayerTestViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 26/01/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  https://zsisme.gitbooks.io/ios-/content/chapter1/working-with-layers.html

#import "DLLayerTestViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface DLLayerTestViewController ()<CALayerDelegate>
@property (weak, nonatomic) IBOutlet UIView *layerView;
@property(nonatomic, weak) CALayer *blueLayer;

@property (weak, nonatomic) IBOutlet UIView *layerView1;
@property (weak, nonatomic) IBOutlet UIView *layerView2;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@end

@implementation DLLayerTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"图层相关学习";
    
    // Do any additional setup after loading the view.
//    [self drawingPicture];
    
//    [self addBluelayerTest];
    [self enablePathShadow];
    [self layerMasking];
    
    [self transparentHandle];
}

- (void)drawingPicture{
    //Snowman
    UIImage *image = [UIImage imageNamed:@"Snowman.png"];
    
    //add it directly to your view's layer
    self.layerView.layer.contents = (__bridge id)image.CGImage;
    self.layerView.layer.contentsGravity = kCAGravityCenter;
    //set the contentsScale to match image
    //如果contentsScale设置为1.0，将会以每个点1个像素绘制图片，如果设置为2.0，则会以每个点2个像素绘制图片，这就是我们熟知的Retina屏幕。
    //    self.layerView.layer.contentsScale = image.scale;
    //当用代码的方式来处理寄宿图的时候，一定要记住要手动的设置图层的contentsScale属性，否则，你的图片在Retina设备上就显示得不正确啦。
    self.layerView.layer.contentsScale = [UIScreen mainScreen].scale;
    self.layerView.layer.masksToBounds = YES;//裁剪边界
    
    
    //测试图层绘图
    [self customView];
}

- (void)addBluelayerTest{
    self.blueLayer = [CALayer layer];
    self.blueLayer.frame = CGRectMake(50.0f, 50.0f, 100.0f, 100.0f);
    self.blueLayer.backgroundColor = [UIColor blueColor].CGColor;
    //add it to our view
    [self.layerView.layer addSublayer:self.blueLayer];
}

- (void)addLayout{
    //Simple sample
    CALayer *blueLayer = [CALayer layer];
    blueLayer.frame = CGRectMake(50.0f, 50.0f, 100.0f, 100.0f);
    blueLayer.backgroundColor = [UIColor blueColor].CGColor;
    
    [self.layerView.layer addSublayer:blueLayer];
}

//使用layer进行绘图
- (void)customView {
    CALayer *blueLayer = [CALayer layer];
    blueLayer.frame = CGRectMake(50.0f, 50.0f, 100.0f, 100.0f);
    blueLayer.backgroundColor = [UIColor blueColor].CGColor;
    
    //set controller as layer delegate
    blueLayer.delegate = self;
    
    //ensure that layer backing image uses correct scale
    blueLayer.contentsScale = [UIScreen mainScreen].scale;//add layer to our view
    [self.layerView.layer addSublayer:blueLayer];
    
    //forse layer to redraw
    [blueLayer display];//将重汇的决定权交给了开发者
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx{
    CGContextSetLineWidth(ctx, 10.0f);
    CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
    CGContextStrokeEllipseInRect(ctx, layer.bounds);
}

- (void)coordinateTest{
    //不同坐标系转换处理
    /*
     - (CGPoint)convertPoint:(CGPoint)point fromLayer:(CALayer *)layer;
     - (CGPoint)convertPoint:(CGPoint)point toLayer:(CALayer *)layer;
     - (CGRect)convertRect:(CGRect)rect fromLayer:(CALayer *)layer;
     - (CGRect)convertRect:(CGRect)rect toLayer:(CALayer *)layer;
     */
    
    //2.翻转的几何结构 在iOS上通过设置它为YES意味着它的子图层将会被垂直翻转
    self.view.layer.geometryFlipped = YES;
    
    //3.Z坐标轴  改变图层顺序  move the view zPosition nearer to the camera
    self.view.layer.zPosition = 1.0f;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    [self convertPointWithLayer];
    [self hitTestFunction:touches];
}


/*
 注意当调用图层的-hitTest:方法时，测算的顺序严格依赖于图层树当中的图层顺序（和UIView处理事件类似）。之前提到的zPosition属性可以明显改变屏幕上图层的顺序，但不能改变事件传递的顺序。  也就是说：如果更改了Z轴来更改显示界面，但是点击事件不是依照看到的图层顺序进行传递，是依照原有的图层树顺序
 */
- (void)hitTestFunction:(NSSet<UITouch *> *)touches{
    //get touch position
    CGPoint point = [[touches anyObject] locationInView:self.view];
    //get touched layer
    CALayer *layer = [self.layerView.layer hitTest:point];
    //get layer using hitTest
    if (layer == self.blueLayer) {
        [[[UIAlertView alloc] initWithTitle:@"Inside Blue Layer"
                                    message:nil
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }else if(layer == self.layerView.layer){
        [[[UIAlertView alloc] initWithTitle:@"Inside White Layer"
                                    message:nil
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

//转化坐标系 使用containsPoint进行判断
- (void)convertPointWithLayer:(NSSet<UITouch *> *)touches{
    //get touch position relative to main view
    CGPoint point = [[touches anyObject] locationInView:self.view];
    //convert point to the white layer's corodinates
    point = [self.layerView.layer convertPoint:point fromLayer:self.view.layer];
    
    //get layer using containsPoint:
    if ([self.layerView.layer containsPoint:point]) {
        //convert point to blueLayer's coordinates
        point = [self.blueLayer convertPoint:point fromLayer:self.layerView.layer];
        if ([self.blueLayer containsPoint:point]) {
            [[[UIAlertView alloc] initWithTitle:@"Inside Blue Layer"
                                        message:nil
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }else{
            [[[UIAlertView alloc] initWithTitle:@"Inside White Layer"
                                        message:nil
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
    }
}

//使用路径来画阴影，可以提高性能
- (void)enablePathShadow{
//    self.layerView1.hidden = YES;
//    self.layerView2.hidden = YES;
    self.layerView1.layer.shadowOpacity = 0.5f;
    self.layerView2.layer.shadowOpacity = 0.5f;
    
    //create a square shadow
    CGMutablePathRef squarePath = CGPathCreateMutable();
    CGPathAddRect(squarePath, NULL, self.layerView1.bounds);
    self.layerView1.layer.shadowPath = squarePath;
    CGPathRelease(squarePath);
    
    //create a circle shadow
    CGMutablePathRef circlePath = CGPathCreateMutable();
    CGPathAddEllipseInRect(circlePath, NULL, self.layerView2.bounds);
    self.layerView2.layer.shadowPath = circlePath;
    CGPathRelease(circlePath);
}

//图层蒙版
/*
 CALayer蒙板图层真正厉害的地方在于蒙板图不局限于静态图。任何有图层构成的都可以作为mask属性，这意味着你的蒙板可以通过代码甚至是动画实时生成。
 */
- (void)layerMasking{
    //create mask layer
    CALayer *maskLayer = [CALayer layer];
    maskLayer.frame = self.imageView.bounds;
    UIImage *maskImage = [UIImage imageNamed:@"Cone"];
    maskLayer.contents = (__bridge id)maskImage.CGImage;
    
    //apply mask to image layer
    self.imageView.layer.mask = maskLayer;
    
}

- (UIButton *)customButton {
    //create button
    CGRect frame = CGRectMake(0, 0, 150, 50);
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    button.backgroundColor = [UIColor whiteColor];
    button.layer.cornerRadius = 10;
    
    //add label
    frame = CGRectMake(20, 10, 110, 30);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = @"Hello World";
    label.textAlignment = NSTextAlignmentCenter;
    [button addSubview:label];
    
    return button;
}

/*
 
 */
- (void)transparentHandle{
    //create opaque button
    UIButton *button1 = [self customButton];
    button1.center = CGPointMake(100, 30);
                      [self.containerView addSubview:button1];
    
    
    //create translucent button
    UIButton *button2 = [self customButton];
    button2.center = CGPointMake(300,30);
    button2.alpha = 0.5;
    [self.containerView addSubview:button2];
    
    //enable rasterization for the translucent button
    //如果UIViewGroupOpacity设置为YES，下面的两行代码就没有作用
//    button2.layer.shouldRasterize = YES;
//    button2.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

@end
