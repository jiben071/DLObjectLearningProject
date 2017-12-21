//  在BLE基础上的封装，屏蔽了底层的蓝牙连接，主要添加了回调功能
//  Created by zhuzhuxian on 2017/2/10.
//  Copyright © 2017年 zhuzhuxian. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^CompleBlock)(NSError* error, NSData *responseData,NSString *uuid);
typedef void (^CompletionDataBlock)(NSError* error, NSData *responseData);
typedef void (^CompletionResultBlock)(int command, id responseObject);
typedef void (^CompletionBlock)(NSError* error, NSString *response);
@interface BLEManage : NSObject

@property (nonatomic,assign) BOOL isBlueToothOpen;/**< 判断蓝牙是否已经开启 */
@property (nonatomic,assign) BOOL isConnected;/**< 判断是否已经连接了某一个蓝牙设备 */
@property (nonatomic,assign) BOOL isInitiativeDisconnect;/**< 判断是否主动断连 */

+ (id)shareInstance;

//自动搜索设备 无弹出框  timeout  秒 0代表一直扫描
-(void)autoScanDeviceWithTimeOut:(int)timeout   completion:(CompletionBlock)completionBlock;
//停止扫描
-(void)stopScan;
//连接设备
-(void)connectBLEWithUUID:(NSString *)UUID   completion:(CompletionDataBlock)completionBlock;
//断开设备
-(void)disConnectBLEWithUUID:(NSString *)UUID   completion:(CompletionDataBlock)completionBlock;

//发送数据
-(void)sendDataToBLEWithUUID:(NSString *)UUID  keyID:(NSString *)keyID dataString:(NSString *)dataStr  completion:(CompletionResultBlock)completionBlock;
//读取WIFI数据
-(void)readWIFIFromBLEWithUUID:(NSString *)UUID  dataString:(NSString *)dataStr  completion:(CompletionResultBlock)completionBlock;


@end

@interface BlueTooth : NSObject
@property (nonatomic, copy) NSString *name;/**< 蓝牙名称 */
@property (nonatomic, copy) NSString *uuid;/**< 蓝牙UUID */
@property (nonatomic, copy) NSString *rssi;/**< 信号强度 */
@property (nonatomic, copy) NSString *serial;/**< 设备序列号 */
@property (nonatomic, copy) NSString *distance;/**< 距离 */
@end


/*
 调用例子
 //扫描
 [_deviceArray removeAllObjects];
 [self.tableView reloadData];
 [[BLEManage shareInstance] autoScanDeviceWithTimeOut:20 completion:^(NSError *error,NSString *responsString)
 {
 NSString *jsonString = responsString;
 NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
 NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
 
 [_deviceArray addObject:json];
 
 [self.tableView reloadData];
 }];
 
 //连接设备
 -(void)connectDevice
 {
 [[BLEManage shareInstance] connectBLEWithUUID:self.uuidString completion:^(NSError *error,NSData *data){
 
 if (!error)
 {
 NSLog(@"data=%@",data);
 }
 [self hiddenHUD];
 }];
 
 }
 //发送
 -(void)send
 {
 [[BLEManage shareInstance] sendDataToBLEWithUUID:self.uuidString dataString:sendTextField.text  completion:^(NSError *error,NSData *data)
 {
 if(!error )
 NSLog(@"发送成功");
 }];
 }
 //读取
 -(void)read
 {
 [[BLEManage shareInstance] readWIFIFromBLEWithUUID:self.uuidString dataString:nil  completion:^(NSError *error,NSData *data)
 {
 if(!error )
 {
 NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
 NSLog(@"收到数据222= %@", s);
 }
 }];
 }

 */
