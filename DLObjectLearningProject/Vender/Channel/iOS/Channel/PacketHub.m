//
//  PacketHub.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/4.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#define HEADER_BYTES  4 // Integer.BYTES
#define BODY_SIZE_MIN  0
#define BODY_SIZE_MAX  0xFFFFFF



//publish event
#define BODY_TYPE_PUB  @"sub-pub.pub"
//subscribe event
#define BODY_TYPE_SUB  @"sub-pub.sub"
//unsubscribe event
#define BODY_TYPE_UNSUB  @"sub-pub.unsub"
//request
#define BODY_TYPE_REQ  @"req-res.req"
//response
#define BODY_TYPE_RES  @"req-res.res"
//register request
#define BODY_TYPE_REG_RES  @"req-res.reg-res"
//register request return 回复注册信息
#define BODY_TYPE_REG_RES_RET  @"req-res.reg-res-ret"
//unregister request
#define BODY_TYPE_UNREG_RES  @"req-res.unreg-res"

#define ENDPOINT @"mobile"

#define VERSION @"v1"

#import "PacketHub.h"
#import "packethub_utils.h"
#import "AsyncUdpSocketManager.h"
#import "AsynTcpSocketManager.h"
#import "HeartBeat.h"

static NSString *const PacketHubErrorDomain = @"com.ubt.packethubErrorDomain";
NSString *const AsyncSocketStatusChangeNotification = @"com.asynTctcpSocket.statusChageNotification";

static uint16_t localPort = 6000;
static long broadTimeOut = 5;

@interface PacketHub() <TcpSocketConnectStatus, TcpSocketCallBackDelegate>

@property (nonatomic, strong)NSMutableDictionary *callBackDic;

@property (nonatomic, strong)NSMutableDictionary *subScibers;

@property (nonatomic, strong)HeartBeat *headBeat;

@property (nonatomic, strong)NSMutableData *receiveData;

@end

@implementation PacketHub

+(instancetype)sharePacketHub {
    static PacketHub *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PacketHub alloc] init];
    });
    return sharedInstance;
}

-(NSString *)getLocalIpAddress {
    NSDictionary *addressDic = [AsynSocketManager localIPAddress];
    return [addressDic objectForKey:@"HOST"];
}

-(BOOL)deviceDetectionSuccess:(void (^)(id responseObj))success failure:(void (^)(NSError *error))failure {
    NSDictionary *addressDic = [AsynSocketManager localIPAddress];
    NSLog(@"======>Broadcast addressDic = %@", addressDic);
    if(addressDic) {
        NSString *localHost = [addressDic objectForKey:@"HOST"];
        NSString *broadcastHost = [addressDic objectForKey:@"BROADCASTHOST"];
        
        NSString *id_p = [packethub_utils getUniqueId];
        
        DiscoverParam *discoverParam = [[DiscoverParam alloc] init];
        discoverParam.discoverHost = localHost;
        discoverParam.discoverPort = localPort;
        discoverParam.broadcast = broadcastHost;
        
        Event *event = [[Event alloc] init];
        event.id_p = id_p;
        event.endpoint = ENDPOINT;
        event.when = [self getSendTimeStamp];
        [event.param packWithMessage:discoverParam error:nil];
        
        Header *header = [[Header alloc] init];
        header.id_p = id_p;
        header.endpoint = ENDPOINT;
        header.when = event.when;
        header.version = VERSION;
        header.bodyType = BODY_TYPE_PUB;
        
        Packet *packet = [[Packet alloc] init];
        packet.header = header;
        NSError *err = nil;
        [packet.body packWithMessage:event error:&err];
        if(err) {
            failure(err);
            return NO;
        }
        NSData *data = [packet data];
        
        BOOL res = [[AsyncUdpSocketManager shareUdpSocketManager] broadcastData:data toHost:broadcastHost port:7999 timeOut:broadTimeOut responseBlock:^(NSData *receiveData) {
            NSError *error = nil;
            Packet *packet = [Packet parseFromData:receiveData error:&error];
            if(error) {
                failure(error);
                return;
            }
            Event *event = (Event *)[packet.body unpackMessageClass:[Event class] error:&error];
            if(error) {
                failure(error);
                return;
            }
            DiscoveredParam *param = (DiscoveredParam *)[event.param unpackMessageClass:[DiscoveredParam class] error:&error];
            if(error) {
                failure(error);
                return;
            }
            success(param);
        }];
        return res;
    }else {
        NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"get local ip address fail"}];
        failure(error);
        return NO;
    }
}

