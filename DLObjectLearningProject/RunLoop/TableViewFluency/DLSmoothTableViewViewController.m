//
//  DLSmoothTableViewViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 21/12/2017.
//  Copyright © 2017 long deng. All rights reserved.
//

#import "DLSmoothTableViewViewController.h"
#import "UIViewController+HeavyTaskSimulateCategory.h"
#import "DWURunLoopWorkDistribution.h"

static NSString *IDENTIFIER = @"IDENTIFIER";
static CGFloat CELL_HEIGHT = 135.f;

@interface DLSmoothTableViewViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *exampleTableView;

@end

@implementation DLSmoothTableViewViewController

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 399;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //打印当前的runloop模式
    NSLog(@"current:%@",[NSRunLoop currentRunLoop].currentMode);
    
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:IDENTIFIER];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.currentIndexPath = indexPath;
    
    //cell加入了很多耗时任务，关键在于如何优化顺畅度
    [UIViewController task_5:cell indexPath:indexPath];
    [UIViewController task_1:cell indexPath:indexPath];
    [[DWURunLoopWorkDistribution sharedRunLoopWorkDistribution] addTask:^BOOL(void) {
        if (![cell.currentIndexPath isEqual:indexPath]) {
            return NO;
        }
        [UIViewController task_2:cell indexPath:indexPath];
        return YES;
    } withKey:indexPath];
    
    
    [[DWURunLoopWorkDistribution sharedRunLoopWorkDistribution] addTask:^BOOL(void) {
        if (![cell.currentIndexPath isEqual:indexPath]) {
            return NO;
        }
        [UIViewController task_3:cell indexPath:indexPath];
        return YES;
    } withKey:indexPath];
    
    
    [[DWURunLoopWorkDistribution sharedRunLoopWorkDistribution] addTask:^BOOL(void) {
        if (![cell.currentIndexPath isEqual:indexPath]) {
            return NO;
        }
        [UIViewController task_4:cell indexPath:indexPath];
        return YES;
    } withKey:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}


- (void)loadView {
    self.view = [UIView new];
    self.exampleTableView = [UITableView new];
    self.exampleTableView.delegate = self;
    self.exampleTableView.dataSource = self;
    [self.view addSubview:self.exampleTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.exampleTableView.frame = self.view.bounds;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.exampleTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:IDENTIFIER];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
