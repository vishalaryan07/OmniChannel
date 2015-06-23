//
//  BeaconMonitoringModel.m
//  iBeacon_Retail
//
//  Created by shruthi on 10/03/15.
//  Copyright (c) 2015 TAVANT. All rights reserved.
//

#import "BeaconMonitoringModel.h"

#import "ESTConfig.h"
#import "ESTBeaconManager.h"
#import "ESTBeaconRegion.h"
#import "OffersViewController.h"
#import "BeaconMonitoringModel.h"
#import "GlobalVariables.h"
#import "Products.h"
#import "Offers.h"


@interface BeaconMonitoringModel ()<ESTBeaconManagerDelegate>
@property (nonatomic, strong) ESTBeaconRegion *region;
@property (nonatomic, strong) ESTBeaconRegion *regionSectionSpec;
@property (nonatomic, strong) ESTBeaconManager *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion *regionMenSection;
@property (nonatomic, strong) ESTBeaconRegion *regionWomenSection;
@property (nonatomic, strong) ESTBeaconRegion *regionKidsSection;
@property (nonatomic, assign) RegionIdentifier beaconRegion;
@property (nonatomic, strong) ESTBeaconRegion *mainEntraneRegion;
@property (nonatomic, strong) GlobalVariables *globals;
@property (nonatomic, strong) NSDictionary *dict;
@end


@implementation BeaconMonitoringModel
@synthesize dict;

- (id) init {
    if (self = [super init]) {
        
    }
    return self;
}

