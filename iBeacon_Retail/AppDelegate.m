//
//  AppDelegate.m
//  iBeacon_Retail
//
//  Created by ShrutiHegde on 2/27/15.
//  Copyright (c) 2015 TAVANT. All rights reserved.
//

#import "AppDelegate.h"
#import "ESTConfig.h"
#import "ESTBeaconManager.h"
#import "ESTBeaconRegion.h"
#import "OffersViewController.h"
#import "BeaconMonitoringModel.h"
#import "GlobalVariables.h"
#import "LoginViewController.h"
#import "Products.h"
#import "Offers.h"
#import "CheckoutViewController.h"


#define ESTIMOTE_PROXIMITY_UUID             [[NSUUID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D"]
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define k_SlidePixelOffset 212;


@interface AppDelegate ()<ESTBeaconManagerDelegate>
@property (nonatomic, strong) ESTBeaconRegion *region;
@property (nonatomic, strong) ESTBeaconRegion *regionSectionSpec;
@property(nonatomic,strong)ESTBeaconManager *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion *regionMenSection;
@property (nonatomic, strong) BeaconMonitoringModel *beaconOperations;
@property (nonatomic,strong) LoginViewController *loginViewController;
@property(nonatomic,strong) GlobalVariables * globals;

@end

@implementation AppDelegate
@synthesize beaconOperations,globals;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // get all prodict and offer related data app open
    globals=[GlobalVariables getInstance];
    [GlobalVariables getAllProductsFromServer];
    
    // start monitoring for beacons
    beaconOperations=[[BeaconMonitoringModel alloc] init];
    [beaconOperations startBeaconOperations];
    [self loadSlideNotifications];
    [self showMainScreen];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    if (notification)
    {
        
        NSLog(@" offer id is%@",notification.userInfo.description);
        
        // when app in backgroud and notification from beacon arrives then open product details screen
        
        CGRect mainFrame = [UIScreen mainScreen].bounds;
        UIGraphicsBeginImageContext(CGSizeMake(mainFrame.size.width, mainFrame.size.height));
        [self.window.rootViewController.view drawViewHierarchyInRect:CGRectMake(0, 0, mainFrame.size.width, mainFrame.size.height) afterScreenUpdates:YES];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        // global method to get product and offers based on offerID
        Products *prodObject=  [GlobalVariables getProductWithID:[[notification.userInfo valueForKey:@"offerID" ] intValue]];
        Offers *offerObject= [GlobalVariables getOfferWithID:[[notification.userInfo valueForKey:@"offerID" ] intValue]];
        UIApplicationState state = [UIApplication sharedApplication].applicationState;
        BOOL result = (state == UIApplicationStateActive);
        // if project object not null then check for beacon conditions
        if(prodObject){
            prodObject.prodDescription=offerObject.offerHeading;
            if(!result){
                
                ProductDetailViewController* prodDetailVC = [[ProductDetailViewController alloc] initWithNibName:@"ProductDetailViewController" bundle:nil];
                prodDetailVC.product=prodObject;
                [[SlideNavigationController sharedInstance] popToRootAndSwitchToViewController:prodDetailVC withSlideOutAnimation:NO andCompletion:nil];
                
                
            }
            else {
                // if app in use and beacon notification arrives then remove it from widget and open up the offer popup screen
                
                [self clearNotifications];
                if(offerObject.isExitOffer){
                    NSMutableArray *cartItems=[NSMutableArray arrayWithArray:[GlobalVariables getCartItems]];
                    if([cartItems count]>0 ){
                        
                        // show checkout screen with billing details
                        CheckoutViewController *checkout=[[CheckoutViewController alloc]initWithNibName:@"CheckoutViewController" bundle:[NSBundle mainBundle] ];
                        [self.window.rootViewController presentViewController:checkout animated:NO completion:nil];
                    }
                    else if(![cartItems count]>0 ){// when app in foreground and cart empty and user exits
                        [self clearNotifications];
                        
                        [globals showOfferPopUp:prodObject andMessage:[notification.userInfo valueForKey:@"offerHeader" ]
                                   onController:self.window.rootViewController withImage:image];
                    }
                }
                else{
                    [globals showOfferPopUp:prodObject andMessage:[notification.userInfo valueForKey:@"offerHeader" ]
                               onController:self.window.rootViewController withImage:image];
                    
                }
                
                
            }
        }
        
    }
}

