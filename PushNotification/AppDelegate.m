//
//  AppDelegate.m
//  PushNotification
//
//  Created by jin dongri on 12/05/31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize debug;

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, 320, 50)];
    label.font = [UIFont fontWithName:@"AppleGothic" size:20];
    label.text = @"Push Notification";
    
    debug = [[UILabel alloc] initWithFrame:CGRectMake(10, 70, 320, 100)];
    [debug setLineBreakMode:UILineBreakModeWordWrap];//改行モード
    [debug setNumberOfLines:0];
    [self.window addSubview:label];
    [self.window addSubview:debug];
    
    // Push
    // デバイス認証通知
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeBadge| UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


// Push
// 認証されたデバイストークンを受け取る
- (void)application:(UIApplication*)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)devToken{
    //NSLog(@"deviceToken: %@", devToken);
    NSString *deviceToken = [[[[devToken description]
                               stringByReplacingOccurrencesOfString:@"<"withString:@""]
                              stringByReplacingOccurrencesOfString:@">" withString:@""]
                             stringByReplacingOccurrencesOfString: @" " withString: @""];
    [self sendProviderDeviceToken:deviceToken];
}

// 認証エラー
- (void)application:(UIApplication*)app didFailToRegisterForRemoteNotificationsWithError:(NSError*)err{
    NSString *text = [NSString stringWithFormat:@"didFailToRegister Error:%@",err];
    debug.text = text;
}

// Providerにデバイストークンを送信
- (void)sendProviderDeviceToken:(NSString *)token {
    NSMutableData *data = [NSMutableData data];
    NSString *params = [NSString stringWithFormat:@"user_id=%@&token=%@",@"7329732",token];
    [data appendData:[params dataUsingEncoding:NSUTF8StringEncoding]];    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                    [NSURL URLWithString:@"http://sinatra.heroku.com/push/device/"]];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];		
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
	int statusCode = [res statusCode];
    NSString *text = [NSString stringWithFormat:@"SendProviderDeviceToken status code = %d",statusCode];
    debug.text = text;
    
}
- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error{
    NSString *text = [NSString stringWithFormat:@"SendProviderDeviceToken error %@",error];
    debug.text = text;
}

// Received Push Notification 
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSString *text = [NSString stringWithFormat:@"From Push Notification!"];
    debug.text = text;
}

@end
