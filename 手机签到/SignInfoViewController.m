//
//  SignInfoViewController.m
//  手机签到
//
//  Created by fred on 14-7-29.
//  Copyright (c) 2014年 fred. All rights reserved.
//

#import "SignInfoViewController.h"

@interface SignInfoViewController ()

@end


@implementation SignInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //1.设置签到历史界面背景图
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
    
    //2.启动检测网络状态
    //Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method reachabilityChanged will be called.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    internetReachability = [Reachability reachabilityForInternetConnection];
	[internetReachability startNotifier];
	[self updateInterfaceWithReachability:internetReachability];
    
    wifiReachability = [Reachability reachabilityForLocalWiFi];
	[wifiReachability startNotifier];
	[self updateInterfaceWithReachability:wifiReachability];
    
    //3.启动百度地图manager
    mapManager = [[BMKMapManager alloc]init];
    // 如果要关注网络及授权验证事件，请设定generalDelegate参数
    BOOL ret = [mapManager start:@"dMslCyqBNImFFRhtE3S1CijC"  generalDelegate:nil];
    if (!ret) {
        NSLog(@"Baidu map manager start failed!");
    }
    //定位
    locService = [[BMKLocationService alloc]init];
    //反查位置
    geoCodeSearch = [[BMKGeoCodeSearch alloc]init];
    
    
    //4.接受notice,接受RegisterViewController 发送过来的notice
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:@"mynotice" object:nil];
    
    //5.初始化播放声音
    NSString *soundFilePath = [[NSBundle mainBundle]pathForResource:@"ring1" ofType:@"mp3"];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:soundFilePath];
    AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    //[fileURL release];
    audioPlayer = newPlayer;
    //[newPlayer release];
    [audioPlayer prepareToPlay];
    [audioPlayer setDelegate:self];
    
    //6.初始化刷新按钮
    activeView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    
    //7.初始化签到信息
    signHistory = [[NSMutableString alloc ] initWithString:@""];
    
    //8.初始化标志位
    isRegistered = NO;
    canShake = YES;
    canLocation = NO;
    networkState = NO;
    
}

