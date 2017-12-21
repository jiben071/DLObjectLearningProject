//
//  PacketHub_IM.m
//  AlphaMini
//
//  Created by denglong on 13/11/2017.
//  Copyright © 2017 denglong. All rights reserved.
//  通过IM传输数据  实现IM拉取图片列表以及单张图片

#import "PacketHub_IM.h"
#import "packethub_utils.h"
#import "HeartBeat.h"
#import "Protocol.h"
#import "SyncParams.pbobjc.h"


#define HEADER_BYTES  4 // Integer.BYTES
#define BODY_SIZE_MIN  0
#define BODY_SIZE_MAX  0xFFFFFF

static NSString *const PacketHubErrorDomain = @"com.ubt.packethubErrorDomain";

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

typedef void(^TaskSuccessBlock)(id responseObj);
typedef void(^TaskFailureBlock)(NSError *error);


@interface PacketHub_IM()
@property (nonatomic, strong)HeartBeat *headBeat;
@property (nonatomic, strong)NSMutableDictionary *callBackDic;
@property (nonatomic, assign) NSInteger commandID;/**< 命令号 */
@property (nonatomic,strong) id param;/**< 参数 */
@property (nonatomic,strong) NSData *commandParamData;/**< 命令参数 */
@property (nonatomic,copy) TaskSuccessBlock successBlock;/**< 成功回调 */
@property (nonatomic,copy) TaskFailureBlock failureBlock;/**< 失败回调 */

@end

@implementation PacketHub_IM
+(instancetype)sharePacketHub {
    static PacketHub_IM *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PacketHub_IM alloc] init];
    });
    return sharedInstance;
}

- (HeartBeat *)headBeat{
    if (!_headBeat) {
        _headBeat = [[HeartBeat alloc] init];
        [_headBeat startHeartBeat];
    }
    return _headBeat;
}

- (NSMutableDictionary *)callBackDic{
    if (!_callBackDic) {
        _callBackDic = [NSMutableDictionary dictionary];
    }
    return _callBackDic;
}


#pragma mark -- 核心发送数据方法
-(void)getUri:(NSString *)uri
        param:(id)param
    commandID:(NSInteger)commandID
 commandParamData:(NSData *)commandParamData
      success:(void (^)(id responseObj))success
      failure:(void (^)(NSError *error))failure {
    if(!uri || !param) {
        NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Paramter is illegal!"}];
        failure(error);
        return;
    }
    self.commandID = commandID;
    self.param = param;
    self.commandParamData = commandParamData;
    Request *request = [self newRequestWithUri:uri method:Method_Enum_Get andParam:param];
    NSError *error;
    GPBAny *any = request.param;
    if (error) {
        NSLog(@"发生错误：%@",error);
        return;
    }
    
    [self doSendData:any withMsgId:request.id_p withSuccess:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}


#pragma mark - 辅助方法
#pragma mark -- 新建请求
-(Request *)newRequestWithUri:(NSString *)uri method:(Method_Enum)method andParam:(id)param {
    Request *request = [[Request alloc] init];
    request.id_p = [self getUniqueId];
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

-(NSString *)getUniqueId {
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [formatter stringFromDate:currentDate];
}



#pragma mark -- 获取时间戳
-(int64_t)getSendTimeStamp {
    NSDate *currentDate = [NSDate date];
    long currentTimeInterval = (long)([currentDate timeIntervalSince1970] * 1000);
    return currentTimeInterval - _headBeat.differInterval;
}

-(void)doSendData:(GPBAny *)anyData withMsgId:(NSString *)msgId withSuccess:(void (^)(id responseObj))success failure:(void (^)(NSError *error))failure {
    
    self.successBlock = success;
    self.failureBlock = failure;
    if(anyData) {
        if(msgId && success && failure) {
            if(!self.callBackDic) {
                self.callBackDic = [NSMutableDictionary dictionary];
            }
            NSArray *array = [NSArray arrayWithObjects:success,[failure copy], nil];
            [self.callBackDic setObject:array forKey:msgId];
        }
    }else {
        NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"sendData is illeagl"}];
        failure(error);
    }
}

#pragma mark -Responsedata Handle
-(void)handleResponseData:(GPBAny *)paramAny {
    PullResponse *pullResponse = (PullResponse *)[paramAny unpackMessageClass:[PullResponse class] error:nil];
    PushResponse *pushResponse = (PushResponse *)[paramAny unpackMessageClass:[PushResponse class] error:nil];

    NSString *reqID = @"";
    id obj = nil;
    if (pullResponse) {
        reqID = [self getShowDateTime:[NSString stringWithFormat:@"%@",@(pullResponse.seqId)]];
        obj = pullResponse;
        NSLog(@"===========>RES response = %@",[pullResponse description]);
    }
    
    if (pushResponse) {
        reqID = [self getShowDateTime:[NSString stringWithFormat:@"%@",@(pushResponse.seqId)]];
        obj = pushResponse;
        NSLog(@"===========>RES response = %@",[pushResponse description]);
    }
    
    if(obj && self.successBlock) {
        self.successBlock(obj);
    }else {
        NSError *error = [NSError errorWithDomain:PacketHubErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Parse responseData error"}];
        if (self.failureBlock) {
            self.failureBlock(error);
        }
    }
}


- (NSString *)getShowDateTime:(NSString *)timeString{
    long long time =  [timeString longLongValue];
    NSDate *d = [[NSDate alloc] initWithTimeIntervalSince1970:time];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *timeStringAfterF = [formatter stringFromDate:d];
    return timeStringAfterF;
}


@end
