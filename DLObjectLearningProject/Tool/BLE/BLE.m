
//  Created by zhuzhuxian on 17/2/8.
//  Copyright © 2017年 zhuzhuxian All rights reserved.

#import "BLE.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//#import "NSString+XEP_0106.h"

#define Lynx_UUID   @"2A39"
#define SERVICE_UUID @"07303e62-cb70-38d8-8f5c-40c062145442"

@interface BLE(){
   NSMutableData *_receiveData;//装载收到的字节流
}
@property (strong, nonatomic) NSData                    *dataToSend;
@property (nonatomic, assign) NSInteger              sendDataIndex;

@end
@implementation BLE


@synthesize CM;
@synthesize peripherals;
@synthesize peripheralsRssi;
@synthesize activePeripheral;

static bool isConnected = NO;
static int rssi = 0;

+ (id)shareInstance{
    static BLE	*instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BLE alloc] init];
    });
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _receiveData = [[NSMutableData alloc] init];
    }
    return self;
}

-(void) readRSSI{
    [activePeripheral readRSSI];
}

-(BOOL) isConnected{
    return isConnected;
}

-(void) read{
    CBUUID *uuid_service = [CBUUID UUIDWithString:@RBL_SERVICE_UUID];
    CBUUID *uuid_char = [CBUUID UUIDWithString:@RBL_CHAR_TX_UUID];
    
    [self readValue:uuid_service characteristicUUID:uuid_char p:activePeripheral];
}

-(void) write:(NSData *)d{
    CBUUID *uuid_service = [CBUUID UUIDWithString:@RBL_SERVICE_UUID];
    CBUUID *uuid_char = [CBUUID UUIDWithString:@RBL_CHAR_RX_UUID];
    
    [self writeValue:uuid_service characteristicUUID:uuid_char p:activePeripheral data:d];
}

-(void) enableReadNotification:(CBPeripheral *)p{
    CBUUID *uuid_service = [CBUUID UUIDWithString:@RBL_SERVICE_UUID];
    CBUUID *uuid_char = [CBUUID UUIDWithString:@RBL_CHAR_TX_UUID];
    
    [self notification:uuid_service characteristicUUID:uuid_char p:p on:YES];
}

-(void) notification:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on{
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];
    
    if (!service){
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);
        
        return;
    }
    
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];
    
    if (!characteristic){
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:characteristicUUID],
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);
        
        return;
    }
    
    [p setNotifyValue:on forCharacteristic:characteristic];
}

-(UInt16) frameworkVersion{
    return RBL_BLE_FRAMEWORK_VER;
}

-(NSString *) CBUUIDToString:(CBUUID *) cbuuid;{
    NSData *data = cbuuid.data;
    
    if ([data length] == 2)
    {
        const unsigned char *tokenBytes = [data bytes];
        return [NSString stringWithFormat:@"%02x%02x", tokenBytes[0], tokenBytes[1]];
    }
    else if ([data length] == 16)
    {
        NSUUID* nsuuid = [[NSUUID alloc] initWithUUIDBytes:[data bytes]];
        return [nsuuid UUIDString];
    }
    
    return [cbuuid description];
}

-(void) readValue: (CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p{
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];
    
    if (!service){
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);
        
        return;
    }
    
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];
    
    if (!characteristic){
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:characteristicUUID],
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);
        
        return;
    }
    
    [p readValueForCharacteristic:characteristic];
}

-(void) writeValue:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data{
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];
    
    if (!service){
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);
        
        return;
    }
    
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];
    
    if (!characteristic){
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:characteristicUUID],
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);
        
        return;
    }
    
    [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
}