//连接
-(BOOL)connectToHost:(NSString *)host onPort:(uint16_t)port withTimeout:(NSTimeInterval)timeout {
    if(!host || port == 0 || timeout == 0) return NO;
    BOOL res = [[AsynTcpSocketManager shareTcpSocketManager] connectToHost:host onPort:port withTimeout:timeout connectStatusDelegate:self];
    return  res;
}

//重连
-(BOOL)reConnect {
   return [[AsynTcpSocketManager shareTcpSocketManager] connect];
}

//关闭
-(void)shotDown {
    [[AsynTcpSocketManager shareTcpSocketManager] close];
}

//对象初始化
-(Event *)newEventWithAction:(NSString *)action subAction:(NSString *)subAction andParam:(id)param {
    Event *event = [[Event alloc] init];
    event.id_p = [packethub_utils getUniqueId];
    event.endpoint = ENDPOINT;
    event.action = action;
    event.subAction = subAction;
    event.when = [self getSendTimeStamp];
    if(param) {
        NSError *error = nil;
        [event.param packWithMessage:(GPBMessage *)param error:&error];
    }
    return event;
}


-(Event *)newEventWithAction:(NSString *)action andParam:(id)param {
    Event *event = [[Event alloc] init];
    event.id_p = [packethub_utils getUniqueId];
    event.endpoint = ENDPOINT;
    event.action = action;
    event.when = [self getSendTimeStamp];
    if(param) {
        NSError *error = nil;
         [event.param packWithMessage:(GPBMessage *)param error:&error];
    }
    return event;
}

-(Request *)newRequestWithUri:(NSString *)uri method:(Method_Enum)method andParam:(id)param {
    Request *request = [[Request alloc] init];
    request.id_p = [packethub_utils getUniqueId];
    request.endpoint = ENDPOINT;
    request.uri = uri;
    request.method = method;
    request.when = [self getSendTimeStamp];
    if(param) {
        NSError *error = nil;
        [request.param packWithMessage:(GPBMessage *)param error:&error];
    }
    return request;
}

-(Packet *)newPacketWithBody:(GPBMessage *)body withBodytype:(NSString *)bodyType {
    Packet *packet = [[Packet alloc] init];
    Header *header = [[Header alloc] init];
    if([bodyType isEqualToString:BODY_TYPE_PUB]) {
        Event *event = (Event *)body;
        header.id_p = event.id_p;
        header.endpoint = event.endpoint;
        header.when = event.when;
        header.version = VERSION;
        header.bodyType = bodyType;
    }else if([bodyType isEqualToString:BODY_TYPE_SUB] || [bodyType isEqualToString:BODY_TYPE_UNSUB]){
        header.id_p = [packethub_utils getUniqueId];
        header.endpoint = ENDPOINT;
        header.when = [self getSendTimeStamp];
        header.version = VERSION;
        header.bodyType = bodyType;
    }else if([bodyType isEqualToString:BODY_TYPE_REQ]) {
        Request *request = (Request *)body;
        header.id_p = request.id_p;
        header.endpoint = request.endpoint;
        header.when = request.when;
        header.version = VERSION;
        header.bodyType = bodyType;
    }else if([bodyType isEqualToString:BODY_TYPE_RES] || [bodyType isEqualToString:BODY_TYPE_REG_RES_RET] || [bodyType isEqualToString:BODY_TYPE_UNREG_RES]) {
        
    }
    packet.header = header;
    if(body) {
        NSError *error = nil;
        [packet.body packWithMessage:body error:&error];
    }
    return packet;
}

