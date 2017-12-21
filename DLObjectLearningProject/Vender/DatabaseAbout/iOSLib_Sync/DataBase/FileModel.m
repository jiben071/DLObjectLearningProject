//
//  FileModel.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "FileModel.h"

@implementation FileModel

#pragma mark - SQLModelRecordProtocol
- (NSArray *)availableKeyList
{
    return @[@"id_q", @"fileKey", @"hash_",@"state",@"filename",@"uploadedTime",@"originRobotId",@"uploaderId",@"cloudId",@"storageType",@"isCollected",@"fileDescription",@"path",@"thumbnail",@"preview",@"type",@"tags",@"location",@"timestamp",@"size",@"len",@"from",@"fileCreateTime",@"longitude",@"latitude",@"url",@"fileId",@"orinalImageURL",@"bigImageURL",@"thumnailImageURL"];
}

+(FileModel *)read:(MetaData *)data {
    if(data == nil) return nil;
    FileModel *mode = [[FileModel alloc] init];
    mode.filename = data.name;
    mode.from = FROM_ROBOT;
    mode.path = data.path;
    mode.thumbnail = data.thumbnail;
    mode.preview = data.preview;
    mode.type = data.type;
    mode.size = data.size;
    if(data.tagArray.count > 0) {
        mode.tags = [NSArray arrayWithArray:data.tagArray];
    }
    if(data.locationArray.count > 0) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:data.locationArray.count];
        for (int i =0; i < data.locationArray.count; i++) {
            double value = [data.locationArray valueAtIndex:i];
            [array addObject:@(value)];
        }
        mode.location = array.copy;
    }
    mode.timestamp = data.createTime;
    mode.size = data.size;
//    if(data.sizeArray.count > 0) {
//        NSMutableArray *array = [NSMutableArray arrayWithCapacity:data.sizeArray.count];
//        for (int i = 0; i < data.sizeArray.count; i++) {
//            int value = [data.sizeArray valueAtIndex:i];
//            [array addObject:@(value)];
//        }
//        mode.size = array.copy;
//    }
    
//    mode.len = data.len;
    return mode;
}


-(BOOL)isEqualToMode:(FileModel *)fileModel {
    return [self.path isEqualToString:fileModel.path];
}


@end
