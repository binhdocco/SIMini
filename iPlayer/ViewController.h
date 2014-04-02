//
//  ViewController.h
//  iPlayer
//
//  Created by binhdocco on 10/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface UIWebView() 
    - (void) _setWebGLEnabled: (BOOL)newValue;
@end


@interface ViewController : UIViewController <UIWebViewDelegate> {

    IBOutlet UIWebView *webview;
    
    
    NSString *serverURL;
    NSString *username;
    NSString *password;
    NSString *prezFilename;
    NSDictionary *persistanceData;
    NSDictionary *tmpPersistanceData;
    
    NSMutableData *receivedData;
    long long dataSize;
    UIAlertView *myAlertView;
}

@property(nonatomic, retain) IBOutlet UIWebView *webview;


- (NSString *) getAppPath;
- (void) login;
- (void) download: (NSString*) id;
- (void) loginFailed;

@end
