//
//  HeartBeat.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/8/23.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HeartBeat : NSObject

@property (nonatomic, assign) long differInterval;

//开始心跳
-(void)startHeartBeat;
//结束心跳
-(void)destoryHeartBeat;
//判断是否是心跳回复
-(BOOL)isRecvedPong:(NSData *)data;
//更新接收数据的时间
-(void)updateReceiveTime;

@end