-(UInt16) swap:(UInt16)s
{
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

- (void) controlSetup
{
//    deviceName=@"Galaxy C5";
    //deviceName=@"魅蓝 note 2";
    //deviceName=@"ubt172";
    if (self.CM) {
        self.CM=nil;
    }
    // 1.创建中央设备管理器
    self.CM = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

UInt16 const START_BYTE    = 0x01;
UInt16 const CONTINUE_BYTE = 0x02;
UInt16 const END_BYTE      = 0x00;

- (void) sendHexString:(NSString *)sendString
{
    NSData *sendData = [sendString dataUsingEncoding:NSUTF8StringEncoding];
    
    if (self.writeCharacteristic)
    {
        // [self.activePeripheral writeValue:[sendString dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
        //[self.activePeripheral readValueForCharacteristic:self.writeCharacteristic];
        // [self.accessibilityValue setno];
        
        [self.activePeripheral setNotifyValue:YES forCharacteristic:self.writeCharacteristic];
        [self.activePeripheral readValueForCharacteristic:self.writeCharacteristic];
        
        // [self writeLongData:[sendString dataUsingEncoding:NSUTF8StringEncoding] peripheral:self.activePeripheral characteristic:self.writeCharacteristic];
        
        [self sendPackageData:sendData
                   peripheral:self.activePeripheral
                    character:self.writeCharacteristic];
    }
    else{
        NSLog(@"self.writeCharacteristic 为空");
    }

    
}

#define BLE_SEND_MAX_LEN 18

- (void)sendPackageData:(NSData *)pocketData
             peripheral:(CBPeripheral *)peripheral
              character:(CBCharacteristic *)characteristic
{
#if 1
    if (pocketData.length <= BLE_SEND_MAX_LEN) {
        
        UInt16 flag = END_BYTE;
        NSMutableData *flagData = [NSMutableData dataWithBytes:&flag length:1];
        [flagData appendData:pocketData];
        [peripheral writeValue:flagData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];//CBCharacteristicWriteWithoutResponse
        
    }else if (pocketData.length <= 2 * BLE_SEND_MAX_LEN && pocketData.length > BLE_SEND_MAX_LEN){
        
        //第一次发送
        UInt16 start_flag = START_BYTE;
        NSMutableData *start_flagData = [NSMutableData dataWithBytes:&start_flag length:1];
        NSData *start_subData = [pocketData subdataWithRange:NSMakeRange(0, BLE_SEND_MAX_LEN)];
        
        [start_flagData appendData:start_subData];
        
        [peripheral writeValue:start_flagData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];//CBCharacteristicWriteWithoutResponse
        
        sleep(0.2);
        
        //第二次发送
        UInt16 end_flag = END_BYTE;
        NSMutableData *end_flagData = [NSMutableData dataWithBytes:&end_flag length:1];
        NSData *end_subData = [pocketData subdataWithRange:NSMakeRange(BLE_SEND_MAX_LEN,pocketData.length - BLE_SEND_MAX_LEN)];
        
        [end_flagData appendData:end_subData];
        
        [peripheral writeValue:end_flagData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];//CBCharacteristicWriteWithoutResponse
        
    }else{
        
        //第一次发送
        NSInteger firstlength = BLE_SEND_MAX_LEN;
        UInt16 start_flag = START_BYTE;
        NSMutableData *start_flagData = [NSMutableData dataWithBytes:&start_flag length:1];
        NSData *start_subData = [pocketData subdataWithRange:NSMakeRange(0, firstlength)];
        
        [start_flagData appendData:start_subData];
        
        [peripheral writeValue:start_flagData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];//CBCharacteristicWriteWithoutResponse
        
        NSInteger lastlength = pocketData.length % BLE_SEND_MAX_LEN;
        
        for (int i = BLE_SEND_MAX_LEN; i <= pocketData.length - (firstlength + lastlength); i += BLE_SEND_MAX_LEN) {
            
            UInt16 flag = CONTINUE_BYTE;
            NSMutableData *flagData = [NSMutableData dataWithBytes:&flag length:1];
            NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, BLE_SEND_MAX_LEN];
            NSData *subData = [pocketData subdataWithRange:NSRangeFromString(rangeStr)];
            [flagData appendData:subData];
            [peripheral writeValue:flagData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];//CBCharacteristicWriteWithoutResponse
            
            sleep(0.2);
            
        }
        
        UInt16 end_flag = END_BYTE;
        NSMutableData *end_flagData = [NSMutableData dataWithBytes:&end_flag length:1];
        NSData *end_subData = [pocketData subdataWithRange:NSMakeRange(pocketData.length - lastlength,lastlength)];
        
        [end_flagData appendData:end_subData];
        
        [peripheral writeValue:end_flagData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];//CBCharacteristicWriteWithoutResponse
        
        
    }
    
#else
    
    for (int i = 0; i < [pocketData length]; i += BLE_SEND_MAX_LEN) {
        // 预加 最大包长度，如果依然小于总数据长度，可以取最大包数据大小
        if ((i + BLE_SEND_MAX_LEN) < [pocketData length]) {
            NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, BLE_SEND_MAX_LEN];
            NSData *subData = [pocketData subdataWithRange:NSRangeFromString(rangeStr)];
            NSLog(@"%@",subData);
            [peripheral writeValue:subData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];//CBCharacteristicWriteWithoutResponse
            //根据接收模块的处理能力做相应延时
            usleep(20 * 1000);
        }else {
            NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, (int)([pocketData length] - i)];
            NSData *subData = [pocketData subdataWithRange:NSRangeFromString(rangeStr)];
            [peripheral writeValue:subData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];//CBCharacteristicWriteWithoutResponse
            usleep(20 * 1000);
        }
    }
    