-(NSData *)getSendDataWithPacket:(Packet *)packet {
    NSData *packetData = [packet data];
    int len = (int)[packetData length];
    if(len > BODY_SIZE_MIN && len <= BODY_SIZE_MAX) {
        NSData *lenData = [packethub_utils int2Bytes:len];
        NSMutableData *sendData = [NSMutableData data];
        [sendData appendData:lenData];
        [sendData appendData:packetData];
        return sendData;
    }else {
        return nil;
    }
}

-(void)doSendData:(NSData *)sendData withMsgId:(NSString *)msgId withSuccess:(void (^)(id responseObj))success failure:(void (^)(NSError *error))failure {
    if(sendData) {
        if(msgId && success && failure) {
            if(!self.callBackDic) {
                self.callBackDic = [NSMutableDictionary dictionary];
            }
            NSArray *array = [NSArray arrayWithObjects:success,[failure copy], nil];
            [self.callBackDic setObject:array forKey:msgId];
        }
        [[AsynTcpSocketManager shareTcpSocketManager] sendMsg:sendData withTimeout:-1 withCallBackDelegate:self];
    }else {
        NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"sendData is illeagl"}];
        failure(error);
    }
}

-(int64_t)getSendTimeStamp {
    NSDate *currentDate = [NSDate date];
    long currentTimeInterval = (long)([currentDate timeIntervalSince1970] * 1000);
    return currentTimeInterval - _headBeat.differInterval;
}

//发布
-(void)pubilsh:(NSString *)action {
    if(!action) return;
    Event *event = [self newEventWithAction:action andParam:nil];
    Packet *packet = [self newPacketWithBody:event withBodytype:BODY_TYPE_PUB];
    NSData *sendData = [self getSendDataWithPacket:packet];
    [self doSendData:sendData withMsgId:nil withSuccess:nil failure:nil];
    
}

-(void)pubilsh:(NSString *)action subAction:(NSString *)subAction {
    if(!action  || !subAction) return;
    Event *event = [self newEventWithAction:action subAction:subAction andParam:nil];
    Packet *packet = [self newPacketWithBody:event withBodytype:BODY_TYPE_PUB];
    NSData *sendData = [self getSendDataWithPacket:packet];
    [self doSendData:sendData withMsgId:nil withSuccess:nil failure:nil];
}

-(void)publish:(NSString *)action param:(id)param {
    if(!action || !param) return;
    Event *event = [self newEventWithAction:action andParam:param];
    Packet *packet = [self newPacketWithBody:event withBodytype:BODY_TYPE_PUB];
    NSData *sendData = [self getSendDataWithPacket:packet];
    [self doSendData:sendData withMsgId:nil withSuccess:nil failure:nil];
}

-(void)pubilsh:(NSString *)action subAction:(NSString *)subAction param:(id)param {
    if(!action  || !subAction || !param) return;
    Event *event = [self newEventWithAction:action subAction:subAction andParam:param];
    Packet *packet = [self newPacketWithBody:event withBodytype:BODY_TYPE_PUB];
    NSData *sendData = [self getSendDataWithPacket:packet];
    [self doSendData:sendData withMsgId:nil withSuccess:nil failure:nil];
}


