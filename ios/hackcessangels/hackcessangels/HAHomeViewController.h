//
//  ViewController.h
//  HackcessAngels
//
//  Created by RIEUX Alexandre on 15/01/2014.
//  Copyright (c) 2014 RIEUX Alexandre. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HATileOverlay.h"

#import "AFNetworking.h"

@interface HAHomeViewController : UIViewController <MKMapViewDelegate> 

@property (nonatomic, strong) HATileOverlay *overlay;
@property (nonatomic, weak) IBOutlet MKMapView *map;


@end