#endif
    
}


//分包发送
#define NOTIFY_MTU      100
- (void)writeLongData:(NSData *)toSend  peripheral:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic
{
    self.dataToSend=toSend;
    self.sendDataIndex = 0;
    if (self.sendDataIndex >= self.dataToSend.length) {
        
        return;
    }
    
    int num=0;
    BOOL didSend = YES;
    
    while (didSend) {
        
        NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;//每次发送 NOTIFY_MTU 字节
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
        
        // Send it
        if (chunk) {
            
            [peripheral writeValue:chunk forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];//CBCharacteristicWriteWithoutResponse
            
            num++;
        }
        else
        {
            NSLog(@"data is null not send");
        }
        self.sendDataIndex += amountToSend;
        if (self.sendDataIndex >= self.dataToSend.length) {
            
            return;
        }
    }
}


- (void)readData
{
    if (self.readCharacteristic)
    {
        
        [self.activePeripheral readValueForCharacteristic:self.readCharacteristic];
    }
    
}
- (void)stopScan
{
    [self.CM stopScan];
}

// 3.开启扫描，扫描周边设备
- (int) scanBLEPeripherals:(int) timeout
{
    NSLog(@"start finding");
    
    if (self.CM.state != CBCentralManagerStatePoweredOn)
    {
        [self controlSetup];
        NSLog(@"CoreBluetooth not correctly initialized !");
        NSLog(@"State = %ld (%s)\r\n", (long)self.CM.state, [self centralManagerStateToString:self.CM.state]);
        return -1;
    }
    
    //[NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
    
    [self.CM stopScan];
    [self.peripherals removeAllObjects];
    [self.peripheralsRssi removeAllObjects];
    _writeCharacteristic=nil;
    if (self.activePeripheral) {
        [self.CM cancelPeripheralConnection:self.activePeripheral];
        self.activePeripheral=nil;
    }
    
    
    // 4.扫描周边设备的服务
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
    
    
//    [self.CM scanForPeripheralsWithServices:nil options:options];
#warning 极其重要的参数  目前是针对Alpha Mini指定搜索
    //针对指定的服务特征值进行搜索
    [self.CM scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_UUID]] options:options];
    
    
    NSLog(@"scanForPeripheralsWithServices");
    
    return 0; // Started scanning OK !
}
-(void) connectPeripheralWithUUID:(NSString *)UUID
{
    if (!UUID) {
        return;
    }
    _deviceUUID=UUID;
    CBPeripheral *p=[self getPeripheralByUUID:UUID];
    if (p) {
        [self connectPeripheral:p];
    }else{
        NSLog(@"无法找到外设去连接！");
    }
    
}
-(void) disConnectPeripheralWithUUID:(NSString *)UUID
{
    isConnected = NO;
    CBPeripheral *p=[self getPeripheralByUUID:UUID];
    if (p)
    {
        [self.CM cancelPeripheralConnection:p];
    }
    
}
-(CBPeripheral *)getPeripheralByUUID:(NSString *)uuid
{
    if (!uuid) {
        
        for (int i=0; i<self.peripherals.count; i++)
        {
            CBPeripheral *peripheral=[self.peripherals objectAtIndex:i];
            if (peripheral.state== CBPeripheralStateConnected)
            {
                NSLog(@" 找到了设备");
                
                return peripheral;
                break;
            }
        }
        
        return nil;
    }
    for (int i=0; i<self.peripherals.count; i++) {
        CBPeripheral *peripheral=[self.peripherals objectAtIndex:i];
        NSLog(@"peripheral.identifier.UUIDString=%@ uuid=%@",peripheral.identifier.UUIDString,uuid);
        NSString *uid=[NSString stringWithFormat:@"%@",peripheral.identifier.UUIDString];
        if ([uuid isEqualToString:uid])
        {
            NSLog(@" 找到了设备");
            return peripheral;
            break;
        }
    }
    NSLog(@" 找不到设备");
    return nil;
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
{
    
    NSLog(@"和外设已经断开连接，需要重连%s---deviceUUID===%@",__FUNCTION__,_deviceUUID);
    
    [[self delegate] bleDidDisconnect];
    
    isConnected = NO;

    
}

// 6.连接周边设备
- (void) connectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connecting to peripheral with UUID : %@", peripheral.identifier.UUIDString);//4A662705-DE35-902F-1A8A-C3715BC3EF08
    if(peripheral.state!= CBPeripheralStateConnected)
    {
        self.activePeripheral = peripheral;
        self.activePeripheral.delegate = self;
        [self.CM connectPeripheral:self.activePeripheral
                           options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    }
    else
    {
        NSLog(@"设备已经连接 ");
    }
}

- (const char *) centralManagerStateToString: (int)state
{
    switch(state)
    {
        case CBCentralManagerStateUnknown:
            return "State unknown (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateResetting:
            return "State resetting (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateUnsupported:
            return "State BLE unsupported (CBCentralManagerStateResetting)";
        case CBCentralManagerStateUnauthorized:
            return "State unauthorized (CBCentralManagerStateUnauthorized)";
        case CBCentralManagerStatePoweredOff:
            return "State BLE powered off (CBCentralManagerStatePoweredOff)";
        case CBCentralManagerStatePoweredOn:
            return "State powered up and ready (CBCentralManagerStatePoweredOn)";
        default:
            return "State unknown";
    }
    
    return "Unknown state";
}

- (void) scanTimer:(NSTimer *)timer
{
    [self.CM stopScan];
    NSLog(@"Stopped Scanning");
    NSLog(@"Known peripherals : %lu", (unsigned long)[self.peripherals count]);
    [self printKnownPeripherals];
}

- (void) printKnownPeripherals
{
    NSLog(@"List of currently known peripherals :");
    
    for (int i = 0; i < self.peripherals.count; i++)
    {
        CBPeripheral *p = [self.peripherals objectAtIndex:i];
        
        if (p.identifier != NULL)
        {
            NSLog(@"%d  |  %@", i, p.identifier.UUIDString);
        }
        else
        {
            NSLog(@"%d  |  NULL", i);
        }
        [self printPeripheralInfo:p];
    }
}

- (void) printPeripheralInfo:(CBPeripheral*)peripheral
{
    NSLog(@"------------------------------------");
    NSLog(@"Peripheral Info :");
    
    if (peripheral.identifier != NULL){
        NSLog(@"UUID : %@", peripheral.identifier.UUIDString);
    }else{
        NSLog(@"UUID : NULL");
    }

    NSLog(@"Name : %@", peripheral.name);
    NSLog(@"-------------------------------------");
    
    
}

- (BOOL) UUIDSAreEqual:(NSUUID *)UUID1 UUID2:(NSUUID *)UUID2
{
    if ([UUID1.UUIDString isEqualToString:UUID2.UUIDString])
        return YES;
    else
        return NO;
}

-(void) getAllServicesFromPeripheral:(CBPeripheral *)p
{
    [p discoverServices:nil]; // Discover all services without filter
}


-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2
{
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1];
    [UUID2.data getBytes:b2];
    
    if (memcmp(b1, b2, UUID1.data.length) == 0)
        return 1;
    else
        return 0;
}

