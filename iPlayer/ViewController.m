//
//  ViewController.m
//  iPlayer
//
//  Created by binhdocco on 10/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "ZipArchive.h"

@implementation ViewController
@synthesize webview;

- (void) login {
    
    // NSLog(@"START DOWNLOADING url: %@", downloadUrl);
    

   
    NSString *loginUrl = serverURL;
    NSString *params = [NSString stringWithFormat:@"?user=%@&pass=%@", username, password];
    
    loginUrl = [loginUrl stringByAppendingString:params];
    NSLog(@"%@", loginUrl);
  
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:loginUrl]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10    ];
    [request setHTTPMethod:@"GET"];
    
    NSURLResponse *res = nil;
    NSError *err = nil;
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request
                                               returningResponse:&res
                                                           error:&err];
    
    NSLog(@"error: %@", err);
    
    if (!err) {
        NSLog(@"check json");
        //NSString *response = [[NSString alloc] initWithBytes:[returnData bytes] length:[returnData length] encoding:NSUTF8StringEncoding];
        //NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
        
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:returnData options:nil error:&err];
        if (!err) {
            NSLog(@"jsonArray: %@", [jsonArray objectAtIndex:0]);
            NSDictionary* prezData = (NSDictionary*) [jsonArray objectAtIndex:0];
            
            tmpPersistanceData = [prezData mutableCopy];
            //NSLog(@"prezData version: %@", [prezData objectForKey:@"version"]);
            BOOL needInstall = NO;
            BOOL needUpdate = NO;
            
            NSString* oldId = [persistanceData objectForKey:@"id"];
            if (![oldId isEqualToString:@""]) {
                NSString* oldVersion = [persistanceData objectForKey:@"version"];
                NSString* newVersion = [tmpPersistanceData objectForKey:@"version"];
                NSString* newId = [tmpPersistanceData objectForKey:@"id"];
                
                if (![oldId isEqualToString: newId] || ![oldVersion isEqualToString: newVersion]) {
                    
                    NSLog(@"NEW VERSION: %@", newVersion);
                    needUpdate = YES;
                    
                } else {
                    NSLog(@"NO NEW VERSION FOUND");
                }
            } else {
                needInstall = YES;
                NSLog(@"FIRST INSTALL id: %@, version: %@", [tmpPersistanceData objectForKey:@"id"], [tmpPersistanceData objectForKey:@"version"]);
            }
            
            if (needInstall == YES) {
                //NSLog(@"START DOWNLOADING: %@", [persistanceData objectForKey:@"id"]);
                [self download:[tmpPersistanceData objectForKey:@"id"]];
            }
            
            if (needUpdate == YES) {
                //NSLog(@"START DOWNLOADING: %@", [persistanceData objectForKey:@"id"]);
                [self confirmDownload];
            }
            
            //[[NSUserDefaults standardUserDefaults] setObject:persistanceData forKey:@"PersistanceData"];
            
        } else {
            [self loginFailed];
        }
       
    } else {
        NSLog(@"%@", [err ])
        [self loginFailed];
    }
   
}

- (void) confirmDownload {

    UIAlertView *wantDown = [[UIAlertView alloc] initWithTitle:@"UPDATE" message:@"New version of presentation found! Do you want to replace ?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
    [wantDown show];
    wantDown = nil;

}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self download:[tmpPersistanceData objectForKey:@"id"]];
        
    } else {
        NSLog(@"NO");
    }
}

- (void) loginFailed {
    if (![[persistanceData objectForKey:@"id"] isEqualToString:@""]) {
        return;
    }

    //NSLog(@"loginFailed");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"NETWORK PROBLEM" message:@"Authentication failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
    alert = nil;
}

- (void) download: (NSString*) id {
    NSString* downloadUrl = serverURL;
    NSString* params = [NSString stringWithFormat:@"/download?user=%@&pass=%@&presentation_id=%@", username, password, id];
    downloadUrl = [downloadUrl stringByAppendingString:params];
    
    [myAlertView setTitle:@"DOWNLOADING"];
    [myAlertView show];
    [self startDownloadingURL:downloadUrl];
}

