//
//  FileModel.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//  机器人实体类（这里命名不准确）


#import "BaseModel.h"
#import "SyncFiles.pbobjc.h"

typedef NS_ENUM(NSUInteger, State) {
    Unknown,
    Success,
    Illegal,
    Fail,
};

@interface FileModel : BaseModel

@property (nonatomic, strong) NSString *fileKey;
@property (nonatomic, strong) NSString *hash_;
@property (nonatomic, assign) State state;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, assign) long  uploadedTime;
@property (nonatomic, strong) NSString *originRobotId;
@property (nonatomic, assign) long uploaderId;
@property (nonatomic, assign) int cloudId;
@property (nonatomic, assign) int storageType;
@property (nonatomic, assign) int isCollected;
@property (nonatomic, strong) NSString *fileDescription;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *thumbnail;
@property (nonatomic, strong) NSString *preview;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSArray *location;
@property (nonatomic, assign) long timestamp;
@property (nonatomic, assign) long size;
@property (nonatomic, assign) long len;
@property (nonatomic, strong) NSString *from;
@property (nonatomic, copy) NSString *orinalImageURL;/**< 原图链接,供下载使用 */
@property (nonatomic, copy) NSString *bigImageURL;/**< 大图链接，供单图查看使用 */
@property (nonatomic, copy) NSString *thumnailImageURL;/**< 缩略图链接，供相册列表使用 */


//@property (nonatomic, assign) long fileCreateTime;
//@property (nonatomic, assign) float longitude;
//@property (nonatomic, assign) float latitude;
//@property (nonatomic, strong) NSString *url;
//@property (nonatomic, assign) int fileId;


+(FileModel *)read:(MetaData *)data;

-(BOOL)isEqualToMode:(FileModel *)fileModel;




@end