-(int) compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID2
{
    char b1[16];
    
    [UUID1.data getBytes:b1];
    UInt16 b2 = [self swap:UUID2];
    
    if (memcmp(b1, (char *)&b2, 2) == 0)
        return 1;
    else
        return 0;
}

-(UInt16) CBUUIDToInt:(CBUUID *) UUID
{
    char b1[16];
    [UUID.data getBytes:b1];
    return ((b1[0] << 8) | b1[1]);
}

-(CBUUID *) IntToCBUUID:(UInt16)UUID
{
    char t[16];
    t[0] = ((UUID >> 8) & 0xff); t[1] = (UUID & 0xff);
    NSData *data = [[NSData alloc] initWithBytes:t length:16];
    return [CBUUID UUIDWithData:data];
}

-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p
{
    for(int i = 0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID])
            return s;
    }
    
    return nil; //Service not found on this peripheral
}

-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service
{
    for(int i=0; i < service.characteristics.count; i++)
    {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([self compareCBUUID:c.UUID UUID2:UUID]) return c;
    }
    
    return nil; //Characteristic not found on this service
}


// 2.检测中央设备状态(CBCentralManagerDelegate的required方法)
- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    
    static CBCentralManagerState previousState = -1;
    
    self.isBlueToothOpen = NO;
    NSLog(@"centralManagerDidUpdateState");
    switch ([central state])
    {
        case CBCentralManagerStateUnsupported:
        {
            
            NSLog(@"This device does not support Bluetooth Low Energy");
            break;
        }
        case CBCentralManagerStatePoweredOff:
        {
            
            NSLog(@"CBCentralManagerStatePoweredOff");
            
            break;
        }
        case CBCentralManagerStateUnauthorized:
        { NSLog(@"CBCentralManagerStateUnauthorized");
            /* Tell user the app is not allowed. */
            break;
        }
        case CBCentralManagerStateUnknown:
        { NSLog(@"CBCentralManagerStateUnknown");
            /* Bad news, let's wait for another event. */
            break;
        }
        case CBCentralManagerStatePoweredOn:
        { NSLog(@"CBCentralManagerStatePoweredOn");
            //[self scanBLEPeripherals:10];
            self.isBlueToothOpen = YES;
            if (self.isClickScan==1) {
                [self scanBLEPeripherals:self.scanTimeOut];
            }
            break;
        }
        case CBCentralManagerStateResetting:
        { NSLog(@"CBCentralManagerStateResetting");
            
            break;
        }
    }
    
}
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerDidUpdateState");
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:{
            
            
        }
            break;
            
        default:
            
            break;
    }
}


