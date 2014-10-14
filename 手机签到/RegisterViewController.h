//
//  RegisterViewController.h
//  手机签到
//
//  Created by fred on 14-7-29.
//  Copyright (c) 2014年 fred. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RegisterViewController : UIViewController<UITextFieldDelegate>

@property (retain, nonatomic) IBOutlet UITextField *userName;
@property (retain, nonatomic) IBOutlet UITextField *telNumber;
@property (retain, nonatomic) UIActivityIndicatorView *activeView1;//刷新进度

@end
