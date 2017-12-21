//
//  Protocol.h
//  iOSLib_SyncDemo
//
//  Created by zzg on 2017/10/31.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PATH_HOST @"sync"

#define BROADCAST_LATEST_FILE_CHANGED  @"/latest_file_changed"

#define REQUEST_ADD_META_DATA           @"/add_meta_data"
#define REQUEST_START_TRANSFER_SERVER   @"/start_transfer_server"
#define REQUEST_STOP_TRANSFER_SERVER    @"/stop_transfer_server"
#define REQUEST_PULL_META_DATA          @"/pull_meta_data"
#define REQUEST_PUSH_META_DATA          @"/push_meta_data"


//#define SCHEME_NET  @"net"
//#define SCHEME_RPC  @"rpc"
//#define SCHEME_LAN  @"lan"
//#define SCHEME_WAN  @"wan"
//#define PATH_SYNC  @"sync"
//
//#define CMD_START_HTTP_SERVER  @"start_http_server"
//#define CMD_STOP_HTTP_SERVER  @"stop_http_server"
//#define CMD_PULL_META_DATA  @"pull_meta_data"
//#define CMD_PUSH_META_DATA  @"push_meta_data"

#define Consts_MODE_REPLACE  @"replace"
#define Consts_MODE_MERGE  @"merge"
#define Consts_MODE_NONE  @"none"
#define Consts_MODE_ERROR  @"error"

#define Consts_FILE_ACTION_ADD  @"add"
#define Consts_FILE_ACTION_DELETE  @"delete"
#define Consts_FILE_ACTION_RENAME  @"rename"

@interface Protocol : NSObject

@end
