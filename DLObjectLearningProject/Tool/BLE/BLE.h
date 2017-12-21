// 核心的蓝牙类，实现了最底层的蓝牙连接的操作
//  Created by zhuzhuxia on 17/2/8.
//  Copyright © 2017年 zhuzhuxian All rights reserved.

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#define RBL_SERVICE_UUID                         "07303e62-cb70-38d8-8f5c-40c062145442"  //原值：2A39  改值：34e37817-8a36-325d-8bbc-24716c220aab
#define RBL_CHAR_TX_UUID                         "2A39"
#define RBL_CHAR_RX_UUID                         "2A39"

#define RBL_BLE_FRAMEWORK_VER                    0x0200
@protocol BLEDelegate

-(void) bleDidConnect;
-(void) bleDidDisconnect;
-(void) bleDidUpdateRSSI:(NSNumber *) rssi;
-(void) bleDidReceiveData:(NSData *) data length:(int) length;
-(void) didFoundDevice:(NSString *)deviceJson;

@end

@interface BLE : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate> {
//    NSString *deviceName;
    NSString *_deviceUUID;
}
@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) int              scanTimeOut;
@property (nonatomic, assign) int              isClickScan;
@property (strong, nonatomic) NSMutableArray *peripherals;
@property (strong, nonatomic) NSMutableArray *peripheralsRssi;
@property (strong, nonatomic) CBCentralManager *CM;
@property (strong, nonatomic) CBCharacteristic *writeCharacteristic;
@property (strong, nonatomic) CBCharacteristic *readCharacteristic;
@property (strong, nonatomic) CBPeripheral *activePeripheral;
@property (nonatomic, assign)  BOOL isBlueToothOpen;/**< 判断系统蓝牙是否已经打开 */


+ (id)shareInstance;

-(void) enableReadNotification:(CBPeripheral *)p;
-(void) read;
-(void) writeValue:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data;

-(BOOL) isConnected;
-(void) write:(NSData *)d;
-(void) readRSSI;
- (void) sendHexString:(NSString *)sendString;
- (void)readData;
-(void) controlSetup;
//停止扫描
- (void)stopScan;
//开始扫描BLE设备
-(void) connectPeripheralWithUUID:(NSString *)UUID;
-(void) disConnectPeripheralWithUUID:(NSString *)UUID;
-(int) scanBLEPeripherals:(int) timeout;
-(void) connectPeripheral:(CBPeripheral *)peripheral;

-(UInt16) swap:(UInt16) s;
-(const char *) centralManagerStateToString:(int)state;
-(void) scanTimer:(NSTimer *)timer;
-(void) printKnownPeripherals;
-(void) printPeripheralInfo:(CBPeripheral*)peripheral;

-(void) getAllServicesFromPeripheral:(CBPeripheral *)p;
-(void) getAllCharacteristicsFromPeripheral:(CBPeripheral *)p;
-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p;
-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service;

//-(NSString *) NSUUIDToString:(NSUUID *) UUID;
-(NSString *) CBUUIDToString:(CBUUID *) UUID;

-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2;
-(int) compareCBUUIDToInt:(CBUUID *) UUID1 UUID2:(UInt16)UUID2;
-(UInt16) CBUUIDToInt:(CBUUID *) UUID;
-(BOOL) UUIDSAreEqual:(NSUUID *)UUID1 UUID2:(NSUUID *)UUID2;

@end