//订阅
-(void)subScribe:(SubScriber *)subScriber actions:(NSArray *)actions {
    if(!subScriber || actions.count == 0) return;
    GPBListValue *listValue = [[GPBListValue alloc] init];
    for(int i = 0; i < actions.count; i++) {
        GPBValue *value = [[GPBValue alloc] init];
        value.stringValue = [actions[i] copy];
        [listValue.valuesArray addObject:value];
    }
    Packet *packet = [self newPacketWithBody:listValue withBodytype:BODY_TYPE_SUB];
    NSData *sendData = [self getSendDataWithPacket:packet];
    if(!self.subScibers) {
        self.subScibers = [NSMutableDictionary dictionary];
    }
    for(int j = 0; j < actions.count; j++) {
        NSString *action = actions[j];
        NSMutableArray *array = [self.subScibers objectForKey:action];
        if(!array) {
            array = [NSMutableArray array];
        }
        BOOL isContain = NO;
        for (int t = 0; t < array.count; t++) {
            SubScriber *temp = array[t];
            if(temp == subScriber) {
                isContain = YES;
            }
        }
        if(!isContain) {
            [array addObject:subScriber];
        }
        [self.subScibers setObject:array forKey:action];
    }
    [self doSendData:sendData withMsgId:nil withSuccess:nil failure:nil];

}

-(void)subScribe:(SubScriber *)subScriber action:(NSString *)action {
    if(!subScriber || !action)  {
        return;
    }
    GPBListValue *listValue = [[GPBListValue alloc] init];
    GPBValue *value = [[GPBValue alloc] init];
    value.stringValue = [action copy];
    [listValue.valuesArray addObject:value];
    
    Packet *packet = [self newPacketWithBody:listValue withBodytype:BODY_TYPE_SUB];
    NSData *sendData = [self getSendDataWithPacket:packet];
    if(!self.subScibers) {
        self.subScibers = [NSMutableDictionary dictionary];
    }
    NSMutableArray *array = [self.subScibers objectForKey:action];
    if(!array) {
        array = [NSMutableArray array];
    }
    BOOL isContain = NO;
    for (int i = 0; i < array.count; i++) {
        SubScriber *temp = array[i];
        if(temp == subScriber) {
            isContain = YES;
        }
    }
    if(!isContain) {
        [array addObject:subScriber];
    }
    [self.subScibers setObject:array forKey:action];
    [self doSendData:sendData withMsgId:nil withSuccess:nil failure:nil];
    
}

//取消订阅
-(void)unSubscribe:(SubScriber *)subScriber {
    if(!self.subScibers) return;
    NSMutableArray *actions = [NSMutableArray array];
    NSMutableArray *keyArray = [[NSMutableArray alloc] initWithArray:[self.subScibers allKeys]];
    for (int i = 0; i < keyArray.count; i++) {
        NSMutableArray *valueArray = [self.subScibers objectForKey:keyArray[i]];
        for (SubScriber *temp in valueArray) {
            if(subScriber == temp) {
                [valueArray removeObject:temp];
            }
        }
        if(valueArray.count == 0) {
            [actions addObject:keyArray[i]];
            [self.subScibers removeObjectForKey:keyArray[i]];
        }
    }
    
    if(actions.count == 0) return;
    GPBListValue *listValue = [[GPBListValue alloc] init];
    for (int i = 0; i < actions.count; i++) {
        GPBValue *value = [[GPBValue alloc] init];
        value.stringValue = [actions[i] copy];
        [listValue.valuesArray addObject:value];
    }
    Packet *packet = [self newPacketWithBody:listValue withBodytype:BODY_TYPE_UNSUB];
    NSData *sendData = [self getSendDataWithPacket:packet];
    [self doSendData:sendData withMsgId:nil withSuccess:nil failure:nil];

}

//get请求
-(void)getUri:(NSString *)uri success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure {
    if(!uri) {
        NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Paramter is illegal!"}];
        failure(error);
        return;
    }
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Get andParam:nil];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    [self doSendData:sendData withMsgId:request.id_p withSuccess:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

-(Response *)getUri:(NSString *)uri {
    if(!uri) return nil;
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Get andParam:nil];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block id res = nil;
    void (^success)(id responseObj) = ^(id responseObj) {
        res = responseObj;
        dispatch_semaphore_signal(semaphore);
    };
    void (^failure)(NSError *error) = ^(NSError *error) {
        dispatch_semaphore_signal(semaphore);
    };
    [self doSendData:sendData withMsgId:request.id_p withSuccess:success failure:failure];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC));
    return res;
}