// 5.CBPeripheralDelegate代理方法,成功扫描到周边设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    CGFloat distance = 100;
    if (peripheral.name) {
        distance = [self calcDistByRSSI:RSSI.intValue];
        NSLog(@"设备%@离我有%f米",peripheral.name,distance);
    }
    
    NSLog(@"didDiscoverPeripheral");
    if (!self.peripherals)
    {
        self.peripherals = [[NSMutableArray alloc] init];
        self.peripheralsRssi = [[NSMutableArray alloc] init];
    }
    
    NSLog(@"机器人的广播数据advertisementData=%@",advertisementData);
    if ([self.peripherals containsObject:peripheral]) {//作用是允许重复获取蓝牙设备，重复的目的是为了获取变化中的RSSI值 
        [self.peripherals removeObject:peripheral];
    }
    if (![self.peripherals containsObject:peripheral] && peripheral.name) {
        
        NSLog(@"New UUID, adding %@ name=%@ rssi=%@ distance=%@",peripheral.identifier.UUIDString,peripheral.name,RSSI,@(distance));
        [self.peripherals addObject:peripheral];
        [self.peripheralsRssi addObject:RSSI];
        
        if(self.delegate)
        {
            if ([self.delegate conformsToProtocol:@protocol(BLEDelegate)] )
            {
                if([self.delegate respondsToSelector:@selector(didFoundDevice:)])
                {
                    NSString *deviceJson=[NSString stringWithFormat:@"{\"name\":\"%@\",\"uuid\":\"%@\",\"rssi\":\"%@\",\"serial\":\"%@\",\"distance\":\"%@\"}",peripheral.name,peripheral.identifier.UUIDString,RSSI,[self getSerialNum:advertisementData],@(distance)];
                    deviceJson=[deviceJson stringByReplacingOccurrencesOfString:@"\n\"" withString:@"\""];
                    [self.delegate didFoundDevice:deviceJson];
                }
            }
            
        }
    }
    else
    {
        NSLog(@"not add to array %@ name=%@",peripheral.identifier.UUIDString,peripheral.name);
        
    }
    
    NSArray *arr=[advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"];
    if(arr)
    {
        if(arr.count>0)
        {
            NSString *uuidstr=[NSString stringWithFormat:@"%@",[arr objectAtIndex:0]];
            /*
             if ([uuidstr isEqualToString:@"7F28E56B-216F-3910-9061-7AF1980811BA"])
             {
             _deviceUUID=peripheral.identifier.UUIDString;
             }
             if ([peripheral.identifier.UUIDString isEqualToString:_deviceUUID])
             {
             [self connectPeripheral:peripheral];
             // [self.CM stopScan];
             }
             */
            
        }
    }
    
    NSDictionary *dic=[advertisementData objectForKey:@"kCBAdvDataServiceData"];
    if (dic)
    {
        NSArray *allkey=[dic allKeys];
        for (int i=0; i<allkey.count; i++)
        {
            NSString *s = [[NSString alloc] initWithData:[dic objectForKey:[allkey objectAtIndex:i]] encoding:NSUTF8StringEncoding];
            
            NSLog(@"key=%@ value=%@",[allkey objectAtIndex:i],s);
        }
    }
    
    
#warning 此处为测试代码
    if ([peripheral.name isEqualToString:@"denglong"]) {
        [self.peripherals removeObject:peripheral];
    }
    
}

