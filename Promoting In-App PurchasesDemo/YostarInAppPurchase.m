//
//  YostarInAppPurchase.m
//  YostarInAppPurchase
//
//  Created by Yostar on 2018/9/21.
//

#import "YostarInAppPurchase.h"
#import <StoreKit/StoreKit.h>

@interface YostarInAppPurchase () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

// AppStore返回的SKProduct列表
@property (nonatomic, strong) NSArray * myProductList;

@end

@implementation YostarInAppPurchase

#pragma mark - 单例方法
// 禁止外部访问，同时放在静态池中
static YostarInAppPurchase *instance = nil;
+ (instancetype)shareInstance{
    // 线程锁，防止多线程访问冲突
    @synchronized(self){
        if (instance == nil) {
            instance = [[self alloc] init];
        }
    }
    return instance;
}

#pragma mark - 重载初始化方法，注册用于处理支付回调的Observer
- (instancetype)init{
    self = [super init];
    if (self) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)iosPayInit:(NSString *)productlistinfo{
    NSLog(@"SDK-**&d商品b列表&&&&&&&&:%@", productlistinfo);
    NSMutableArray *tempArr = [NSMutableArray arrayWithCapacity:6];
    [tempArr addObject:productlistinfo];
    if (0 < tempArr.count) {
        [self initWithProductIDList:tempArr];
    }else{
       NSLog(@"SDK-没有商品id");
    }
}

#pragma mark - 使用Product_ID_List初始化AppPay
- (void)initWithProductIDList:(NSArray *)array{
    if ([SKPaymentQueue canMakePayments]) {
        NSLog(@"SDK-允许程序内付费购买道具");
        [self requestProductData:array];
    }else{
        NSLog(@"SDK-不允许程序内付费购买道具");
    }
}

#pragma mark - 请求对应的产品信息
- (void)requestProductData:(NSArray *)array{
    NSLog(@"SDK----------请求对应的产品信息-----------");
    NSSet *nsset = [NSSet setWithArray:array];
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
    request.delegate = self;
    [request start];
}

- (void)iosPay:(NSString *)productid{
    [self rechargeWithProductID:productid];
}

#pragma mark - 使用苹果充值AppPay
- (void)rechargeWithProductID:(NSString *)productId{
    SKProduct *myProduct = nil;
    // 遍历AppStore返回的SKProduct列表，根据productId，找到对应的SKProduct对象
    for (SKProduct *product in self.myProductList) {
        if (product != nil && [product.productIdentifier isEqualToString:productId]) {
            myProduct = product;
        }
    }
    
    SKMutablePayment *myPayment = nil;
    if (myProduct) {
        myPayment = [SKMutablePayment paymentWithProduct:myProduct];
    }else{
        NSLog(@"SDK-未找到对应商品");
        return;
    }
    myPayment.quantity = 1;
    [[SKPaymentQueue defaultQueue] addPayment:myPayment];
}

#pragma mark - SKProductsRequestDelegate
// 必接接口
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    NSLog(@"SDK----------收到商品反馈信息----------");
    NSArray *myProducts = response.products;
    self.myProductList = myProducts;
    if (0 < [myProducts count]) {
        NSDictionary *result = @{@"R_CODE":@0, @"R_MSG":@"success", @"METHOD":@"OnPayInitNotify"};
    }else{
        NSLog(@"SDK-商品不存在");
        NSDictionary *result = @{@"R_CODE":@2, @"R_MSG":@"It doesn't exist in the STORE", @"METHOD":@"OnPayInitNotify"};
    }
    NSLog(@"SDK-可选商品数量: %lu", (unsigned long)[myProducts count]);
    // 商品信息(复验)
    // 遍历AppStore返回的SKProduct列表，根据productId，找到对应的SKProduct对象
    for (SKProduct *product in myProducts) {
        NSLog(@"SDK----------Product Info----------@");
        NSLog(@"SDK-%@", product.description);
        NSLog(@"SDK-%@", product.localizedTitle);
        NSLog(@"SDK-%@", product.localizedDescription);
        NSLog(@"SDK-%@", product.price);
        NSLog(@"SDK-%@", product.productIdentifier);
    }
}

// 弹出错误信息
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    NSLog(@"SDK----------弹出错误信息----------");
    NSDictionary *result = @{@"R_CODE":@1, @"R_MSG":@"init failed", @"METHOD":@"OnPayInitNotify"};
}

