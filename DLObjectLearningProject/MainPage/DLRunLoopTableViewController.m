//
//  DLRunLoopTableViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 21/12/2017.
//  Copyright © 2017 long deng. All rights reserved.
//

#import "DLRunLoopTableViewController.h"
#import "DLObjectLearningProject-Swift.h"

@interface DLRunLoopTableViewController ()
@property (weak, nonatomic) IBOutlet UIButton *smoothProcessBtn;

@end

@implementation DLRunLoopTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



//进入到swift版本的流畅度提升控制器
- (IBAction)jumpToSmoothProcessAction:(id)sender {
    DLSmoothTableViewSwiftVC *vc = [DLSmoothTableViewSwiftVC new];
    [self.navigationController pushViewController:vc animated:YES];
}


@end