#pragma mark -- 根据rssi值计算蓝牙设备与手机的距离
/*具体解释请看：http://blog.csdn.net/njchenyi/article/details/46981423*/
- (float)calcDistByRSSI:(int)rssi{
    int iRssi = abs(rssi);
    float power = (iRssi-59)/(10*2.0);
    return powf(10.0f, power);
}


#pragma mark -
-(NSString *)getSerialNum:(NSDictionary *)advertisementData
{
    NSString *SerialNum=@"";
    NSDictionary *dic=[advertisementData objectForKey:@"kCBAdvDataServiceData"];
    if (dic)
    {
        NSArray *allkey=[dic allKeys];
        for (int i=0; i<allkey.count; i++)
        {
            NSString *key = [allkey objectAtIndex:i];
            NSData *myValueData = [dic objectForKey:key];
            Byte *bytes = (Byte *)[myValueData bytes];
            for(int i=0;i<[myValueData length];i++)
            {    NSLog(@"stByte = %d\n",bytes[i]);}
            NSString *s = [[NSString alloc] initWithData:myValueData encoding:NSASCIIStringEncoding];
            SerialNum=s;
           // SerialNum=@"T1234567890";
            NSLog(@"key=%@ value=%@ bytes=%s",key,s,bytes);
            break;
        }
    }    return SerialNum;
}
-(NSString *)getSerialNum22:(NSDictionary *)advertisementData
{
    NSString *SerialNum=@"";
    NSArray *arr=[advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"];
    if(arr)
    {
        if(arr.count>0)
        {
            SerialNum=[NSString stringWithFormat:@"%@",[arr objectAtIndex:0]];
        }
    }
    return SerialNum;
}

// 7.CBCentralManagerDelegate的代理方法,成功连接周边设备
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"你已经连接上了外设");
//    [self.delegate bleDidConnect];
    
    if (peripheral.identifier != NULL)
    {
        NSLog(@"Connected to %@ successful", peripheral.identifier.UUIDString);
    }
    else
    {
        NSLog(@"Connected to NULL successful");
    }
    if ([peripheral.identifier.UUIDString isEqualToString:_deviceUUID])
    {
        self.activePeripheral = peripheral;
        self.activePeripheral.delegate=self;
        // 8.扫描周围设备的服务
        [self.activePeripheral discoverServices:nil];
    }
    else
    {
        NSLog(@"not the connected device222 %@",peripheral.name);
    }
    
    isConnected = YES;
    
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (![peripheral.identifier.UUIDString isEqualToString:_deviceUUID])
    {
        NSLog(@"not the connected device %@",peripheral.name);
        return;
    }
    if (!error)
    {
        
        CBCharacteristic *aChar = nil;
        //if ([service.UUID isEqual:[CBUUID UUIDWithString:@"FFF0"]])
        //{
        
        for (aChar in service.characteristics)
        {
            // NSLog(@"serviceUUID=%@ aChar.UUID=%@",service.UUID,aChar.UUID);
            
            NSLog(@"\n开始连接lynx的服务：serviceUUID=%@  \ncharacteristic.uuid=%@ \ncharacteristic.value=%@ \naChar.properties=%lu  \naChar.description=%@ \naChar.isNotifying=%@",service.UUID,aChar.UUID,aChar.value,(unsigned long)aChar.properties,aChar.description,aChar.isNotifying?@"1":@"0");
            
            if([[NSString stringWithFormat:@"%@",aChar.UUID] isEqualToString:Lynx_UUID])
            {
                 NSLog(@"eefound Write characteristic.uuid: %@  \naChar.description: %@",aChar.UUID,aChar.description);
                 NSLog(@" serviceUUID=%@  \ncharacteristic.uuid=%@ \ncharacteristic.value=%@ \naChar.properties=%lu  \naChar.description=%@ \naChar.isNotifying=%@",service.UUID,aChar.UUID,aChar.value,(unsigned long)aChar.properties,aChar.description,aChar.isNotifying?@"1":@"0");
                    if (!_writeCharacteristic){
                        self.activePeripheral = peripheral;
                        self.activePeripheral.delegate=self;
                        CBCharacteristic *charr=aChar;
                        //找出写特征值
                        self.writeCharacteristic=charr;
                         [self.activePeripheral setNotifyValue:YES forCharacteristic:self.writeCharacteristic];
                         [self.activePeripheral readValueForCharacteristic:self.writeCharacteristic];
                    }
                
                [self.delegate bleDidConnect];
                
            }
            
            if(aChar.properties==CBCharacteristicPropertyRead)
            {
                NSLog(@"eefound Read characteristic.uuid=%@  value=%@ descriptors=%@",aChar.UUID,aChar.value,aChar.descriptors);
                
                [peripheral readValueForCharacteristic:aChar];
                CBCharacteristic *charr=aChar;
                //找出读特征值
                self.readCharacteristic=charr;
            }
            else if(aChar.properties==CBCharacteristicPropertyWriteWithoutResponse)
            {
                NSLog(@"eefound WriteWithoutResponse characteristic.uuid=%@ ",aChar.UUID);
                
            }
            else if(aChar.properties==CBCharacteristicPropertyNotify)
            {
                [peripheral setNotifyValue:YES forCharacteristic:aChar];
                NSLog(@"eefound Notify characteristic.uuid=%@ ",aChar.UUID);
            }
            
        }
        
    }
    else
    {
        NSLog(@"Characteristic discorvery unsuccessful!");
    }
}