- (void)requestDidFinish:(SKRequest *)request{
    NSLog(@"SDK----------反馈商品信息结束----------");
}

#pragma mark - SKPaymentTransactionObserver
// 必接接口
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(nonnull NSArray<SKPaymentTransaction *> *)transactions{
    NSLog(@"SDK----------处理支付结果----------");
    for (SKPaymentTransaction *transaction in transactions) {
        //        self.myTransaction = transaction;
        
        switch (transaction.transactionState) {
                // 交易成功
            case SKPaymentTransactionStatePurchased:
            {
                NSLog(@"SDK----------交易成功----------");
                
                // 通知Unity交易成功
                [self completeTransaction:transaction];
            }
                break;
                // 交易失败
            case SKPaymentTransactionStateFailed:
            {
                NSLog(@"SDK----------交易失败----------");
                [self failedTransaction:transaction];
            }
                break;
                // 已经购买过该商品
            case SKPaymentTransactionStateRestored:
            {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                //                [HRGSVProgressHUD dismiss];
                NSLog(@"SDK----------已经购买过该商品----------");
            }
                break;
                // 商品已经添加进列表
            case SKPaymentTransactionStatePurchasing:
            {
                // 锁定屏幕，禁止其他操作
                //                [HRGSVProgressHUD showWithStatus:@"Loading..." maskType:SVProgressHUDMaskTypeClear];
                NSLog(@"SDK----------商品已经添加进列表----------");
            }
                break;
                
            default:
                break;
        }
    }
}

// appstore pay
- (void)completeTransaction:(SKPaymentTransaction *)transaction{
    // Encode the receiptData for receipt verification
    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];
    // ios 7.0 以下
    //    NSData *receiptData = transaction.transactionReceipt;
    NSString *receipt = [receiptData base64EncodedStringWithOptions:0];
//    NSString *accessToken = [YostarUtilits getUserDefaultsForKey:ACCESSTOKENKEY];
//    [self confirmOrder:accessToken withOrderId:transaction.payment.applicationUsername withReceiptData:receipt transaction:transaction];
    NSDictionary *result = @{@"R_CODE":@0, @"R_MSG":@"success", @"METHOD":@"OnPayNotify", @"receiptData":receipt, @"receiptInfo":@""};
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

// 交易失败
- (void)failedTransaction:(SKPaymentTransaction *)transaction{
    NSLog(@"SDK----------failedTransaction----------");
    // ***************测试*************
    NSLog(@"SDK-******交易失败错误码：：：：：%d", transaction.error.code);
    
    if (transaction.error.code == SKErrorPaymentCancelled) {
        NSLog(@"SDK----------交易取消----------");
        NSDictionary *result = @{@"R_CODE":@2, @"R_MSG":@"appstorepay cancel", @"METHOD":@"OnPayNotify", @"receiptData":@"", @"receiptInfo":@""};
    }else if (transaction.error.code != SKErrorPaymentCancelled){
        NSLog(@"SDK----------交易失败----------");
        NSDictionary *result = @{@"R_CODE":@1, @"R_MSG":@"appstorepay failed", @"METHOD":@"OnPayNotify", @"receiptData":@"", @"receiptInfo":@""};
    }
    // Remove the transaction from the payment queue
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    //    [HRGSVProgressHUD dismiss];
}

// App Store商店购买会调用这个方法，相关逻辑在这里处理
- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product{
    NSLog(@"SDK----------shouldAddStorePayment----------");
    NSLog(@"localizedDescription::%@,,localizedTitle::%@,,price::%@,,priceLocale::%@,,productIdentifier::%@", product.localizedDescription, product.localizedTitle, product.price, product.priceLocale, product.productIdentifier);
    
    NSLog(@"payment::%@", payment);
//    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
    return NO;
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error{
    NSLog(@"SDK----------恢复交易失败----------");
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue{
    // if needed
    NSLog(@"SDK----------恢复交易完成----------");
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads{
    // if needed
    NSLog(@"SDK----------更新下载----------");
}

// Sent when transactions are removed from the queue (via finishTransaction:).
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions{
    [[SKPaymentQueue defaultQueue] finishTransaction:transactions[0]];
    NSLog(@"SDK----------移除交易----------");
}

- (void)dealloc{
    // 移除监听
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

@end