-(BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler{
//    NSDictionary *userInfo = (NSDictionary*)userActivity.userInfo;
    NSDictionary* activityInfo = [userActivity.userInfo objectForKey:TavantIBeaconRetailContinutiyScreenData];
    NSArray* cartItems = [activityInfo objectForKey:@"cartItems"];
    if(cartItems){
        // update/sync cart items across devices
        [GlobalVariables clearCartItems];
        [GlobalVariables updateCartItemsWithNewData:cartItems];
    }
    [self.window.rootViewController restoreUserActivityState:userActivity];
//    NSLog(@"USER INFO IS : %@",userInfo);
    return YES;
}

- (BOOL)application:(UIApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType{
    return YES;
}

-(void)application:(UIApplication *)application didFailToContinueUserActivityWithType:(NSString *)userActivityType error:(NSError *)error{
    if (error.code != NSUserCancelledError) {
        NSString* message = [NSString stringWithFormat:@"The connection to your other device may have been interrupted. Please try again.,%@",error.localizedDescription];
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Handoff Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//        UIAlertView* alertView = UIAlertView(title: "Handoff Error", message: message, delegate: nil, cancelButtonTitle: "Dismiss")
        [alertView show];
    }
}

- (void) clearNotifications {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

// global method to decide main screen
-(void) showMainScreen{
    NSUserDefaults  *defaults = [NSUserDefaults standardUserDefaults];
    
    // GlobalVariables *globals=[GlobalVariables getInstance];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    if([defaults boolForKey:@"hasALreadyLoggedIn"]) {
        self.window.rootViewController=[self loadSlideMenuInstance];
    }
    else {
        self.loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        self.window.rootViewController = self.loginViewController;
    }
    
}

-(UINavigationController*)loadSlideMenuInstance {
    
    CGRect frame = [[UIScreen mainScreen]bounds];
    
    //This is where you define the view for the left panel
    ProductViewController* rootViewControllerForSlideMenu = [[ProductViewController alloc] initWithNibName:@"ProductViewController" bundle:nil];
    
    SlideNavigationController *slideController = [[SlideNavigationController alloc] initWithRootViewController:rootViewControllerForSlideMenu];
    slideController.panGestureSideOffset=frame.size.width * .5; // to enable gesture only on half of the screen from the left edge for slide menu pangestures
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:74/255.0 green:170/255.0 blue:192/255.0 alpha:1.0]];
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"blue_sq"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[UIImage imageNamed:@"blue_sq"]];
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor],NSForegroundColorAttributeName,[UIFont fontWithName:@"AvenirNext-DemiBold" size:18.0], NSFontAttributeName, nil]];
    
    //slideController.rightMenu = menuViewController;
    
    
    
    slideController.leftMenu = [GlobalVariables getLeftMenu];
    slideController.menuRevealAnimationDuration = .18;
    slideController.avoidSwitchingToSameClassViewController = NO;
    [SlideNavigationController sharedInstance].portraitSlideOffset =frame.size.width-k_SlidePixelOffset;
    
    
    // Creating a custom bar button for right menu
    UIButton *button  = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [button setImage:[UIImage imageNamed:@"menu_icon.png"] forState:UIControlStateNormal];
    [button addTarget:[SlideNavigationController sharedInstance] action:@selector(toggleLeftMenu) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    slideController.leftBarButtonItem = leftBarButtonItem;
    
    
    UIButton *rtButton  = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [rtButton setImage:[UIImage imageNamed:@"icon_cart.png"] forState:UIControlStateNormal];
    [rtButton addTarget:[GlobalVariables getInstance] action:@selector(loadCartScreen) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rtButton];
    slideController.rightBarButtonItem = rightBarButtonItem;
    return slideController;
    
    
}

-(void)loadSlideNotifications
{
    [[NSNotificationCenter defaultCenter] addObserverForName:SlideNavigationControllerDidClose object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSString *menu = note.userInfo[@"menu"];
        NSLog(@"Closed %@", menu);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:SlideNavigationControllerDidOpen object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSString *menu = note.userInfo[@"menu"];
        NSLog(@"Opened %@", menu);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:SlideNavigationControllerDidReveal object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSString *menu = note.userInfo[@"menu"];
        NSLog(@"Revealed %@", menu);
    }];
}

@end
