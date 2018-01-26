//
//  DLLayerTestViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 26/01/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  https://zsisme.gitbooks.io/ios-/content/chapter1/working-with-layers.html

#import "DLLayerTestViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface DLLayerTestViewController ()
@property (weak, nonatomic) IBOutlet UIView *layerView;

@end

@implementation DLLayerTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
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
    
    
}

- (void)addLayout{
    //Simple sample
    CALayer *blueLayer = [CALayer layer];
    blueLayer.frame = CGRectMake(50.0f, 50.0f, 100.0f, 100.0f);
    blueLayer.backgroundColor = [UIColor blueColor].CGColor;
    
    [self.layerView.layer addSublayer:blueLayer];
    

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
