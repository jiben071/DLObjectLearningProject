//
//  DataBase.h
//  MessageUnit
//
//  Created by 朱志刚 on 2017/9/11.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DataBase : NSObject

+(instancetype)shareDataBase;

-(BOOL)createTable:(NSString *)sql;

-(BOOL)insertData:(NSString *)sql;

-(NSArray <NSDictionary *> *)queryData:(NSString *)sql;

-(BOOL)updateData:(NSString *)sql;

-(BOOL)deleteData:(NSString *)sql;

-(long)queryAllCount:(NSString *)sql;

-(long)lastInsertRowId;

-(int)rowsChanged;

@end
