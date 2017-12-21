//
//  DataBase.m
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/11.
//  Copyright © 2017年 UBTECH. All rights reserved.
//



#import "DataBase.h"
#import "FMDB.h"

@interface DataBase(){
    FMDatabase *_db;
    FMDatabaseQueue *_queue;
}

@end

@implementation DataBase

+(instancetype)shareDataBase {
    static DataBase *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[DataBase alloc] init];
    });
    return shareInstance;
}

-(id)init {
    self = [super init];
    if(self) {
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:@"UBT_iOSLib_Sync.sqlite"];
        _db = [FMDatabase databaseWithPath:filePath];
        _queue = [FMDatabaseQueue databaseQueueWithPath:filePath];
    }
    return self;
}

-(BOOL)createTable:(NSString *)sql {
    if(!sql) {
        NSLog(@"sql is nil");
        return NO;
    }
    __block BOOL res = NO;
    [_queue inDatabase:^(FMDatabase * _Nonnull db) {
        if([_db open]) {
            res = [_db executeUpdate:sql];
            if(!res) {
                NSLog(@"error when creating db table");
            }else {
                NSLog(@"success to creating db table");
            }
            [_db close];
        } else {
            NSLog(@"error when open db");
        }

    }];
    return res;
}


-(BOOL)insertData:(NSString *)sql {
    if(!sql) {
        NSLog(@"sql is nil");
        return NO;
    }
    __block BOOL res = NO;
    [_queue inDatabase:^(FMDatabase * _Nonnull db) {
        if([_db open]) {
            res = [_db executeUpdate:sql];
            if(!res) {
                NSLog(@"error to insert data");
                
            }else {
                NSLog(@"success to insert data");
            }
            [_db close];
        }else {
            NSLog(@"error when open db");
        }
    }];
    return res;
    
}

-(long)lastInsertRowId {
    __block long num = -1;
    
    [_queue inDatabase:^(FMDatabase * _Nonnull db) {
        if([_db open]) {
            num = [_db lastInsertRowId];
        }else {
            NSLog(@"error when open db");
            num = -1;
        }
    }];
    return num;
}

-(int)rowsChanged {
    __block int num = -1;
    [_queue inDatabase:^(FMDatabase * _Nonnull db) {
        if([_db open]) {
            num = [_db changes];
        }else {
            NSLog(@"error when open db");
            num = -1;
        }
    }];
    return num;
}


-(NSArray <NSDictionary *> *)queryData:(NSString *)sql {
    if(!sql) {
        NSLog(@"sql is nil");
        return nil;
    }
    NSMutableArray *resultsArray = [NSMutableArray array];
    [_queue inDatabase:^(FMDatabase * _Nonnull db) {
        if([_db open]) {
            FMResultSet *rs = [_db executeQuery:sql];
            while([rs next]) {
                int columns = [rs columnCount];
                NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:columns];
                for (int i = 0; i < columns; i++) {
                    NSString *columnName = [rs columnNameForIndex:i];
                    id value = [rs objectForColumnIndex:i];
                    if([value isKindOfClass:[NSString class]]) {
                        [result setObject:value forKey:columnName];
                    }else if([value isKindOfClass:[NSNumber class]]) {
                        [result setObject:value forKey:columnName];
                    }else if([value isKindOfClass:[NSData class]]) {
                        [result setObject:value forKey:columnName];
                    }else if([value isKindOfClass:[NSNull class]]) {
                        [result setObject:[NSNull null] forKey:columnName];
                    }
                }
                [resultsArray addObject:result];
            }
        }else {
            NSLog(@"error when open db");
        }
    }];
    return resultsArray.copy;
}


-(BOOL)updateData:(NSString *)sql {
    if(!sql) {
        NSLog(@"sql is nil");
        return NO;
    }
   __block BOOL res = NO;
    [_queue inDatabase:^(FMDatabase * _Nonnull db) {
        if([_db open]) {
            res = [_db executeUpdate:sql];
            if(!res) {
                NSLog(@"error to update data");
            }else {
                NSLog(@"success to update data");
            }
            [_db close];
        }else {
            NSLog(@"error when open db");
        }
    }];
    return res;
}


-(BOOL)deleteData:(NSString *)sql {
    if(!sql) {
        NSLog(@"sql is nil");
        return NO;
    }
    __block BOOL res = NO;
    [_queue inDatabase:^(FMDatabase * _Nonnull db) {
        if([_db open]) {
            res = [_db executeUpdate:sql];
            if(!res) {
                NSLog(@"error to delete data");
                
            }else {
                NSLog(@"success to delete data");
                
            }
            [_db close];
        }else {
            NSLog(@"error when open db");
        }

    }];
    
    return res;
}

-(long)queryAllCount:(NSString *)sql {
    if(!sql) {
        NSLog(@"sql is nil");
        return -1;
    }
    __block long sum = -1;
    [_queue inDatabase:^(FMDatabase * _Nonnull db) {
        if([_db open]) {
            sum = [_db longForQuery:sql];
        }else {
            NSLog(@"error when open db");
            sum = -1;
        }
    }];
    return sum;
}



@end
