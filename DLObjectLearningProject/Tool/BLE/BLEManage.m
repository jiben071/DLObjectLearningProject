
//  Created by zhuzhuxian on 2017/2/10.
//  Copyright © 2017年 zhuzhuxian. All rights reserved.
//

#import "BLEManage.h"
#import "BLE.h"

@interface BLEManage()<BLEDelegate>
{
    NSString *_deviceUUID;
}

@property(nonatomic, strong) CompletionDataBlock myCompletionBlock;
@property(nonatomic, strong) CompletionBlock scanCompletionBlock;
@property(nonatomic, strong) CompletionDataBlock connectCompletionBlock;
@property(nonatomic, strong) CompletionResultBlock dataCompletionBlock;

@property (nonatomic,strong) NSMutableDictionary *blockDictionary;/**< 保存对应命令号的block回调 */
@end

@implementation BLEManage

- (NSMutableDictionary *)blockDictionary{
    if (!_blockDictionary) {
        _blockDictionary = [NSMutableDictionary dictionary];
    }
    return _blockDictionary;
}

- (BOOL)isBlueToothOpen{
    BLE *bleShield=[BLE shareInstance];
    return bleShield.isBlueToothOpen;
}

- (BOOL)isConnected{
    BLE *bleShield=[BLE shareInstance];
    return bleShield.isConnected;
}

#if 1
+ (id)shareInstance
{
    
    static BLEManage    *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BLEManage alloc] init];
    });
    return instance;
    
}

#else
static BLEManage *sharedManage = nil; //第一步：静态实例，并初始化。

+ (id)shareInstance
{
    @synchronized(self) {
        if (!sharedManage) {
            sharedManage = [[BLEManage alloc] init];
        }
    }
    return sharedManage;
}

#endif



-(void)autoScanDeviceWithTimeOut:(int)timeout   completion:(CompletionBlock)completionBlock
{
    if (timeout>0)
    {
        [self performSelector:@selector(scanTimeout) withObject:nil afterDelay:timeout];
    }
    
    _scanCompletionBlock=completionBlock;
    BLE *bleShield=[BLE shareInstance];
    bleShield.isClickScan=1;
    bleShield.scanTimeOut=timeout;
    bleShield.delegate=self;
    if (bleShield.activePeripheral)
    {
        if(bleShield.activePeripheral.state == CBPeripheralStateConnected)
        {
            [[bleShield CM] cancelPeripheralConnection:[bleShield activePeripheral]];
        }
    }
    [bleShield scanBLEPeripherals:timeout];
    
}

- (void)stopScan{
    [self scanTimeout];
}

-(void)didFoundDevice:(NSString *)deviceJson
{
    if (_scanCompletionBlock)
    {
        _scanCompletionBlock(nil,deviceJson);
    }
}
-(void)scanTimeout
{
    BLE *bleShield=[BLE shareInstance];
    [bleShield stopScan];
    
}

-(void)connectBLEWithUUID:(NSString *)UUID   completion:(CompletionDataBlock)completionBlock
{
    self.isInitiativeDisconnect = NO;
    _deviceUUID = UUID;
    _connectCompletionBlock=completionBlock;
    BLE *bleShield=[BLE shareInstance];
    bleShield.delegate=self;
    [bleShield connectPeripheralWithUUID:UUID];
}

-(void)disConnectBLEWithUUID:(NSString *)UUID   completion:(CompletionDataBlock)completionBlock
{
    self.isInitiativeDisconnect = YES;
    _connectCompletionBlock=completionBlock;
    BLE *bleShield=[BLE shareInstance];
    bleShield.delegate=self;
    [bleShield disConnectPeripheralWithUUID:UUID];
    
}

-(void) bleDidConnect
{
    if (_connectCompletionBlock) {
        _connectCompletionBlock(nil,[@"DidConnect" dataUsingEncoding:NSUTF8StringEncoding]);
        _connectCompletionBlock = NULL;//回调一次，便停止回调
    }
}
-(void) bleDidDisconnect{
    //0.发出蓝牙已断开连接通知
    NSLog(@"蓝牙连接断开的消息");
    
    if (!self.isBlueToothOpen) {
        return;
    }
    
    [[BLE shareInstance] disConnectPeripheralWithUUID:_deviceUUID];//不做自动重连
    
    if (_connectCompletionBlock) {
        _connectCompletionBlock(nil,[@"DidDisconnect" dataUsingEncoding:NSUTF8StringEncoding]);
        _connectCompletionBlock = NULL;//回调一次，便停止回调
    }
    
}

//发送数据
-(void)sendDataToBLEWithUUID:(NSString *)UUID  keyID:(NSString *)keyID dataString:(NSString *)dataStr  completion:(CompletionResultBlock)completionBlock{
    _dataCompletionBlock=completionBlock;
    [self.blockDictionary setObject:completionBlock forKey:keyID];
    BLE *bleShield=[BLE shareInstance];
    bleShield.delegate=self;
    [bleShield sendHexString:dataStr];
}
//读取数据
-(void)readWIFIFromBLEWithUUID:(NSString *)UUID  dataString:(NSString *)dataStr  completion:(CompletionResultBlock)completionBlock{
    _dataCompletionBlock=completionBlock;
    BLE *bleShield=[BLE shareInstance];
    bleShield.delegate=self;
    [bleShield readData];
}


-(void) bleDidUpdateRSSI:(NSNumber *) rssi{
    
}

-(void) bleDidReceiveData:(NSData *) data length:(int) length{
    //在这里抛出去
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];  
}

-(void)setBlock:(CompletionDataBlock)completionBlock
{
    if (completionBlock)
    {
        _myCompletionBlock=completionBlock;
    }
    
}
@end


@implementation BlueTooth


@end

