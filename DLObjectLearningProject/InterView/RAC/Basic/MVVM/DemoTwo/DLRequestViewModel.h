//
//  DLRequestViewModel.h
//  DLObjectLearningProject
//
//  Created by denglong on 01/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>

@interface DLRequestViewModel : NSObject<UITableViewDataSource>
//请求命令
@property(nonatomic, strong) RACCommand *reqeustCommand;
//模型数组
@property(nonatomic, strong) NSArray *models;
@end
