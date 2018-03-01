//
//  DLBooksViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 01/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import "DLBooksViewController.h"
#import "DLRequestViewModel.h"

@interface DLBooksViewController ()
@property(nonatomic, weak) UITableView *tableView;
@property(nonatomic, strong) DLRequestViewModel *requestModel;
@end

@implementation DLBooksViewController

- (DLRequestViewModel *)requestModel{
    if (!_requestModel) {
        _requestModel = [[DLRequestViewModel alloc] init];
    }
    return _requestModel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //创建tableView
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.dataSource = self.requestModel;
    [self.view addSubview:tableView];
    
    RACSignal *requestSignal = [self.requestModel.reqeustCommand execute:nil];
    //获取请求的数据
    [requestSignal subscribeNext:^(NSArray *_Nullable x) {
        self.requestModel.models = x;
        [self.tableView reloadData];
    }];
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
