//
//  UBTBLEListModel.h
//  Alexa_iOS
//
//  Created by 姚 on 2017/7/17.
//  Copyright © 2017年 UBT. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, UBTBLELoadingType) {
    UBTBLEUnLoad,
    UBTBLELoading,
    UBTBLELoadFail,
};

@interface UBTBLEListModel : NSObject

@property (nonatomic, copy) NSString *name;/**< 蓝牙名称 */
@property (nonatomic, copy) NSString *uuid;/**< 蓝牙UUID */
@property (nonatomic, copy) NSString *rssi;/**< 信号强度 */
@property (nonatomic, copy) NSString *serial;/**< 设备序列号 */

@property (nonatomic, copy) NSString *bluetoothVersion; /**< 蓝牙版本号 */
@property (nonatomic, copy) NSString *distance;/**< 距离 */

@property (nonatomic,assign) UBTBLELoadingType loadState;

@end

