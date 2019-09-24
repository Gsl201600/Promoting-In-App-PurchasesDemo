//
//  YostarInAppPurchase.h
//  YostarInAppPurchase
//
//  Created by Yostar on 2018/9/21.
//

#import <Foundation/Foundation.h>

@interface YostarInAppPurchase : NSObject

+ (instancetype)shareInstance;

- (void)iosPayInit:(NSString *)productlistinfo;
- (void)iosPay:(NSString *)productid;

@end