- (NSMutableData *) hexStrToData: (NSString *)hexStr
{
    NSMutableData *data= [[NSMutableData alloc] init];
    NSUInteger len = [hexStr length];
    
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < len/2; i++) {
        byte_chars[0] = [hexStr characterAtIndex:i*2];
        byte_chars[1] = [hexStr characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    //return [data autorelease];
    return data;
}

// 9.CBPeripheralDelegate的代理方法，接收到了连接的周边设备的服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (!error)
    {
        if ([peripheral.identifier.UUIDString isEqualToString:_deviceUUID]) {
            //        printf("Services of peripheral with UUID : %s found\n",[self UUIDToString:peripheral.UUID]);
            [self getAllCharacteristicsFromPeripheral:peripheral];
        }
        
        
    }
    else
    {
        NSLog(@"Service discovery was unsuccessful!");
    }
}

// 10.扫描周边设备指定的特征
-(void) getAllCharacteristicsFromPeripheral:(CBPeripheral *)p
{
    for (CBService *s in p.services)
    {
        NSLog(@"[CBController] Service found with UUID: %@", s.UUID);
        [p discoverCharacteristics:nil forService:s];
    }
    
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error)
    {
        //  printf("Updated notification state for characteristic with UUID %s on service with  UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:characteristic.UUID],[self CBUUIDToString:characteristic.service.UUID],[self UUIDToString:peripheral.UUID]);
    }
    else
    {
        NSLog(@"Error in setting notification state for characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:characteristic.UUID],
              [self CBUUIDToString:characteristic.service.UUID],
              peripheral.identifier.UUIDString);
        
        NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    NSLog(@"didWriteValueForCharacteristic characteristic.uuid=%@",characteristic.UUID);
    if ([peripheral.identifier.UUIDString isEqualToString:_deviceUUID])
    {
        self.writeCharacteristic=characteristic;
    }
    /* When a write occurs, need to set off a re-read of the local CBCharacteristic to update its value */
    if (error)
    {
        NSLog(@"Error writing value for characteristic %@ error: %@", characteristic.UUID, [error localizedDescription]);
        return;
    }
    [peripheral readValueForCharacteristic:characteristic];
}

