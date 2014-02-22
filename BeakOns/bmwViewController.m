//
//  bmwViewController.m
//  BeakOns
//
//  Created by Chad D Colby on 2/21/14.
//  Copyright (c) 2014 Byte Meets World. All rights reserved.
//

#import "bmwViewController.h"
#import "ESTBeaconManager.h"
//#import <CoreLocation/CoreLocation.h>

@interface bmwViewController () <ESTBeaconManagerDelegate>

@property (strong, nonatomic) ESTBeaconManager *beaconManager;
@property (strong, nonatomic) UIImageView *refImage;
@property (assign, nonatomic) BOOL notificationSound;
@property (strong, nonatomic) UIImageView *dotPos;
@property (strong, nonatomic) ESTBeacon *selectedBeacon;

@property (nonatomic) float dotMinPos;
@property (nonatomic) float dotRange;

@end

@implementation bmwViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    self.beaconManager.avoidUnknownStateBeacons = YES;
    
    ESTBeaconRegion *region = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID major:4326 minor:25951 identifier:@"Code.Fellow.Worskspace"];
    
    region.notifyOnEntry = YES;
    region.notifyOnExit = YES;
    region.notifyEntryStateOnDisplay = YES;
    
    [self.beaconManager startRangingBeaconsInRegion:region];
    [self.beaconManager requestStateForRegion:region];
    

    [self setUpReferenceIcon];
    [self setUpBeaconIcon];
    
}

- (void)setUpBeaconIcon
{
    self.dotPos = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"beacon1"]];
    [self.dotPos setCenter:self.view.center];
    [self.dotPos setAlpha:1.0f];
    
    self.dotMinPos = 25.f;
    self.dotRange = self.view.bounds.size.height  - 220;
    
    [self.view addSubview:self.dotPos];
}

- (void)setUpReferenceIcon
{
    self.refImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iPhone1"]];
    self.refImage.center = CGPointMake(self.view.center.x, self.view.center.y/5);
    self.refImage.alpha = 1.0f;
    
    [self.view addSubview:self.refImage];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

/*
 Test to make sure both beacon and iPhone did not wake up w/o registering one another
*/
- (void)beaconManager:(ESTBeaconManager *)manager didDetermineState:(CLRegionState)state forRegion:(ESTBeaconRegion *)region
{
    if (state == CLRegionStateInside) {
        ESTBeaconRegion *beaconRegion = (ESTBeaconRegion *)region;
        [self.beaconManager startRangingBeaconsInRegion:beaconRegion];
    }
}

- (void)beaconManager:(ESTBeaconManager *)manager didEnterRegion:(ESTBeaconRegion *)region
{
    ESTBeaconRegion *beaconRegion = (ESTBeaconRegion *)region;
    if ([beaconRegion.identifier isEqualToString:@"CodeFellowsRegion"]) {
        [self.beaconManager startRangingBeaconsInRegion:beaconRegion];

    }
        [self presentEnteringNotification];
        [self setUpBeaconIcon];
}

- (void)beaconManager:(ESTBeaconManager *)manager didExitRegion:(ESTBeaconRegion *)region
{
    ESTBeaconRegion *beaconRegion = (ESTBeaconRegion *)region;
    if ([beaconRegion.identifier isEqualToString:@"CodeFellowsRegion"]) {
        [self.beaconManager stopRangingBeaconsInRegion:beaconRegion];
    }
    [self.dotPos removeFromSuperview];
    self.view.backgroundColor = [UIColor whiteColor];
    //[self showAlertView];
    [self presentLeavingNotification];
}

- (void)showAlertView
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notice" message:@"You have left the Beacon Region" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
    
    [alert show];
    [self.dotPos removeFromSuperview];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)beaconManager:(ESTBeaconManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(ESTBeaconRegion *)region
{
    if ([beacons count] > 0) {
        
        NSLog(@">>> %@", region.identifier);
        
        if (!self.selectedBeacon) {
            self.selectedBeacon = [beacons objectAtIndex:0];
        
            [self setBackgroundColorForBeaconProximity:self.selectedBeacon.proximity];
        }
        else {
            for (ESTBeacon *beakOns in beacons) {
                
                if([self.selectedBeacon.major unsignedShortValue] == [beakOns.major unsignedShortValue] &&
                   [self.selectedBeacon.minor unsignedShortValue] == [beakOns.minor unsignedShortValue])
                {
                    self.selectedBeacon = beakOns;
                    [self setBackgroundColorForBeaconProximity:beakOns.proximity];
                }
            }
        }
        
        float distanceFactor = (((float)self.selectedBeacon.rssi + 30) / - 70);

        float resetPosition = self.dotMinPos + distanceFactor * self.dotRange;
        
        self.dotPos.center = CGPointMake(self.view.bounds.size.width/2, resetPosition);
        
    }
}

- (void)setBackgroundColorForBeaconProximity:(CLProximity)prox
{
    switch (prox) {
        case CLProximityUnknown:
            self.view.backgroundColor = [UIColor whiteColor];
            break;
            
        case CLProximityImmediate:
            self.view.backgroundColor = [UIColor redColor];
            break;
            
        case CLProximityNear:
            self.view.backgroundColor = [UIColor greenColor];
            break;
            
        case CLProximityFar:
            self.view.backgroundColor = [UIColor yellowColor];
            break;
            
        default:
            break;
    }
}

- (void)presentLeavingNotification
{
    UILocalNotification *leaveNotification = [[UILocalNotification alloc]init];
    leaveNotification.alertBody = @"You're Too Far Away";
    leaveNotification.alertAction = @"Get Your Ass Back In There";
    leaveNotification.soundName = UILocalNotificationDefaultSoundName;

    
    [[UIApplication sharedApplication] presentLocalNotificationNow:leaveNotification];
    
}

- (void)presentEnteringNotification
{
    UILocalNotification *enterNotification = [[UILocalNotification alloc] init];
    enterNotification.alertBody = @"Welcome!";
    enterNotification.alertAction = @"See More";
    enterNotification.soundName = UILocalNotificationDefaultSoundName;
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:enterNotification];
}
@end