-(void)startBeaconOperations {
   
    [ESTConfig setupAppID:nil andAppToken:nil];
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    self.globals=[GlobalVariables getInstance];
    
    // read config values from plist and assign it to parameters
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
    dict = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSUUID *beaconId=[[NSUUID alloc] initWithUUIDString:[dict objectForKey:@"UUID"]];
    CLBeaconMajorValue majorValue=[[dict objectForKey:@"EntryBeacon_Major"] intValue];
    CLBeaconMinorValue minorValue=[[dict objectForKey:@"EntryBeacon_Minor"] intValue];
    
    // create a region for entry beacon
    self.region = [[ESTBeaconRegion alloc] initWithProximityUUID:beaconId
                                                           major:majorValue minor:minorValue identifier:@"ENTRYBEACON"
                                                         secured:NO];
    self.regionMenSection = [[ESTBeaconRegion alloc] initWithProximityUUID:beaconId
                                                                     major:[[dict objectForKey:@"MenSectionBeacon_Major"] intValue] minor:[[dict objectForKey:@"MenSectionBeacon_Minor"] intValue] identifier:@"MENSECTIONBEACON"
                                                                   secured:NO];
    self.regionWomenSection = [[ESTBeaconRegion alloc] initWithProximityUUID:beaconId
                                                                     major:[[dict objectForKey:@"WomenSectionBeacon_Major"] intValue] minor:[[dict objectForKey:@"WomenSectionBeacon_Minor"] intValue] identifier:@"WOMENSECTIONBEACON"
                                                                   secured:NO];
    self.mainEntraneRegion = [[ESTBeaconRegion alloc] initWithProximityUUID:beaconId
                                                                       major:[[dict objectForKey:@"MainEntranceBeacon_Major"] intValue] minor:[[dict objectForKey:@"MainEntranceBeacon_Minor"] intValue] identifier:@"MAINENTRANCEBEACON"
                                                                     secured:NO];
    self.regionKidsSection = [[ESTBeaconRegion alloc] initWithProximityUUID:beaconId
                                                                     major:[[dict objectForKey:@"KidSectionBeacon_Major"] intValue] minor:[[dict objectForKey:@"KidSectionBeacon_Minor"] intValue] identifier:@"KIDSECTIONBEACON"
                                                                   secured:NO];
//    self.mainEntraneRegion = [[ESTBeaconRegion alloc] initWithProximityUUID:beaconId
//                                                                      major:37372  minor:20643 identifier:@"MAINENTRANCEBEACON"
//                                                                    secured:NO];
   NSLog(@"main region is %@  Minor %@",self.mainEntraneRegion.major,self.mainEntraneRegion.minor);
    
    //settings for monitoring a region
    self.region.notifyOnEntry = YES;
    self.region.notifyOnExit = YES;
    self.regionMenSection.notifyOnEntry=YES;
    self.regionWomenSection.notifyOnEntry=YES;
    self.mainEntraneRegion.notifyOnEntry=YES;
    self.mainEntraneRegion.notifyOnExit=YES;
    self.regionKidsSection.notifyOnEntry=YES;
    [self.beaconManager requestAlwaysAuthorization];
    // commenting monitoring for now
//    [self.beaconManager startMonitoringForRegion:  self.mainEntraneRegion];
//    [self.beaconManager startMonitoringForRegion:  self.region];
//    [self.beaconManager startMonitoringForRegion:  self.regionMenSection];
//    [self.beaconManager startMonitoringForRegion:  self.regionWomenSection];
//    [self.beaconManager startMonitoringForRegion:  self.regionKidsSection];
    
    [self.beaconManager startRangingBeaconsInRegion:  self.mainEntraneRegion];
    [self.beaconManager startRangingBeaconsInRegion:  self.region];
    [self.beaconManager startRangingBeaconsInRegion:  self.regionMenSection];
    [self.beaconManager startRangingBeaconsInRegion:  self.regionWomenSection];
    [self.beaconManager startRangingBeaconsInRegion:  self.regionKidsSection];
   
}
/*
#pragma beaconmanager Delegate method
- (void)beaconManager:(ESTBeaconManager *)manager didEnterRegion:(ESTBeaconRegion *)region
{
    
   
    NSInteger offerId=0;
    NSString *offerHeading=[[NSString alloc] init];
    @synchronized(self) {
        UILocalNotification *notification = [UILocalNotification new];
        // if user is near outside beacon and he has already visted shop not that event as exit and clear all flags
        if([region.identifier isEqualToString:@"MAINENTRANCEBEACON"]) {
            self.globals.hasUsercrossedEntrance=YES;
            if(self.globals.hasUserEnteredTheStore){
                notification.alertBody = @"Thank you for visiting Us";
                offerId=5;
                offerHeading= @"Exit Offers";
                self.globals.hasUserEnteredTheStore=NO;
                self.globals.hasUserGotMenSectionOffers=NO;
                self.globals.hasUserGotWOmenSectionOffers=NO;
                self.globals.hasUserEntredEntryBeacon=NO;
                self.globals.hasUserGotKidSectionOffers=NO;
                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
            }
            
        }
        else  if([region.identifier isEqualToString:@"ENTRYBEACON" ] && !self.globals.hasUserEnteredTheStore && self.globals.hasUsercrossedEntrance){
            // else  if([region.identifier isEqualToString:@"ENTRYBEACON" ] ){
            notification.alertBody = @"Welcome to Tavant Store..Check for offers here";
             offerHeading= @"Welcome to the Store check for offers here";
            offerId=6;
         
            self.globals.hasUserEnteredTheStore=YES;
            self.globals.hasUserEntredEntryBeacon=YES;
        }
        else if([region.identifier isEqualToString:@"MENSECTIONBEACON"]&& !self.globals.hasUserGotMenSectionOffers &&  self.globals.hasUserEntredEntryBeacon ){
        //else if([region.identifier isEqualToString:@"MENSECTIONBEACON"]){
            notification.alertBody = @"Visit Men section to avail the exiting offers.";
          offerHeading= @"Welcome to Men's section!!";
            offerId=4;
           
            self.globals.hasUserGotMenSectionOffers=YES;
            
            
        }
        else if([region.identifier isEqualToString:@"WOMENSECTIONBEACON"]&& !self.globals.hasUserGotWOmenSectionOffers && self.globals.hasUserEntredEntryBeacon){
           // else if([region.identifier isEqualToString:@"WOMENSECTIONBEACON"]){
            notification.alertBody = @"Visit Women section to avail the exiting offers.";
            offerId=1;
           offerHeading= @"Welcome to Women's section!!";
            self.globals.hasUserGotWOmenSectionOffers=YES;
        }
        else if([region.identifier isEqualToString:@"KIDSECTIONBEACON"]&& !self.globals.hasUserGotKidSectionOffers && self.globals.hasUserEntredEntryBeacon){
       // else if([region.identifier isEqualToString:@"KIDSECTIONBEACON"]){
            notification.alertBody = @"Visit Kids section to avail the exiting offers.";
            offerHeading= @"Welcome to Kid's section!!";
            offerId=2;
            self.globals.hasUserGotKidSectionOffers=YES;
        }
        
        else{
            notification.alertBody=nil;
        }
        if(notification.alertBody){
           
            
            NSDictionary *userInformation=[[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%ld",(long)offerId],@"offerID",offerHeading,@"offerHeader" ,nil];
            notification.userInfo=userInformation;
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
            
        }

    }
    NSLog(@"recieved region is %@",region.identifier);
    
   
  
   }
 */