-(void)getUri:(NSString *)uri param:(id)param success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure {
    if(!uri || !param) {
        NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Paramter is illegal!"}];
        failure(error);
        return;
    }
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Get andParam:param];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    [self doSendData:sendData withMsgId:request.id_p withSuccess:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

-(Response *)getUri:(NSString *)uri param:(id)param {
    if(!uri || !param) return nil;
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Get andParam:param];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block id res = nil;
    void (^success)(id responseObj) = ^(id responseObj) {
        res = responseObj;
        dispatch_semaphore_signal(semaphore);
    };
    void (^failure)(NSError *error) = ^(NSError *error) {
        dispatch_semaphore_signal(semaphore);
    };
    [self doSendData:sendData withMsgId:request.id_p withSuccess:success failure:failure];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC));
    return res;
}

//post请求
-(void)postUri:(NSString *)uri success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure {
    if(!uri) {
        NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Paramter is illegal!"}];
        failure(error);
        return;
    }
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Post andParam:nil];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    [self doSendData:sendData withMsgId:request.id_p withSuccess:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

-(Response *)postUri:(NSString *)uri {
    if(!uri)return nil;
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Post andParam:nil];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block id res = nil;
    void (^success)(id responseObj) = ^(id responseObj) {
        res = responseObj;
        dispatch_semaphore_signal(semaphore);
    };
    void (^failure)(NSError *error) = ^(NSError *error) {
        dispatch_semaphore_signal(semaphore);
    };
    [self doSendData:sendData withMsgId:request.id_p withSuccess:success failure:failure];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC));
    return res;

}

-(void)postUri:(NSString *)uri param:(id)param success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure {
    if(!uri || !param) {
        NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Paramter is illegal!"}];
        failure(error);
        return;
    }
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Post andParam:param];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    [self doSendData:sendData withMsgId:request.id_p withSuccess:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

-(Response *)postUri:(NSString *)uri param:(id)param {
    if(!uri || !param) return nil;
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Post andParam:param];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block id res = nil;
    void (^success)(id responseObj) = ^(id responseObj) {
        res = responseObj;
        dispatch_semaphore_signal(semaphore);
    };
    void (^failure)(NSError *error) = ^(NSError *error) {
        dispatch_semaphore_signal(semaphore);
    };
    [self doSendData:sendData withMsgId:request.id_p withSuccess:success failure:failure];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC));
    return res;

}

//put请求
-(void)putUri:(NSString *)uri success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure {
    if(!uri) {
        NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Paramter is illegal!"}];
        failure(error);
        return;
    }
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Put andParam:nil];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    [self doSendData:sendData withMsgId:request.id_p withSuccess:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

-(Response *)putUri:(NSString *)uri {
    if(!uri) return nil;
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Put andParam:nil];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block id res = nil;
    void (^success)(id responseObj) = ^(id responseObj) {
        res = responseObj;
        dispatch_semaphore_signal(semaphore);
    };
    void (^failure)(NSError *error) = ^(NSError *error) {
        dispatch_semaphore_signal(semaphore);
    };
    [self doSendData:sendData withMsgId:request.id_p withSuccess:success failure:failure];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC));
    return res;

}

-(void)putUri:(NSString *)uri param:(id)param success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure {
    if(!uri || !param) {
        NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Paramter is illegal!"}];
        failure(error);
        return;
    }
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Put andParam:param];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    [self doSendData:sendData withMsgId:request.id_p withSuccess:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

-(Response *)putUri:(NSString *)uri param:(id)param {
    if(!uri || !param) return nil;
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Get andParam:param];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block id res = nil;
    void (^success)(id responseObj) = ^(id responseObj) {
        res = responseObj;
        dispatch_semaphore_signal(semaphore);
    };
    void (^failure)(NSError *error) = ^(NSError *error) {
        dispatch_semaphore_signal(semaphore);
    };
    [self doSendData:sendData withMsgId:request.id_p withSuccess:success failure:failure];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC));
    return res;

}

