PushNotification
================

毎回毎回忘れるので今回はメモ！   

登場人物
-----
1. iPhone, iPad, iPod   
iPhone, iPadは手元にある端末。

2. Apple Push Notification Service (APNs)   
APNsはアップが提供するサービス。

3. Provider   
ProviderはPushしたい情報を送信するやつ（サーバー側ですかね）

手順
-----

### デバイス登録   
APNsにPush通知する端末を登録。APNsから一意のデバイストークンが発行されるので、それをProviderが持つことになる。

### アプリインストール   
アプリ起動時に端末からAPNsへデバイスの認証を通知。
APNsから認証されると、デバイストークンを受け取る。
端末からデバイストークンをProviderに送る。

### Push通知   
ProviderがPushしたい情報をAPNsに送る。APNsが認証されると、端末宛にPush通知が送られる。

### 鍵を作る   
デバイス登録手順でアプリインストール、
iPhoneからAPNsへデバイス認証通知をするためには、鍵が必要

### iOS Provisioning Portal   
https://developer.apple.com/ios/manage/overview/index.action

### 左メニューApp IDsから「New App ID」ボタンでアプリ生成   
  Description: Push Notification Sample    
  Bundle Seed ID: Use Team ID    
  Bundle Identifier: com.dongriab.ios.dev.PushNotification (ここは開発用の*ではなく一意になるものにする必要がある)   

Apps一覧で作成したAppの「Configure」リンクをクリック   
Enableにチェックを付ける。   
Development Push SSL Certificate   
Production Push SSL Certificate   
上の二つあるが、まずは、DevelopmentのConfigureボタンを押す   
Generate a Certificate Signing Request 画面が出る。   
Continue押して、次の画面へ   
通常アプリ登録時生成した CertificateSigningRequest.certSigningRequest をアップロードする   
Generate で成功することを確認。失敗したら？わかりません   
Continue押して、次の画面でDone   
戻って、Development Push SSL Certificateの方のstatusがEnabledになってることを確認。   
aps_development.cer をダウンロードしてキーチェーンに保存   
キーチェーンに「Apple Development IOS Push Services: ***」が入ってることを確認   

証明書と秘密鍵が階層になっているのでこの２つを選択   
名前は適当に   
apns_certificate.p12   

以下のコマンドでpemファイルを生成

    $ openssl pkcs12 -in apns_certificate.p12 -out apns_certificate.pem -nodes -clcerts  


apns_certificate.pemができたら、ここで作成したApp IDを指定したProvisioningファイルを作成して、Xcodeにインストール。   
code signに設定しておくことも忘れずに。   
ここでの code sign は 「iOS Team Provisioning Profile: *」は駄目でProvisioningのDevelopmentで 
上の指定した、Bundle Identifier(com.dongriab.ios.dev.***)でもう一つ生成して設定

### AppDelegate.m

### デバイストークンを受け取る
    - (void)applicationDidFinishLaunching:(UIApplication *)application {
        ...
        // デバイス認証通知
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
        (UIRemoteNotificationTypeBadge| UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }

### APNsから認証されるとデバイストークンを受け取ることができる。
認証後はUIApplicationのapplication:didRegisterForRemoteNotificationsWithDeviceToken:メソッドが呼ばれるのでそこで受け取る。   

    - (void)application:(UIApplication*)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)devToken{
        //NSLog(@"deviceToken: %@", devToken);
        NSString *deviceToken = [[[[devToken description]
                                   stringByReplacingOccurrencesOfString:@"<"withString:@""]
                                  stringByReplacingOccurrencesOfString:@">" withString:@""]
                                 stringByReplacingOccurrencesOfString: @" " withString: @""];
        [self sendProviderDeviceToken:deviceToken];
    }

### 認証エラー
    - (void)application:(UIApplication*)app didFailToRegisterForRemoteNotificationsWithError:(NSError*)err{
        NSString *text = [NSString stringWithFormat:@"didFailToRegister Error:%@",err];
        debug.text = text;
    }

### Providerにデバイストークンを送信
    - (void)sendProviderDeviceToken:(NSString *)token {
        NSMutableData *data = [NSMutableData data];
        [data appendData:[[@"device=" stringByAppendingFormat:@"%@",token] dataUsingEncoding:NSUTF8StringEncoding]];    
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                        [NSURL URLWithString:@"http://sinatra.heroku.com/push/device/"]];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];  	
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:data];
        [NSURLConnection connectionWithRequest:request delegate:self];
    }
サーバ側では、このデバイストークンをDBなりどこかに保存しておく。


### Provider側の実装。  
今回はRuby、Sinatraで実装することにする。  
Ruby, Sinatraについてはググって   
APNS gem 追加   
gem "jtv-apns" # ios push notification   

### push.rb   

    ###################
    # Hosts Config
    ###################
    
    #APNS.host = 'gateway.push.apple.com' # Production
    APNS.host = 'gateway.sandbox.push.apple.com' #Development
    
    APNS.feedback_host = 'feedback.push.apple.com'
    
    ####################
    # Certificate Setup
    ####################
    APNS.pem  = 'cert/apns_certificate.pem'
    APNS.pass = '******'
    ####################
    # Connection Mgmt
    ####################
    
    get "/push/" do
      device_token = 'bd4bc8c5 c2033f56 e0d08478 992cd783 f0bfb1ff f4787c32 b22594a6 3bce0464'
    
      n1 = [device_token, :aps => { :alert => 'Hello...', :badge => 1, :sound => 'default' }]
      n2 = [device_token, :aps => { :alert => '... iPhone!', :badge => 1, :sound => 'default' }]
      APNS.send_notifications([n1, n2])
      erb :index
    end

Enterprise in-House 配布ではでは Development の config ではなく、Production の config を設定する。




