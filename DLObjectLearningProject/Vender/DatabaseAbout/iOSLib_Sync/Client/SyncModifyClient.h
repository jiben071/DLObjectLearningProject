//
//  SyncModifyClient.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/12.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import "SyncClient.h"
#import "ModifyTable.h"
#import "ModifyModel.h"
#import "FileModel.h"

@interface SyncModifyClient : SyncClient



+(instancetype)shareSyncModifyClient;
-(void)deleteObjWithFileModel:(FileModel *)fileModel;/**< 构造可删除的模型，以便于push到服务器进行删除数据 */
@end