//patch请求
-(void)patchUri:(NSString *)uri success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure {
    if(!uri) {
        NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Paramter is illegal!"}];
        failure(error);
        return;
    }
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Patch andParam:nil];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    [self doSendData:sendData withMsgId:request.id_p withSuccess:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

-(Response *)patchUri:(NSString *)uri {
    if(!uri) return nil;
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Patch andParam:nil];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block id res = nil;
    void (^success)(id responseObj) = ^(id responseObj) {
        res = responseObj;
        dispatch_semaphore_signal(semaphore);
    };
    void (^failure)(NSError *error) = ^(NSError *error) {
        dispatch_semaphore_signal(semaphore);
    };
    [self doSendData:sendData withMsgId:request.id_p withSuccess:success failure:failure];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC));
    return res;

}

-(void)patchUri:(NSString *)uri param:(id)param success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure {
    if(!uri || !param) {
        NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Paramter is illegal!"}];
        failure(error);
        return;
    }
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Patch andParam:param];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    [self doSendData:sendData withMsgId:request.id_p withSuccess:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

-(Response *)patchUri:(NSString *)uri param:(id)param {
    if(!uri || !param) return nil;
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Patch andParam:param];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block id res = nil;
    void (^success)(id responseObj) = ^(id responseObj) {
        res = responseObj;
        dispatch_semaphore_signal(semaphore);
    };
    void (^failure)(NSError *error) = ^(NSError *error) {
        dispatch_semaphore_signal(semaphore);
    };
    [self doSendData:sendData withMsgId:request.id_p withSuccess:success failure:failure];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC));
    return res;

}

//delete请求
-(void)deleteUri:(NSString *)uri success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure {
    if(!uri) {
        NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Paramter is illegal!"}];
        failure(error);
        return;
    }
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Delete andParam:nil];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    [self doSendData:sendData withMsgId:request.id_p withSuccess:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

-(Response *)deleteUri:(NSString *)uri {
    if(!uri) return nil;
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Delete andParam:nil];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block id res = nil;
    void (^success)(id responseObj) = ^(id responseObj) {
        res = responseObj;
        dispatch_semaphore_signal(semaphore);
    };
    void (^failure)(NSError *error) = ^(NSError *error) {
        dispatch_semaphore_signal(semaphore);
    };
    [self doSendData:sendData withMsgId:request.id_p withSuccess:success failure:failure];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC));
    return res;

}

-(void)deleteUri:(NSString *)uri param:(id)param success:(void (^)(Response *responseObj))success failure:(void (^)(NSError *error))failure {
    if(!uri || !param) {
        NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Paramter is illegal!"}];
        failure(error);
        return;
    }
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Delete andParam:param];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    [self doSendData:sendData withMsgId:request.id_p withSuccess:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

-(Response *)deleteUri:(NSString *)uri param:(id)param {
    if(!uri || !param) return nil;
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Delete andParam:param];
    Packet *packet = [self newPacketWithBody:request withBodytype:BODY_TYPE_REQ];
    NSData *sendData = [self getSendDataWithPacket:packet];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block id res = nil;
    void (^success)(id responseObj) = ^(id responseObj) {
        res = responseObj;
        dispatch_semaphore_signal(semaphore);
    };
    void (^failure)(NSError *error) = ^(NSError *error) {
        dispatch_semaphore_signal(semaphore);
    };
    [self doSendData:sendData withMsgId:request.id_p withSuccess:success failure:failure];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC));
    return res;

}


