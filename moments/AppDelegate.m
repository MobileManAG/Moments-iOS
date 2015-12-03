/*******************************************************************************
 * Copyright 2015 MobileMan GmbH
 * www.mobileman.com
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ******************************************************************************/

//
//  AppDelegate.m
//  moments
//
//  Created by MobileMan GmbH on 10.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "AppDelegate.h"
//#import <Parse/Parse.h>
#import "ServiceFactory.h"
#import "UserService.h"
#import "UserSession.h"
#import "User.h"
#import "MomentsNavigationController.h"
#import "SignInViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "mom_defines.h"
#import "Haneke.h"
#import "Settings.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
     
    NSDictionary *userInfo = [launchOptions valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        NSLog(@"user info : %@", userInfo);
        NSDictionary * data = [[ServiceFactory systemService] parseBroadcastNotificationData:userInfo];
        [Settings setAppLaunchBroadcastNotificationData:data];
    }
    
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    
    [[ServiceFactory systemService] startup:application launchOptions:launchOptions];
    
    //[PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    [self initImageCache];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    self.homeViewController = [storyboard instantiateViewControllerWithIdentifier:@"homeViewController"];
    MomentsNavigationController *navigationController = [[MomentsNavigationController alloc] initWithRootViewController:self.homeViewController];
    [navigationController setNavigationBarHidden:YES];
    
    UserSession *userSession = [[ServiceFactory userService] currentSession];
    if (userSession != nil) {
        [[ServiceFactory userService] validateToken:^(NSError *error) { }];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 140, 140)];
        imageView.hnk_cacheFormat = [HNKCache sharedCache].formats[@"thumbnail"];
        [imageView hnk_setImageFromURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",@"https://graph.facebook.com/",userSession.user.facebookID,@"/picture?type=large"]]];
        
    } else {
        self.homeViewController.isShowingLogin = YES;
        SignInViewController *signInViewController = [storyboard instantiateViewControllerWithIdentifier:@"signInViewController"];
        signInViewController.delegate = self.homeViewController;
        [navigationController pushViewController:signInViewController animated:NO];
    }
    
    self.window.rootViewController = navigationController;
    
    self.backgroundViewController = [[BackgroundViewController alloc] init];
    [self.window addSubview:self.backgroundViewController.view];
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)initImageCache
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"thumbnail"];
    
    format.compressionQuality = 0.5;
    // UIImageView category default: 0.75, -[HNKCacheFormat initWithName:] default: 1.
    
    format.allowUpscaling = YES;
    // UIImageView category default: YES, -[HNKCacheFormat initWithName:] default: NO.
    
    format.diskCapacity = 10 * 1024 * 1024;
    // UIImageView category default: 10 * 1024 * 1024 (10MB), -[HNKCacheFormat initWithName:] default: 0 (no disk cache).
    
    //format.preloadPolicy = HNKPreloadPolicyLastSession;
    // Default: HNKPreloadPolicyNone.
    
    format.scaleMode = HNKScaleModeAspectFill;
    // UIImageView category default: -[UIImageView contentMode], -[HNKCacheFormat initWithName:] default: HNKScaleModeFill.
    
    format.size = CGSizeMake(80, 80);
    // UIImageView category default: -[UIImageView bounds].size, -[HNKCacheFormat initWithName:] default: CGSizeZero.
    
    /*
    format.postResizeBlock = ^UIImage* (NSString *key, UIImage *image) {
        NSString *title = [key.lastPathComponent stringByDeletingPathExtension];
        title = [title stringByReplacingOccurrencesOfString:@"sample" withString:@""];
        UIImage *modifiedImage = [image demo_imageByDrawingColoredText:title];
        return modifiedImage;
    };
    */
    
    [[HNKCache sharedCache] registerFormat:format];
    
    HNKCacheFormat *formatCall = [[HNKCacheFormat alloc] initWithName:@"call"];
    formatCall.compressionQuality = 0.5;
    formatCall.allowUpscaling = YES;
    formatCall.diskCapacity = 5 * 1024 * 1024;
    formatCall.scaleMode = HNKScaleModeAspectFill;
    formatCall.size = CGSizeMake(240, 240);
    [[HNKCache sharedCache] registerFormat:formatCall];
    
    CGSize streamImageSize = CGSizeMake(250, 250);
    HNKCacheFormat *formatStream = [[HNKCacheFormat alloc] initWithName:@"stream"];
    formatStream.compressionQuality = 0.5;
    formatStream.allowUpscaling = YES;
    formatStream.diskCapacity = 50 * 1024 * 1024;
    //formatStream.scaleMode = HNKScaleModeAspectFill;
    formatStream.size = streamImageSize;
    formatStream.preResizeBlock = ^UIImage* (NSString *key, UIImage *image) {
        return [self scaleImage:image toSizeKeepAspect:streamImageSize];
    };
    [[HNKCache sharedCache] registerFormat:formatStream];
    
}

- (UIImage*)scaleImage:(UIImage*)image toSizeKeepAspect:(CGSize)newSize {
    double ratio;
    double delta;
    CGPoint offset;
    
    CGSize sz = CGSizeMake(newSize.width, newSize.width);
    
    if (image.size.width > image.size.height) {
        ratio = newSize.width / image.size.width;
        delta = (ratio*image.size.width - ratio*image.size.height);
        offset = CGPointMake(delta/2, 0);
    } else {
        ratio = newSize.width / image.size.height;
        delta = (ratio*image.size.height - ratio*image.size.width);
        offset = CGPointMake(0, delta/2);
    }

    CGRect clipRect = CGRectMake(-offset.x, -offset.y,
                                 (ratio * image.size.width) + delta,
                                 (ratio * image.size.height) + delta);
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [image drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[ServiceFactory systemService] applicationDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.mobileman.moments" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"moments" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"moments.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark BackgroundViewController methods

- (void) didStartBroadcast
{
    [self.backgroundViewController hideGreyLayer];
}

- (void) didStopBroadcast
{
    [self.backgroundViewController showGrayLayer];
}

#pragma mark - Remote Notifications
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[ServiceFactory systemService] deviceTokenReceived:deviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[ServiceFactory systemService] didReceiveRemoteNotification:userInfo fetchCompletionHandler:nil];
}

/*
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler {
    [[ServiceFactory systemService] didReceiveRemoteNotification:userInfo fetchCompletionHandler:handler];
    
}
*/

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        NSLog(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler {
    [[ServiceFactory systemService] handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:completionHandler];
}

@end
