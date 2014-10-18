//
//  ViewController.m
//  iiwake-kun
//
//  Created by komji on 2014/10/18.
//  Copyright (c) 2014年 komji. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <AFNetworking.h>
#import "ViewController.h"

const float M3_LATITUDE = 35.668955;
const float M3_LONGITUDE = 139.7425;
const float STOP_DISTANCE = 1000.0;
const NSString *TWITTER_USER = @"morizyun";
const NSString *STOP_MAIL_API_URL = @"http://respondto.it/morizyun.json";
const NSString *STOP_NOTIFICATION = @"( ・∀・)ｲｲ!!わけメールを停止しました！";

@interface ViewController ()<CLLocationManagerDelegate> {
    // 会社の緯度経度
    float fco_lat;
    float fco_lon;
    BOOL alreadySend;
}

@property CLLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initializeLocationManager];
    [self intiializeConstants];
    
    // デフォルトの通知センターを取得する
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(postStopMail) name:@"postStopMail" object:nil];
}

-(void)intiializeConstants
{
    // 会社の緯度経度は、M3の緯度経度を決め打ち
    fco_lat = M3_LATITUDE;
    fco_lon = M3_LONGITUDE;
    _companyLatitude.text = [NSString stringWithFormat:@"%.10f", fco_lat];
    _companyLongitude.text = [NSString stringWithFormat:@"%.10f", fco_lon];
    
    // 現在の設定
    _notifySettings.text = [NSString stringWithFormat:@"%.0f メートル以内", STOP_DISTANCE];
    
    // 通知済フラグの初期化
    alreadySend = NO;
}

-(void)initializeLocationManager
{
    // ロケーションマネージャ生成
    if(!_locationManager){
        _locationManager = [[CLLocationManager alloc] init];
        // デリゲート設定
        _locationManager.delegate = self;
        // 精度
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        // 更新頻度
        _locationManager.distanceFilter = kCLDistanceFilterNone;
    }
    
    if( [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0 ) {
        // アプリが非アクティブな場合でも位置取得する場合
        [_locationManager requestAlwaysAuthorization];
    }
    
    if([CLLocationManager locationServicesEnabled]){
        // 位置情報取得開始
        [_locationManager startUpdatingLocation];
    }else{
        // 位置取得が許可されていない場合
    }
}


// 位置取得成功時
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"Called locationManager/didUpdatedToLocation");
    
    // 位置情報取得
    float fcu_lat = newLocation.coordinate.latitude;
    float fcu_lon = newLocation.coordinate.longitude;
    _currentLatitude.text  = [NSString stringWithFormat:@"%.10f", fcu_lat];
    _currentLongitude.text = [NSString stringWithFormat:@"%.10f", fcu_lon];

    // 経緯・緯度からCLLocationを作成
    CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:fcu_lat longitude:fcu_lon];
    CLLocation *companyLocation = [[CLLocation alloc] initWithLatitude:fco_lat longitude:fco_lon];
    
    //　距離を取得
    CLLocationDistance dist = [currentLocation distanceFromLocation:companyLocation];
    
    // 距離を画面に表示
    _distance.text = [NSString stringWithFormat:@"%.0f メートル", dist];
    
    // STOP_DISTANCE メートル 以内に到着したらメールの停止を依頼する
    if (dist < STOP_DISTANCE) {
        // メールの停止を通知センターから依頼
        NSNotification *n = [NSNotification notificationWithName:@"postStopMail" object:self];
        [[NSNotificationCenter defaultCenter] postNotification:n];
        
        // 停止したことを画面で表示
        _notification.text = [NSString stringWithFormat:@"%@", STOP_NOTIFICATION];
        
        // ロケーションマネージャ停止
        [_locationManager stopUpdatingLocation];
    }
}

// メール停止をサーバーに依頼
- (void)postStopMail
{
    if (alreadySend) {
        return;
    } else {
        alreadySend = YES;
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [[manager securityPolicy] setAllowInvalidCertificates:YES];
    
    NSString *stopMailUrl = [NSString stringWithFormat:@"%@", STOP_MAIL_API_URL];
    NSDictionary *params = @{@"twitter_user": TWITTER_USER};
    
    [manager POST:stopMailUrl parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

// 位置情報が取得失敗した場合にコール
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (error) {
        switch ([error code]) {
                // アプリでの位置情報サービスが許可されていない場合
            case kCLErrorDenied:
                NSLog(@"%@", @"このアプリは位置情報サービスが許可されていません");
                break;
            default:
                NSLog(@"%@", @"位置情報の取得に失敗しました");
                break;
        }
    }
    // 位置情報取得停止
    [_locationManager stopUpdatingLocation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