#pragma mark --TcpSocketCallBackDelegate
- (void)asyncTcpSocket:(GCDAsyncSocket *)sock didReadData:(NSData *)data {
    [self.headBeat updateReceiveTime];
    @synchronized (self) {
        if(!self.receiveData) {
            self.receiveData = [NSMutableData data];
        }
        
        [self.receiveData appendData:data];
        
        int len = [packethub_utils bytes2Int:(Byte *)[[self.receiveData subdataWithRange:NSMakeRange(0,4)] bytes]];
        int allLength = (int)[self.receiveData length];
        
        while (allLength >= len + 4) {
            NSLog(@"self.receiveData = %@",self.receiveData);
            NSData *receiveData = nil;
            receiveData = [self.receiveData subdataWithRange:NSMakeRange(4, len)];
            NSLog(@"===>len = %d, allLength = %d",len,allLength);
            NSData *avialbleData = [self.receiveData subdataWithRange:NSMakeRange(len + 4, allLength - len - 4)];
            self.receiveData = avialbleData.mutableCopy;
            if([self.headBeat isRecvedPong:receiveData]) {
                NSLog(@"================>receive pong");
            }else {
                NSLog(@"=====>receiveData = %@",receiveData);
                [self handleResponseData:receiveData];
            }
            if(self.receiveData.length > 4) {
                len = [packethub_utils bytes2Int:(Byte *)[[self.receiveData subdataWithRange:NSMakeRange(0,4)] bytes]];
                allLength = (int)[self.receiveData length];
            }else {
                break;
            }
        }
    }
}

- (void)asyncTcpSocket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength {
    
}



#pragma mark --TcpSocketConnectStatus
static bool isNeedReconnect = YES;
-(void)asyncTcpSocketConnectStatus:(SocketConnectStatus)status {
    switch (status) {
        case Disconnect:  //断开连接
        {
            if(isNeedReconnect) {
                [[AsynTcpSocketManager shareTcpSocketManager] connect];
                isNeedReconnect = NO;
            }else {
                [self.headBeat destoryHeartBeat];
                [[NSNotificationCenter defaultCenter] postNotificationName:AsyncSocketStatusChangeNotification object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@(-1),@"AsyncTCPSockConnectStatus", nil]];
            }
        }
            break;
        case Connecting: //正在连接
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:AsyncSocketStatusChangeNotification object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@(0),@"AsyncTCPSockConnectStatus", nil]];
        }
            break;
        case Connected:  //已连接
        {
            isNeedReconnect = YES;
            if(!self.headBeat) {
                self.headBeat = [[HeartBeat alloc] init];
            }
            [self.headBeat startHeartBeat];
              [[NSNotificationCenter defaultCenter] postNotificationName:AsyncSocketStatusChangeNotification object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@(1),@"AsyncTCPSockConnectStatus", nil]];
        }
            break;
        default:
            break;
    }
}

#pragma mark -Responsedata Handle
-(void)handleResponseData:(NSData *)responseData {
    Packet *packet = [Packet parseFromData:responseData error:nil];
    Header *header = packet.header;
    if([header.bodyType isEqualToString:BODY_TYPE_PUB]) {
        Event *event = (Event *)[packet.body unpackMessageClass:[Event class] error:nil];
        NSLog(@"============>PUB event = %@", [event description]);
        NSString *action = event.action;
        NSArray *array = self.subScibers[action];
        NSLog(@"============>PUB array = %@",[array description]);
        for (int i = 0; i < array.count; i++) {
            SubScriber *subsriber = array[i];
            subsriber.handle(event);
        }
        
    }else if([header.bodyType isEqualToString:BODY_TYPE_RES]) {
        Response *response = (Response *)[packet.body unpackMessageClass:[Response class] error:nil];
        NSLog(@"===========>RES response = %@",[response description]);
        NSLog(@"===========>self.callBackDic = %@",[self.callBackDic description]);
        NSArray *array = self.callBackDic[response.reqId];
        [self.callBackDic removeObjectForKey:response.reqId];
        void(^success)(id responseObj) = array[0];
        void(^failure)(NSError *error) = array[1];
        if(response) {
            success(response);
        }else {
            NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Parse responseData error"}];
            failure(error);
 
        }
    }
}



@end
