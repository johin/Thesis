//
//  AppDelegate.m
//  SpatialMusicMenu
//
//  Created by Jonas Hinge on 07/03/2014.
//  Copyright (c) 2014 Jonas Hinge. All rights reserved.
//

#import "AppDelegate.h"
#import "AudioMenuViewController.h"
#import "MusicViewController.h"
#import "GesturesViewController.h"
#import "NSString+IHSDeviceConnectionState.h"
#import "SMMDeviceManager.h"

#import <TSMessages/TSMessage.h>
#import <MMDrawerController/MMDrawerController.h>
#import <MMDrawerController/MMDrawerBarButtonItem.h>

@interface AppDelegate () <SMMDeviceManagerConnectionDelegate>

@property (nonatomic, strong) AudioMenuViewController *audioVC;
@property (nonatomic, strong) GesturesViewController *gesturesVC;

@property (nonatomic,strong) MMDrawerController * drawerController;

@end

// Set the DEBUG_PRINTOUT define to '1' to enable printouts of the received values
#define DEBUG_PRINTOUT      1

#if !DEBUG_PRINTOUT
#define DEBUGLog(format, ...)
#else
#define DEBUGLog(format, ...) NSLog(format, ## __VA_ARGS__)
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    _audioVC = [[AudioMenuViewController alloc] init];
    MusicViewController *musicVC = [[MusicViewController alloc] init];
    _gesturesVC = [[GesturesViewController alloc] init];
    
    // nav controller
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:_audioVC];
    
    // drawer setup
    _drawerController = [[MMDrawerController alloc] initWithCenterViewController:navController leftDrawerViewController:musicVC rightDrawerViewController:_gesturesVC];
    [_drawerController setMaximumLeftDrawerWidth:400];
    [_drawerController setMaximumRightDrawerWidth:400.0];
    [_drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeAll];
    [_drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModePanningCenterView];
    [_drawerController setShowsShadow:NO];
    
    [self.window setRootViewController:_drawerController];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [TSMessage setDefaultViewController:self.window.rootViewController];
    
    return YES;
}

- (void)makeAudioMenuViewControllerDeviceDelegate:(BOOL)active
{
    if(active)
    {
        _smmDeviceManager.delegate = _audioVC;
    }
    else
    {
        _smmDeviceManager.delegate = _gesturesVC;
    }
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
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (NSString *)translatedLabel:(NSString *)gestureLabel
{
    if([gestureLabel isEqualToString:@"ACTIVATE"])
    {
        return @"Activate";
    }
    else if([gestureLabel isEqualToString:@"NOD"])
    {
        return @"Forward";
    }
    else if([gestureLabel isEqualToString:@"SHAKE"])
    {
        return @"Back";
    }
    
    return @"__UNKNOWN";
}


#pragma mark - DeezerClient instance

- (DeezerClient *)deezerClient
{
    if(_deezerClient == nil)
    {
        _deezerClient = [[DeezerClient alloc] init];
    }
    return _deezerClient;
}

#pragma mark - PersistencyManager instance

- (PersistencyManager *)persistencyManager
{
    if(_persistencyManager == nil)
    {
        _persistencyManager = [[PersistencyManager alloc] init];
    }
    return _persistencyManager;
}


#pragma mark - Custom DeviceManager methods

- (SMMDeviceManager *)smmDeviceManager
{
    if(_smmDeviceManager == nil)
    {
        _smmDeviceManager = [[SMMDeviceManager alloc] init];
        _smmDeviceManager.connectionDelegate = self;
        [_smmDeviceManager connectToDevice];
    }
    return _smmDeviceManager;
}

- (void)smmDeviceManagerFoundAmbiguousDevices:(SMMDeviceManager *)manager
{
    // Needed when running in simulator or
    // when headset is connected via wire.
    [manager showDeviceSelection:self.window.rootViewController];
}

- (void)smmDeviceManager:(SMMDeviceManager *)manager connectedStateChanged:(IHSDeviceConnectionState)connectionState
{
    NSString* connectionString = [NSString stringFromIHSDeviceConnectionState:connectionState];
    
    // Log
    [self.persistencyManager writeToLog:[NSString stringWithFormat:@"Device connection state change: %@", connectionString]];
    
    DEBUGLog(@"%@", connectionString);
    
    // Here we will get information about the connection state.
    switch (connectionState) {
        case IHSDeviceConnectionStateConnecting:
            // Once we have initiated a connection to a headset,
            // the state will change to "Connecting".
            [TSMessage showNotificationWithTitle:@"Intelligent Headset is trying to connect..." type:TSMessageNotificationTypeMessage];
            break;
        case IHSDeviceConnectionStateConnected:
            // Fully connected
            [TSMessage showNotificationWithTitle:@"Intelligent Headset is connected"
                                            type:TSMessageNotificationTypeSuccess];
            [[NSNotificationCenter defaultCenter] postNotificationName:HEADSET_CONNECTED
                                                                object:self
                                                              userInfo:nil];
            break;
        case IHSDeviceConnectionStateConnectionFailed:
            [TSMessage showNotificationWithTitle:@"Intelligent Headset failed to connect" type:TSMessageNotificationTypeError];
            break;
        default:
            
            break;
    }
}

@end