#pragma mark - 收到外设Lynx的数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //NSString *result = [[NSString alloc] initWithData:characteristic.value  encoding:NSUTF8StringEncoding];
    //NSLog(@"didUpdateValueForCharacteristic %@ str=%@ uuid=%@",characteristic.value,result,characteristic.UUID);
    //NSString *s = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    //NSLog(@"收到原始数据===== %@---error：%@", s,error);
    
    NSData *data = characteristic.value;//接收到的二进制数据流
    
    if (data.length == 0) {//如果没有数据则忽视
        return;
    }
    
    NSData *subData = [data subdataWithRange:NSMakeRange(0, 1)];//标志位：0x01表示开始  0x10表示继续 0x00表示结束
    NSData *reallyData = [data subdataWithRange:NSMakeRange(1, data.length - 1)];//真正的数据流
    
    //转换为标志位的第一个字节
    Byte *flagByte = (Byte *)[subData bytes];
    UInt16 flag = flagByte[0];
    
    //分包接收
    if (flag == START_BYTE) {//0x01代表开始
        _receiveData = [NSMutableData data];
        [_receiveData appendData:reallyData];
    }else if(flag == CONTINUE_BYTE){//0x10代表继续
        [_receiveData appendData:reallyData];
    }else if(flag == END_BYTE){//0x00代表结束
        [_receiveData appendData:reallyData];
        [[self delegate] bleDidReceiveData:_receiveData length:(int)characteristic.value.length];//代理回调
    }
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (!isConnected)
        return;
    
    if (rssi != peripheral.RSSI.intValue)
    {
        rssi = peripheral.RSSI.intValue;
        [[self delegate] bleDidUpdateRSSI:activePeripheral.RSSI];
    }
}

@end
