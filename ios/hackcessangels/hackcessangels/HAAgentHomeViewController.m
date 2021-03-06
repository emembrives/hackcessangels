//
//  HAAgentHomeViewController.m
//  hackcessangels
//
//  Created by Etienne Membrives on 19/05/2014.
//  Copyright (c) 2014 RIEUX Alexandre. All rights reserved.
//

#import "HAAgentHomeViewController.h"
#import "HALogViewController.h"
#import "HAAgentService.h"
#import "HARequestsService.h"
#import "HACurrentStationService.h"
#import "UIColor+HackcessAngels.h"

@interface HAAgentHomeViewController ()

@property(nonatomic, strong) HAAgentService* agentService;
@property(nonatomic, strong) HARequestsService* requestsService;

@end

@implementation HAAgentHomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void) dealloc
{
    // If you don't remove yourself as an observer, the Notification Center
    // will continue to try and send notification objects to the deallocated
    // object.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [self.tabBarController.tabBar setSelectedImageTintColor:[UIColor HA_purple]];
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor HA_graybg];
    self.helloUser.textColor = [UIColor HA_purple];
    self.requestsService = [HARequestsService sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionStatusChanged)
                                                 name:@"ConnectionStatusNotification"
                                               object:nil];
}

- (void) connectionStatusChanged {
    HACurrentStationService* service = [HACurrentStationService sharedInstance];
    self.connectedLabel.hidden = !service.connected;
    if (service.stationName) {
        self.stationLabel.text = service.stationName;
    } else {
        self.stationLabel.text = @"En dehors d'une gare";
    }
    self.stationLabel.hidden = !service.connected;
    NSLog(@"Gare: %@", self.stationLabel.text);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self checkUser];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction) verifyHelpRequests:(id)sender {
    [self.requestsService getRequests:nil failure:nil];
}

- (IBAction) createFakeHelpRequest:(id)sender {
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    localNotif.alertBody = @"quelqu'un a besoin de votre aide";
    localNotif.alertAction = @"Appel à l'aide";
    HAHelpRequest* fakeHelpRequest = [[HAHelpRequest alloc] init];
    fakeHelpRequest.user = [[HAUser alloc] init];
    NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: @"http://api.randomuser.me/portraits/women/31.jpg"]];
    fakeHelpRequest.user.image = imageData;
    fakeHelpRequest.user.name = @"Michel Martin";
    fakeHelpRequest.user.disabilityType = 7;
    fakeHelpRequest.user.description = @" blablabla hello hello hello";
    fakeHelpRequest.user.phone = @"0689637482";
    fakeHelpRequest.user.phoneUrgence = @"0493827482";
    fakeHelpRequest.latitude = 48.83938;
    fakeHelpRequest.longitude = 2.27067;
    fakeHelpRequest.Id = @"deadbeef";
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[fakeHelpRequest toPropertyList], @"helpRequest", nil];
    localNotif.userInfo = userInfo;
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
}

/******************************************************************************************************************************
 *
 * Service
 *
 *****************************************************************************************************************************/


#pragma mark - Service

- (void)checkUser
{
    self.agentService = [HAAgentService sharedInstance];
    
    [self.agentService getCurrentAgent:^(HAAgent *agent) {
        NSString *helloName = [NSString stringWithFormat:@"Bonjour %@", agent.name];
        self.helloUser.text = helloName;
        DLog(@"Success");
    } failure:^(NSError *error) {
        if (error.code == 401 || error.code == 404) {
            [self showModalLoginWithAnimation:NO];
        }
    }];
}


/******************************************************************************************************************************
 *
 * Utils
 *
 *****************************************************************************************************************************/


#pragma mark - Utils

- (void)showModalLoginWithAnimation:(BOOL)animated
{
    HALogViewController *logViewController = [[UIStoryboard storyboardWithName:@"Agent" bundle:nil] instantiateViewControllerWithIdentifier:@"loginViewController"];
    [logViewController setCheckCredentialsBlock:[[HAAgentService sharedInstance] getCheckCredentialsBlock]];
    [self presentViewController:logViewController animated:animated completion:nil];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
