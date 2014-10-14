//
//  RegisterViewController.m
//  手机签到
//
//  Created by fred on 14-7-29.
//  Copyright (c) 2014年 fred. All rights reserved.
//

#import "RegisterViewController.h"


@interface RegisterViewController ()

@end

@implementation RegisterViewController


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
    // Do any additional setup after loading the view.
    
    //设置注册界面背景图
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"register.jpg"]];
   
    //初始化刷新按钮
    _activeView1 = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)viewDidAppear:(BOOL)animated
{
    //iOS 点击return或者点击屏幕键盘消失
    self.userName.delegate = self;
    self.telNumber.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated
{
    //iOS 点击return或者点击屏幕键盘消失
    self.userName.delegate = nil;
    self.telNumber.delegate = nil;
}


//注册界面,取消按钮的action
- (IBAction)CancelButton:(id)sender {
    //[self dismissModalViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];

}

//注册界面,注册按钮的action
- (IBAction)DoneButton:(id)sender {
    
    if(self.userName.text.length >0 && self.telNumber.text.length >0){
        
        
        //显示刷新进度
        _activeView1.center = CGPointMake(self.view.bounds.size.width/2.0f, self.view.bounds.size.height-40.0f);
        [_activeView1 startAnimating];
        [self.view addSubview:_activeView1];
        
        
        //保存注册信息
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
        [dictionary setValue:self.userName.text forKey:@"userName"];
        [dictionary setValue:self.telNumber.text forKey:@"telephony"];
        NSString *deviceID = [[[NSString alloc] initWithFormat:@"%@_%@" ,self.userName.text, self.telNumber.text] autorelease];
        [dictionary setValue:deviceID forKey:@"deviceId"];
        NSLog(@"注册界面的deviceID=%@",deviceID);
        
        //转换注册信息为json格式
        NSError *error;
        NSString *registerPostString;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                           options:0
                                                             error:&error];
        if (!jsonData) {
            NSLog(@"转换注册信息到json格式失败,error: %@", error);
        } else {
            
            registerPostString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
            NSLog(@"转换为json格式的注册信息: %@" , registerPostString);
        }
        
        
        //调用注册接口
        NSMutableURLRequest *registerRequest =[[NSMutableURLRequest alloc] initWithURL:
                                               [NSURL URLWithString:@"http://58.30.208.130:8080/registration/mobileios/getUser.do"]];
        [registerRequest setHTTPMethod:@"POST"];
        [registerRequest setHTTPBody:[registerPostString dataUsingEncoding:NSUTF8StringEncoding]];
        //必须设置下面这行,否则会返回404
        [registerRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [registerRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        NSHTTPURLResponse* registerResponse = nil;
        NSError *registerError = [[NSError alloc] init];
        NSData *registerReceived = [NSURLConnection sendSynchronousRequest:registerRequest returningResponse:&registerResponse error:&registerError];
        NSString *registerResult = [[NSString alloc]initWithData:registerReceived encoding:NSUTF8StringEncoding];
        NSLog(@"调用注册接口的返回结果:%@",registerResult);
        
        //返回结果为json格式,转换成dictionary格式
        error = nil;
        NSData *data = [registerResult dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *myDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:kNilOptions
                                                                       error:&error];
        
        //停止刷新图标
        [_activeView1 stopAnimating];
     
        if(!myDictionary) {
            NSLog(@"转换注册返回结果到Dictionary格式失败,error,%@",error);
        }
        else {
            //Do Something
            NSLog(@"转换注册返回结果到Dictionary成功:%@", myDictionary);
            NSString *state = [myDictionary objectForKey:@"success"];

            if([state isEqualToString:@"true"]) {
                NSLog(@"注册成功");
                //保存用户注册信息

                NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
                [defaults setObject:self.userName.text forKey:@"registerName"];
                [defaults setObject:self.telNumber.text forKey:@"telNumber"];
                [defaults synchronize];//用synchronize方法把数据持久化到standardUserDefaults数据库
                
                //发送notice信息,通知SignInfoViewController注册成功
                [[NSNotificationCenter defaultCenter] postNotificationName:@"mynotice" object:@"YES"];
                //退出注册界面
               // [self dismissModalViewControllerAnimated:YES];
                [self dismissViewControllerAnimated:YES completion:nil];
                
                
            }else if([state isEqualToString:@"false"]){
                NSLog(@"注册失败");
                NSString* titleStr;
                NSString* showmeg;
                titleStr = @"";
                showmeg = [NSString stringWithFormat:@"%@",@"注册失败,请检测用户名,电话号是否正确;如果正确,请联系管理员添加后台信息."];
                
                UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:titleStr message:showmeg delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定",nil];
                [myAlertView show];
                [myAlertView release];
            }
        }
        [registerRequest autorelease];
        [registerResult autorelease];
        [dictionary release];
        [registerPostString release];
        
    }else{
        NSString* titleStr;
        NSString* showmeg;
        titleStr = @"";
        showmeg = [NSString stringWithFormat:@"%@",@"注册用户或者手机号为空,请重新填写注册信息"];
        
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:titleStr message:showmeg delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定",nil];
        [myAlertView show];
        [myAlertView release];
    }
    
}

- (void)dealloc {
    [super dealloc];
    
    if(_activeView1){
        [_activeView1 release];
        _activeView1 = nil;
    }
}

//iOS 点击return或者点击屏幕键盘消失
//点击return 按钮 去掉
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}
//点击屏幕空白处去掉键盘
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.userName resignFirstResponder];
    [self.telNumber resignFirstResponder];
}

@end