-(void)viewWillAppear:(BOOL)animated
{

   // if(networkState){
        //保存设备ID
        NSLog(@"唯一设备ID是:%@", [self generateUniqueDeviceID]);
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
        [dictionary setValue:[self generateUniqueDeviceID] forKey:@"deviceId"];
    
        //转换设备ID为json格式
        NSError *error;
        NSString *deviceIDPostString;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:0
                                                         error:&error];
        if (!jsonData) {
            NSLog(@"签到历史界面转换deviceID到json格式失败,error: %@", error);
            return;
        } else {
            deviceIDPostString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
            //  NSLog(@"签到历史界面deviceID转换成json后OUTPUT: %@" , deviceIDPostString);
        }
    
        //查询是否注册
        NSMutableURLRequest *searchSignRequest =[[NSMutableURLRequest alloc] initWithURL:
                                             [NSURL URLWithString:@"http://58.30.208.130:8080/registration/mobileios/getUserByMac.do"]];
    
        [searchSignRequest setHTTPMethod:@"POST"];
        [searchSignRequest setHTTPBody:[deviceIDPostString dataUsingEncoding:NSUTF8StringEncoding]];
        //必须设置下面这行,否则会返回404
        [searchSignRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [searchSignRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
        NSHTTPURLResponse* searchSignResponse = nil;
        NSError *searchSignRrror = [[NSError alloc] init];
        NSData *searchSignReceived = [NSURLConnection sendSynchronousRequest:searchSignRequest returningResponse:&searchSignResponse error:&searchSignRrror];
        NSString *searchSignResult = [[NSString alloc]initWithData:searchSignReceived encoding:NSUTF8StringEncoding];
        NSLog(@"查询是否已经注册返回结果:%@",searchSignResult);
        
        
        //结果为json格式,转换成dictionary格式
        error = nil;
        NSData *data = [searchSignResult dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableArray *array = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
        
        //[searchSignRequest autorelease];
        //[searchSignReceived autorelease];
        //[data autorelease];
        
        //默认没有注册
        isRegistered = NO;
        arrayCount = 0;

        if(error) {
            NSLog(@"转换查询注册结果为json格式失败,error,%@",error);
        }
        else {
            // NSLog(@"转换查询注册结果为json格式,内容是:%@", array);
            [signHistory setString:@""];
            for (NSMutableDictionary *dictionary in array)
            {
                if ( dictionary[@"realName"] != [NSNull null] ){
                    isRegistered = YES;
                    arrayCount++;
                    NSLog(@"arrcount=%d,arraycount=%lu", arrayCount, (unsigned long)[array count]);
                    if(arrayCount == [array count]){
                        r_UserId = [dictionary[@"r_UserId"] copy];
                        realName = [dictionary[@"realName"]copy];
                        company = [dictionary[@"company"] copy];
                        registration = [dictionary[@"registration"] copy];
                    }
                    if( dictionary[@"locateTime"] != [NSNull null] && dictionary[@"locateAddr"] != [NSNull null]
                       && dictionary[@"registration"] != [NSNull null] )
                    {
                        [signHistory appendString:@"签到时间是["];
                        [signHistory appendString:dictionary[@"locateTime"]];
                        [signHistory appendString:@"]客户关系是["];
                        [signHistory appendString:dictionary[@"registration"]];
                        [signHistory appendString:@"]地址是["];
                        [signHistory appendString:dictionary[@"locateAddr"]];
                        [signHistory appendString:@"]\n"];
                    
                    }else{//每天的第一次摇一摇
                        [signHistory setString:@"无签到记录\n"];
                    }
                }else{
                    [signHistory setString:@"用户没有注册\n"];
                }
            }
        }
    
        NSLog(@"signHistory=%@",signHistory);
   // }
}

-(void)viewDidAppear:(BOOL)animated
{
    NSLog(@"viewDidAppear signHistory=%@",signHistory);
    [displayContent setText:signHistory];
    /*摇一摇*/
    [self becomeFirstResponder];

    //进入签到界面后首先检测用户是否已经注册,没有注册时弹出注册界面
    if(isRegistered == NO){
        //切换到第二个界面
        [self performSegueWithIdentifier:@"register" sender:self];
    }
    /*定位*/
    locService.delegate = self;
    /*反查位置*/
    geoCodeSearch.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated
{
     /*定位*/
    locService.delegate = nil;
    /*geo*/
    geoCodeSearch.delegate = nil;
}

- (void)dealloc {
    [super dealloc];
    
    if (signHistory != nil) {
        [signHistory release];
        signHistory = nil;
    }
    if (mapManager != nil) {
        [mapManager release];
        mapManager = nil;
    }
    if (geoCodeSearch != nil) {
        [geoCodeSearch release];
        geoCodeSearch = nil;
    }
     if (locService) {
        [locService release];
         locService = nil;
     }
    if(activeView){
        [activeView release];
        activeView = nil;
    }
}


-(void)viewDidUnload
{
    [locService stopUserLocationService];
    [mapManager stop];
    //释放监测网络状态占用资源
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//网络连接状态发生变化,调用此方法
- (void) reachabilityChanged:(NSNotification *)note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
	[self updateInterfaceWithReachability:curReach];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
	if (reachability == internetReachability)
	{
		[self configureTextField:displayContent reachability:reachability];
	}
    
	if (reachability == wifiReachability)
	{
		[self configureTextField:displayContent reachability:reachability];
	}
}

- (void)configureTextField:(UILabel *)textLabel reachability:(Reachability *)reachability
{
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    NSString* statusString = @"";
    
    switch (netStatus)
    {
        case NotReachable:        {
            statusString = @"网络不能访问,请查看网络设置!";
            networkState = NO;//网络不可用
            break;
        }
        case ReachableViaWWAN:
        case ReachableViaWiFi:        {
            networkState = YES;//网络可用
            break;
        }
    }
    [textLabel setText:statusString];
}

//启动百度地图manager时会检测网络和授权
- (void)onGetNetworkState:(int)iError
{
    if (0 == iError) {
        NSLog(@"联网成功");
    }
    else{
        NSLog(@"onGetNetworkState %d",iError);
    }
    
}

- (void)onGetPermissionState:(int)iError
{
    if (0 == iError) {
        NSLog(@"授权成功");
    }
    else {
        NSLog(@"onGetPermissionState %d",iError);
    }
}

//接受notice的处理方法
-(void) notificationHandler:(NSNotification *) notification{
    
    NSString * string = [notification object];
    isRegistered = string;
    [signHistory setString:@"无签到记录\n"];
}

//播放声音
- (void) audioPlayerDidFinishPlaying: (AVAudioPlayer *) player
                        successfully: (BOOL) completed {
    if (completed == YES) {
        NSLog(@"播放声音结束");
        [audioPlayer stop];
    }
}

//摇一摇的实现代码
- (BOOL)canBecomeFirstResponder {
    return YES;
}

/*
 - (void)viewDidAppear:(BOOL)animated {
 [self becomeFirstResponder]; //这句移动上面的viewDidAppear中
 }
 */

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake)
    {
        NSLog(@"检测到摇晃手机");
        if(canShake == YES){
            canShake = NO;
            //摇一摇开启定位,启动LocationService
            NSLog(@"开始定位");
            [locService startUserLocationService];
            
            //开始播放
            if(!audioPlayer.playing){
                [audioPlayer play];
            }
            
            //显示刷新进度
            activeView.center = CGPointMake(self.view.bounds.size.width/2.0f, self.view.bounds.size.height-40.0f);
            [[UIActivityIndicatorView appearance] setTintColor:[UIColor yellowColor]];
            [activeView startAnimating];
            [self.view addSubview:activeView];
        }
    }
}



//定位,实现相关delegate 处理位置信息更新
- (void)didUpdateUserLocation:(BMKUserLocation *)userLocation
{
    NSLog(@"定位成功:lat %f,long %f",userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude);
    longitude = [[NSString stringWithFormat:@"%f", userLocation.location.coordinate.longitude] copy];
    latitude = [[NSString stringWithFormat:@"%f", userLocation.location.coordinate.latitude] copy];
    
    //定位成功则停止
    [locService stopUserLocationService];
    NSLog(@"停止定位");
    
    //根据定位到得经纬度反查地理位置
    [self reverseGeocode:userLocation];
    
}

/*反查位置*/
-(void)reverseGeocode:(BMKUserLocation *)userLocation
{
 	CLLocationCoordinate2D pt = (CLLocationCoordinate2D){40.056885,116.308150};
    //CLLocationCoordinate2D pt = (CLLocationCoordinate2D){userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude};
    NSLog(@"经纬度查询位置:lat %f,long %f",userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude);
    
    BMKReverseGeoCodeOption *reverseGeocodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];
    reverseGeocodeSearchOption.reverseGeoPoint = pt;
    BOOL flag = [geoCodeSearch reverseGeoCode:reverseGeocodeSearchOption];
    [reverseGeocodeSearchOption release];
    if(flag)
    {
        NSLog(@"经纬度查询位置发送成功");
    }
    else
    {
        NSLog(@"经纬度查询位置发送失败");
    }
    
}