- (void)beaconManager:(ESTBeaconManager *)manager
      didRangeBeacons:(NSArray *)beacons
             inRegion:(ESTBeaconRegion *)region{
  
    NSInteger offerId=0;
    NSString *offerHeading=[[NSString alloc] init];
    for(ESTBeacon *beaconObj in beacons){
    @synchronized(self) {
        UILocalNotification *notification = [UILocalNotification new];
        // if user is near outside beacon and he has already visted shop not that event as exit and clear all flags
        if([region.identifier isEqualToString:@"MAINENTRANCEBEACON"]&&!self.globals.hasUserExited && self.globals.hasUserEnteredTheStore  && ((beaconObj.proximity==CLProximityImmediate)||(beaconObj.proximity==CLProximityNear)) ) {
            self.globals.hasUserExited=YES;
            
                notification.alertBody = @"Thank you for visiting Us";
                offerId=5;
                offerHeading= @"Offers Just For You!";
                self.globals.hasUserEnteredTheStore=NO;
                self.globals.hasUserGotMenSectionOffers=NO;
                self.globals.hasUserGotWOmenSectionOffers=NO;
                self.globals.hasUserEntredEntryBeacon=NO;
                self.globals.hasUserGotKidSectionOffers=NO;
            
                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
            
        }

        else  if([region.identifier isEqualToString:@"ENTRYBEACON" ]&& !self.globals.hasUserEntredEntryBeacon &&((beaconObj.proximity==CLProximityImmediate)||(beaconObj.proximity==CLProximityNear))){
            
            notification.alertBody = @"Welcome to Tavant Store..Check for offers here";
            offerHeading= @"Welcome to the Store check for offers here";
            offerId=6;
            
                self.globals.hasUserEnteredTheStore=YES;
                self.globals.hasUserEntredEntryBeacon=YES;
                self.globals.hasUserExited=NO;
        }
        else if([region.identifier isEqualToString:@"MENSECTIONBEACON"]&& !self.globals.hasUserGotMenSectionOffers &&self.globals.hasUserEnteredTheStore && ((beaconObj.proximity==CLProximityImmediate)||(beaconObj.proximity==CLProximityNear)) ){
           
            notification.alertBody = @"Visit Men section to avail the exiting offers.";
            offerHeading= @"Welcome to Men's section!!";
            offerId=4;
            
            self.globals.hasUserGotMenSectionOffers=YES;
            
            
        }
        else if([region.identifier isEqualToString:@"WOMENSECTIONBEACON"]&& !self.globals.hasUserGotWOmenSectionOffers && self.globals.hasUserEnteredTheStore && ((beaconObj.proximity==CLProximityImmediate)||(beaconObj.proximity==CLProximityNear))){
           
            notification.alertBody = @"Visit Women section to avail the exiting offers.";
            offerId=1;
            offerHeading= @"Welcome to Women's section!!";
            self.globals.hasUserGotWOmenSectionOffers=YES;
        }
        else if([region.identifier isEqualToString:@"KIDSECTIONBEACON"]&& !self.globals.hasUserGotKidSectionOffers  && self.globals.hasUserEnteredTheStore&& ((beaconObj.proximity==CLProximityImmediate)||(beaconObj.proximity==CLProximityNear))){
            
            notification.alertBody = @"Visit Kids section to avail the exiting offers.";
            offerHeading= @"Welcome to Kid's section!!";
            offerId=2;
            self.globals.hasUserGotKidSectionOffers=YES;
        }
        
        else{
            notification.alertBody=nil;
        }
        if(notification.alertBody && !self.globals.isUserOnTheMapScreen){
            
            
            NSDictionary *userInformation=[[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%ld",(long)offerId],@"offerID",offerHeading,@"offerHeader" ,nil];
            notification.userInfo=userInformation;
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
            
        }
        
    }
        
    NSLog(@"recieved region is %@",region.identifier);
    }
}


- (void)beaconManager:(ESTBeaconManager *)manager didExitRegion:(ESTBeaconRegion *)region
{
    
}

#pragma mark - ESTBeaconManager delegate

- (void)beaconManager:(ESTBeaconManager *)manager monitoringDidFailForRegion:(ESTBeaconRegion *)region withError:(NSError *)error
{
    UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:@"Monitoring error"
                                                        message:error.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    
    [errorView show];
}

@end


