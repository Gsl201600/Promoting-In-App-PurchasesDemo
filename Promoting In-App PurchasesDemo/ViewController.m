//
//  ViewController.m
//  Promoting In-App PurchasesDemo
//
//  Created by Yostar on 2019/8/23.
//  Copyright © 2019 Yostar. All rights reserved.
//

#import "ViewController.h"
#import "YostarInAppPurchase.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configUI];
}

- (void)configUI{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(20, 80, self.view.bounds.size.width - 40, 44);
    btn.backgroundColor = [UIColor orangeColor];
    [btn setTitle:@"支付" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(didClcked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    [[YostarInAppPurchase shareInstance] iosPayInit:@"com.yostarjp.azurlane.diamond101"];
//    com.cn.altest1.product1
}

- (void)didClcked:(UIButton *)button{
    [[YostarInAppPurchase shareInstance] iosPay:@"com.yostarjp.azurlane.diamond101"];
}


@end