-(void) onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
	
    //停止刷新图标
    [activeView stopAnimating];
    
    if (error == 0) {
		BMKPointAnnotation* item = [[BMKPointAnnotation alloc]init];
		item.coordinate = result.location;
		item.title = result.address;
        NSString* titleStr;
        NSString* showmeg;
        titleStr = @"签到信息";
        showmeg = [NSString stringWithFormat:@"客户关系是[%@],签到地址[%@]", registration, item.title];
        
        locateAddr = item.title;
        
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:titleStr message:showmeg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定",nil];
        [myAlertView show];
        [myAlertView release];
		[item release];
	}
}

/*弹出框的按钮代码*/
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if(buttonIndex == 0){
        NSLog(@"取消签到");
    }else if(buttonIndex == 1){
        NSLog(@"签到");
        
        //保存签到信息
        NSMutableDictionary *my1dictionary = [[NSMutableDictionary alloc] init];
        [my1dictionary setValue:r_UserId forKey:@"r_UserId"];
        [my1dictionary setValue:longitude forKey:@"longitude"];
        [my1dictionary setValue:latitude forKey:@"latitude"];
        [my1dictionary setValue:locateAddr forKey:@"locateAddr"];
        [my1dictionary setValue:realName forKey:@"realName"];
        [my1dictionary setValue:company forKey:@"company"];
        [my1dictionary setValue:registration forKey:@"registration"];
        
        
        //转换签到信息为json格式
        NSError *error;
        NSString *addSignPostString;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:my1dictionary
                                                           options:0
                                                             error:&error];
        if (!jsonData) {
            NSLog(@"JSON error: %@", error);
            return;
        } else {
            
            addSignPostString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
            //  NSLog(@"deviceID JSON OUTPUT: %@" , deviceIDPostString);
        }
        
        //添加签到信息
        NSMutableURLRequest *addSignRequest =[[NSMutableURLRequest alloc] initWithURL:
                                              [NSURL URLWithString:@"http://58.30.208.130:8080/registration/mobileios/addUserLocate.do"]];
        [addSignRequest setHTTPMethod:@"POST"];
        [addSignRequest setHTTPBody:[addSignPostString dataUsingEncoding:NSUTF8StringEncoding]];
        //必须设置下面这行,否则会返回404
        [addSignRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [addSignRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        
        NSHTTPURLResponse* addSignResponse = nil;
        NSError *addSignRrror = [[NSError alloc] init];
        NSData *addSignReceived = [NSURLConnection sendSynchronousRequest:addSignRequest returningResponse:&addSignResponse error:&addSignRrror];
        NSString *addSignResult = [[NSString alloc]initWithData:addSignReceived encoding:NSUTF8StringEncoding];
        NSLog(@"本次签到信息是:%@",addSignResult);
        
       // [addSignPostString autorelease];
       // [addSignRequest autorelease];
       // [addSignResult autorelease];
        
        //结果为json格式,转换成dictionary格式
        error = nil;
        NSData *data = [addSignResult dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableArray *array = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        if(error) {
            NSLog(@"转换json格式error,%@",error);
        }
        else {
            // NSLog(@"%@", array);
            [signHistory setString:@""];
            for (NSMutableDictionary *dictionary in array)
            {
                
                if(dictionary[@"locateTime"] != [NSNull null] && dictionary[@"locateAddr"] != [NSNull null])
                {
                    [signHistory appendString:@"签到时间是["];
                    [signHistory appendString:dictionary[@"locateTime"]];
                    [signHistory appendString:@"]客户关系是["];
                    [signHistory appendString:dictionary[@"registration"]];
                    [signHistory appendString:@"]地址是["];
                    [signHistory appendString:dictionary[@"locateAddr"]];
                    [signHistory appendString:@"]\n"];
                    
                }
            }
            [displayContent setText:signHistory];
        }
    }
    
    //都处理完,允许再次响应摇一摇
    canShake = YES;
}

//生成deviceID
-(NSString *)generateUniqueDeviceID
{
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    NSString *registerName = [defaults objectForKey:@"registerName"];//根据键值取出registerName
    NSLog(@"用户是:%@", registerName == nil ? @"empty" :registerName);
    NSString *telNumber = [defaults objectForKey:@"telNumber"];//根据键值取出telNumber
    NSLog(@"手机号是:%@", telNumber == nil ? @"empty" :telNumber);
    
    NSString *uniqueDeviceID ;
    
    if(registerName != nil && telNumber != nil){
        uniqueDeviceID = [[[NSString alloc ]initWithFormat:@"%@_%@", registerName, telNumber] autorelease];
    }else{
        uniqueDeviceID = @"";
    }

    return uniqueDeviceID;
}

@end
