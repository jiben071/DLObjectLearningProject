//
//  DLCommandPatternViewController.m
//  DLObjectLearningProject
//
//  Created by long deng on 2018/4/26.
//  Copyright © 2018年 long deng. All rights reserved.
//

#import "DLCommandPatternViewController.h"
#import "Receiver.h"
#import "CommandHelper.h"
#import "Invoker.h"

//实际需要实现的业务逻辑：通过两个按钮调整界面视图的明暗程度，外加一个按钮设置回退操作


typedef enum : NSUInteger {
    hAddButtonTag = 0x11,
    hDelButtonTag,
    hRolButtonTag,
} ViewControllerEnumValue;

@interface DLCommandPatternViewController ()
/** 接受者，执行任务者 */
@property (nonatomic,strong) Receiver *receiver;

/** 命令的调用者或者容器，好比遥控器 */
@property (nonatomic,strong) Invoker *invoker;
@end

@implementation DLCommandPatternViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //画出三个按钮
    //调亮按钮 +
    UIButton* addBtn = [self addButtonWithTitle:@"+"
                                      withFrame:CGRectMake(30, 30, 40, 40)
                                     withAction:@selector(buttonsEvent:)
                                        withTag:hAddButtonTag];
    [self.view addSubview:addBtn];
    //调暗按钮 -
    UIButton* delBtn = [self addButtonWithTitle:@"-"
                                      withFrame:CGRectMake(100, 30, 40, 40)
                                     withAction:@selector(buttonsEvent:)
                                        withTag:hDelButtonTag];
    [self.view addSubview:delBtn];
    //撤销操作按钮
    UIButton* rolBtn = [self addButtonWithTitle:@"RoolBack"
                                      withFrame:CGRectMake(170, 30, 100, 40)
                                     withAction:@selector(buttonsEvent:)
                                        withTag:hRolButtonTag];
    [self.view addSubview:rolBtn];
    
    self.receiver = [[Receiver alloc] init];
    [self.receiver setClientView:self.view];
}


-(void)buttonsEvent:(UIButton*)btn{
    if (btn.tag == hAddButtonTag) {
        
        LighterCommand* lighterCommand = [[LighterCommand alloc] initWithReceiver:self.receiver withParamter:0.1f];
        self.invoker = [[Invoker alloc] init];
        [self.invoker addExcute:lighterCommand];
        
    }else if (btn.tag == hDelButtonTag){
        
        DarkerCommand* darkerCommand = [[DarkerCommand alloc] initWithReceiver:self.receiver withParamter:0.1f];
        self.invoker = [[Invoker alloc] init];
        [self.invoker addExcute:darkerCommand];
        
    }else if (btn.tag == hRolButtonTag){
        
        [self.invoker rollBack];
        
    }
}

#pragma mark - 添加同类按钮的方法
//增加相同按钮的方法相同，所以抽离出来
-(UIButton*)addButtonWithTitle:(NSString*)title withFrame:(CGRect)frame withAction:(SEL)sel withTag:(ViewControllerEnumValue)tag{
    UIButton* btn = [[UIButton alloc] initWithFrame:frame];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btn setTitle:@"🐶" forState:UIControlStateHighlighted];
    btn.layer.borderWidth = 1.0f;
    [btn addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    [btn setTag:tag];
    return btn;
}

@end