// DOWNLOAD
- (void) startDownloadingURL:(NSString *)fileUrl {
    // Create the request.
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:fileUrl]
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:60.0];
    
    // create the connection with the request and start loading the data
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (theConnection) {
        // Create the NSMutableData to hold the received data.
        
        NSLog(@"STARTING DOWNLOADING: %@", fileUrl);
    } else {
        NSLog(@"Inform the user that the connection failed.");
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    receivedData = [[NSMutableData alloc] init];
    dataSize = [response expectedContentLength];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
    
    if (dataSize != NSURLResponseUnknownLength) {
        float progress = ((float) [receivedData length] / (float) dataSize)*100;
        //NSLog(@"download: %f", progress);
        //[myAlertView setTitle:[NSString stringWithFormat:@"DOWNLOADING %.0f%@", progress,@"%"]];
        [myAlertView setMessage:[NSString stringWithFormat:@"%.0f%@", progress,@"%"]];
    }
    
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [myAlertView dismissWithClickedButtonIndex:0 animated:YES];
    myAlertView = nil;
    
    if (![[persistanceData objectForKey:@"id"] isEqualToString:@""]) {
        return;
    }
    
    UIAlertView* Alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Can not download the presentation" delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [Alert show];
    Alert = nil;
    
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [myAlertView setTitle:@"INSTALLING"];
    [myAlertView setMessage:@"..."];
    
    NSString * docPath =[self applicationDocumentsDirectory];
    //NSLog(@"docpath: %@", docPath);
    NSString* zipfile = [NSString stringWithFormat:@"%@.zip", prezFilename];
    docPath = [docPath stringByAppendingPathComponent: zipfile];
    [receivedData writeToFile:docPath atomically:YES];
    
    //unzip
    NSString *afileName = ( NSString *)[[zipfile componentsSeparatedByString:@"."] objectAtIndex:0];
    //[myAlertView setMessage:afileName];
    [self unzipFile:docPath fileName:afileName];
    
    
    
    //waiting for 2 seconds
	[NSTimer scheduledTimerWithTimeInterval:1.5f
									 target: self
								   selector: @selector(doHide:)
								   userInfo: nil
									repeats:NO];
    
    
    
    
    
    // release the connection, and the data object
    connection = nil;
    receivedData = nil;
    
    [self loadPresentation];
    
    
    persistanceData = [NSDictionary dictionaryWithObjectsAndKeys:
                       [tmpPersistanceData objectForKey:@"id"], @"id",
                       [tmpPersistanceData objectForKey:@"version"], @"version",
                       nil];
    
    [[NSUserDefaults standardUserDefaults] setObject:persistanceData forKey:@"PersistanceData"];
}

- (void) doHide: (NSTimer *) theTimer {
	[myAlertView dismissWithClickedButtonIndex:0 animated:YES];
    //myAlertView = nil;
    
    UIAlertView* Alert = [[UIAlertView alloc] initWithTitle:@"Install Completed"
                                                    message:nil delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [Alert show];
    Alert = nil;
   
}

- (void) unzipFile: (NSString *) fileUrl fileName: (NSString *)afileName {
    //NSLog(@"Unzipping %@", fileUrl);
	NSString *docPath = [self applicationDocumentsDirectory];
    
    docPath = [docPath stringByAppendingPathComponent:afileName];
	
    
	ZipArchive* za = [[ZipArchive alloc] init];
    
    if( [za UnzipOpenFile:fileUrl])
    {
        BOOL ret = [za UnzipFileTo:docPath overWrite:YES];
        //NSLog(@"ret: %d ", ret);
        if( NO==ret )
        {
            NSLog(@"fail to unzip");
        }
        
        [za UnzipCloseFile];
    }
    
    //delete zip file
    NSFileManager *filemgr;
    filemgr = [NSFileManager defaultManager];
    [filemgr removeItemAtPath:fileUrl error:NULL];
    
    za = nil;
    
	
}

- (NSString *) getAppPath {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"app_data"];
    //path = [path stringByAppendingString:@"/app_path/"];
    return path;
    
}

- (NSString*) applicationDocumentsDirectory
{
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return url.relativePath;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    webview.allowsInlineMediaPlayback = TRUE;
	webview.mediaPlaybackRequiresUserAction = FALSE;
    
    serverURL = @"http://192.168.1.223/rp1-12/source/api/api_dev.php/simple_presentation";
    username = @"vu";
    password = @"123456";
    prezFilename = @"presentation";
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PersistanceData"];
    
    persistanceData = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"PersistanceData"] mutableCopy];
    if (!persistanceData) {
        persistanceData = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"", @"id",
                           @"", @"version",
                           nil];
        [[NSUserDefaults standardUserDefaults] setObject:persistanceData forKey:@"PersistanceData"];
    }
    
    
    //enable webgl
    @try {
        id webDoc = [webview performSelector: @selector(_browserView)];
        id bwv = [webDoc performSelector: @selector(webView)];
        [bwv _setWebGLEnabled: YES];
        
    } @catch(NSException *e) {
        NSLog(@"WebGL not supported.");
    }
    //end enable
    myAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    //[myAlertView show];
    UIActivityIndicatorView *progress= [[UIActivityIndicatorView alloc] initWithFrame: CGRectMake(25, 50, 30, 30)];
    progress.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [progress startAnimating];
    [myAlertView addSubview:progress];
    progress = nil;
    
    NSString* pId = [persistanceData objectForKey:@"id"];
    NSLog(@"CURRENT prez id: %@", pId);
    if (![pId isEqualToString:@""]) {
        [self loadPresentation];
    }

    
    //login to check new version or new prez
    //[self login];
}

- (void) loadPresentation {
    NSString *url = [self applicationDocumentsDirectory];
    url = [url stringByAppendingPathComponent:prezFilename];
    url = [url stringByAppendingPathComponent:@"index.html"];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval: 10.0];
    
    [webview loadRequest:request];
    NSLog(@"loadPresentation: %@", url);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.webview = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
        interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        return YES;
    }
    return NO;
}

@end
