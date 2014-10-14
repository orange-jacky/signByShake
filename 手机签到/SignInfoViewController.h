//
//  SignInfoViewController.h
//  手机签到
//
//  Created by fred on 14-7-29.
//  Copyright (c) 2014年 fred. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BMapKit.h"
#import "Reachability.h"
#import <AVFoundation/AVAudioPlayer.h>

@interface SignInfoViewController : UIViewController <BMKLocationServiceDelegate,BMKGeoCodeSearchDelegate,AVAudioPlayerDelegate>
{
    //百度地图相关
    BMKMapManager* mapManager;//地图生命周期管理器
    BMKLocationService* locService;//定位到经纬度
    BMKGeoCodeSearch* geoCodeSearch;//根据定位到的经纬度反查具体地址
    
    //查询签到返回信息,返回信息为数组
    int arrayCount;//数组第几个元素
    //数组中每一项的内容
    NSString *deviceID;
    NSString *r_UserId;
    NSString *longitude;
    NSString *latitude;
    NSString *locateAddr;
    NSString *realName;
    NSString *company;
    NSString *registration;
    
    //签到历史信息相关
    NSMutableString *signHistory;//保存签到历史信息
    IBOutlet UILabel *displayContent;//显示签到历史信息

    //播放声音相关
    AVAudioPlayer *audioPlayer;//声音播放器
    
    //网络相关
    Reachability *internetReachability;//监测3g/gprs
    Reachability *wifiReachability;//监测wifi
    
    //刷新进度相关
    UIActivityIndicatorView *activeView;//刷新进度图标

    //状态标识
    bool isRegistered;//用户是否注册,YES:已经注册,NO:没有注册
    bool canShake;//是否可以响应摇晃,YES:摇晃手机要执行动作,NO:摇晃手机不可以执行动作
    bool canLocation;//是否可以定位,YES:可以start定位,NO:不可以start定位
    bool networkState;//网络状态,YES:网络可用,NO:网络不可用
}

@end
