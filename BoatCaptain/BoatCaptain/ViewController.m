//
//  ViewController.m
//  BoatCaptain
//
//  Created by Murray Simpson on 2018-04-19.
//  Copyright © 2018 Simpson's Helpful Software. All rights reserved.
//

#import "ViewController.h"
#import "NetworkCaptain.h"


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *m_cNetworkConnectButton;
- (IBAction)NetworkConnectPressed:(id)sender;
- (IBAction)BluetoothConnectPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *m_cIPAddress;
@property (weak, nonatomic) IBOutlet UIButton *m_cBluetoothConnectButton;
@property (weak, nonatomic) IBOutlet UILabel *m_cRAngleText;
@property (weak, nonatomic) IBOutlet UILabel *m_cPropText;
@property (weak, nonatomic) IBOutlet UIProgressView *m_cRAngle;
@property (weak, nonatomic) IBOutlet UIProgressView *m_cPropSpeed;
@property (weak, nonatomic) IBOutlet UIButton *m_cUpButton;
@property (weak, nonatomic) IBOutlet UIButton *m_cLeftButton;
@property (weak, nonatomic) IBOutlet UIButton *m_cRightButton;
@property (weak, nonatomic) IBOutlet UIButton *m_cBackButton;
@property (weak, nonatomic) IBOutlet UIButton *m_cStopButton;
@property (weak, nonatomic) IBOutlet UIImageView *m_cStopImage;
@property (weak, nonatomic) IBOutlet UIImageView *m_cHomeImage;
@property (weak, nonatomic) IBOutlet UIImageView *m_cPictureImage;
@property (weak, nonatomic) IBOutlet UILabel *m_cTopStatusText;
@property (weak, nonatomic) IBOutlet UIButton *m_cStatusButton;
@property (weak, nonatomic) IBOutlet UIButton *m_cHomeButton;
@property (weak, nonatomic) IBOutlet UIButton *m_cPictureButton;
@property (weak, nonatomic) IBOutlet UILabel *m_cStatusText;
- (IBAction)UpButtonPressed:(id)sender;
- (IBAction)LeftButtonPressed:(id)sender;
- (IBAction)RightButtonPressed:(id)sender;
- (IBAction)BackButtonPressed:(id)sender;
- (IBAction)OnStopPressed:(id)sender;
- (IBAction)StatusButtonPressed:(id)sender;
- (IBAction)OnHomePressed:(id)sender;
- (IBAction)OnPicturePressed:(id)sender;



@end

@implementation ViewController

NetworkCaptain *m_pNetCaptain = nil;
NSString *m_sIPAddr=@"";//the IP address of the boat that we are connecting to
//CBCentralManager *m_testBluetoothManager = nil;
BOOL m_bShowingHomeButton = TRUE;//true if the homing button is being shown
NSString *m_sHomingMsgStatus=@"";//text that describes whether or not the homing request was sent sucessfully
UIImage *m_boatImage=nil;//image downloaded form the boat
CLLocationManager *m_locationManager;//used for getting GPS coordinates of phone
BOOL m_bSendHomingRequest = FALSE;//flag is true when a request should be sent to the boat to return back (to the location of the phone running this program)
double m_dHomingLatitude = 0.0;//latitude angle in degrees of this phone at time of homing request to boat
double m_dHomingLongitude = 0.0;//longitude angle in degrees of this phone at time of homing request to boat
NSDate *m_lastHomingCheckTime = nil;//the time when the boat's position was last checked to see if it had reached the homing location



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [_m_cStatusText setText:@""];
    [_m_cTopStatusText setText:@""];
    [self SetupWindow];
    m_locationManager = [[CLLocationManager alloc]init];
    //test
    //m_testBluetoothManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    //end test
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)NetworkConnectPressed:(id)sender {
    NSString * sButtonText = _m_cNetworkConnectButton.titleLabel.text;
    sButtonText = [sButtonText lowercaseString];
    
    NSRange disconnectRange = [sButtonText rangeOfString:@"disconnect"];
    if (disconnectRange.length>0) {//execute disconnect from boat function
        //disconnected from boat, i.e. destroy m_pNetCaptain object
        if (m_pNetCaptain!=nil) {
            [m_pNetCaptain DisconnectFromBoat];
            m_pNetCaptain = nil;
            [self UpdateStatus:@"Disconnected from boat." popupMsg:TRUE errorMsg:FALSE];
        }
        [_m_cNetworkConnectButton setTitle:@"Connect" forState:UIControlStateNormal];
    }
    else {
        //change connect button to disconnect button
        [_m_cNetworkConnectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
        [self SaveSettings];
        if (m_pNetCaptain==nil) {
            m_pNetCaptain = [[NetworkCaptain alloc]init];
        }
        if ([m_pNetCaptain ConnectToBoat:m_sIPAddr]==FALSE) {
            //range = [_m_sLowerCaseEmailText rangeOfString:text options:NSLiteralSearch range:remainderRange];
            [self UpdateStatus:@"Error, could not connect to boat." popupMsg:TRUE errorMsg:TRUE];
            [self NetCommandFailed];
            [self hideKeyboard];
            return;
        }
        //connected to boat
        //NSString *sKey = [NSString stringWithFormat:@"ignore_folder_%03d",i+1];
        NSString *sStatusText = @"Connected to boat on ";
        sStatusText = [sStatusText stringByAppendingString:[m_pNetCaptain GetIPAddr]];
        [self UpdateStatus:sStatusText popupMsg:true errorMsg:false];
    }
    [self hideKeyboard];
}

- (IBAction)BluetoothConnectPressed:(id)sender {
    [self hideKeyboard];
}
- (IBAction)UpButtonPressed:(id)sender {
    if (m_pNetCaptain!=nil) {
        //move forward
        if (![m_pNetCaptain ForwardHo]) {
            [self NetCommandFailed];
        }
        else [self UpdatePropIndicators];//update the propeller speed indicators
    }
    /*else if (m_pBluetoothCaptain) {
        //move forward
        if (!m_pBluetoothCaptain->ForwardHo()) {
            BluetoothCommandFailed();
        }
        else UpdatePropIndicators();//update the propeller speed indicators
    }*/
    else {
        [self NoConnectionErrMsg];//display message about not being connected to the boat yet
    }
}

- (IBAction)LeftButtonPressed:(id)sender {
    if (m_pNetCaptain!=nil) {
        //turn to left
        if (![m_pNetCaptain PortHo]) {
            [self NetCommandFailed];
        }
        else [self UpdatePropIndicators];//update the propeller speed indicators
    }
    /*else if (m_pBluetoothCaptain) {
        //turn to left
        if (!m_pBluetoothCaptain->PortHo()) {
            BluetoothCommandFailed();
        }
        else UpdatePropIndicators();//update the propeller speed indicators
    }*/
    else {
        [self NoConnectionErrMsg];//display message about not being connected to the boat yet
    }
}

- (IBAction)RightButtonPressed:(id)sender {
    if (m_pNetCaptain!=nil) {
        //turn to right
        if (![m_pNetCaptain StarboardHo]) {
            [self NetCommandFailed];
        }
        else [self UpdatePropIndicators];//update the propeller speed indicators
    }
    /*else if (m_pBluetoothCaptain) {
     //turn to right
     if (!m_pBluetoothCaptain->StarboardHo()) {
     BluetoothCommandFailed();
     }
     else UpdatePropIndicators();//update the propeller speed indicators
     }*/
    else {
        [self NoConnectionErrMsg];//display message about not being connected to the boat yet
    }
}

- (IBAction)BackButtonPressed:(id)sender {
    if (m_pNetCaptain!=nil) {
        //reverse thrusters (move backwards)
        if (![m_pNetCaptain BackHo]) {
            [self NetCommandFailed];
        }
        else [self UpdatePropIndicators];//update the propeller speed indicators
    }
    /*else if (m_pBluetoothCaptain) {
        //reverse thrusters (move backwards)
        if (!m_pBluetoothCaptain->BackHo()) {
            BluetoothCommandFailed();
        }
        else UpdatePropIndicators();//update the propeller speed indicators
    }*/
    else {
        [self NoConnectionErrMsg];//display message about not being connected to the boat yet
    }
}

- (IBAction)OnStopPressed:(id)sender {
    if (m_pNetCaptain!=nil) {
        //turn to left
        if (![m_pNetCaptain Stop]) {
            [self NetCommandFailed];
        }
        else [self UpdatePropIndicators];//update the propeller speed indicators
    }
    /*else if (m_pBluetoothCaptain) {
     //turn to left
     if (!m_pBluetoothCaptain->PortHo()) {
     BluetoothCommandFailed();
     }
     else UpdatePropIndicators();//update the propeller speed indicators
     }*/
    else {
        [self NoConnectionErrMsg];//display message about not being connected to the boat yet
    }

}


- (void)SetupWindow {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *sAMOSIPAddr = [userDefaults stringForKey:@"AMOS_IPAddr"];
    if (sAMOSIPAddr!=nil) {
        [_m_cIPAddress setText:sAMOSIPAddr];
    }
    //setup propeller speed indicators
    [_m_cRAngle setProgress:0 animated:FALSE];
    [_m_cPropSpeed setProgress:0 animated:FALSE];
    _m_cRAngleText.text = @"R. Angle: 0";
    _m_cPropText.text = @"Prop Speed: 0";
    _m_cBluetoothConnectButton.hidden = YES;
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:gestureRecognizer];
}

-(void)SaveSettings {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *sAMOSIPAddr = _m_cIPAddress.text;
    [userDefaults setObject:sAMOSIPAddr forKey:@"AMOS_IPAddr"];
    m_sIPAddr = sAMOSIPAddr;
}

-(void)NetCommandFailed {
    //a network command has failed... adjust interface accordingly
    //delete current network captain
    if (m_pNetCaptain!=nil) {
        m_pNetCaptain=nil;
    }
    [_m_cNetworkConnectButton setTitle:@"Connect" forState:UIControlStateNormal];
}

-(void)BluetoothCommandFailed {//a Bluetooth command has failed...
    //don't do anything
    
}

-(void)UpdatePropIndicators {//update the propeller speed indicators
    struct PROPELLER_STATE *pPropState = NULL;
    Captain *pCaptain = [self GetCaptain];
    if (pCaptain!=nil) {
        pPropState = [pCaptain GetCurrentPropState];
    }
    float fRudderAngle = 0.0;//angle of rudder (in degrees)
    float fPropSpeed = 0.0;//propeller speed (arbitrary units)
    if (pPropState) {
        fRudderAngle = pPropState->fRudderAngle;
        fPropSpeed = pPropState->fPropSpeed;
    }
    //set propeller power progress bar controls
    float fLeftVal = .5 + .5*fRudderAngle/MAX_ANGLE;
    float fRightVal = fPropSpeed / MAX_SPEED;
    [_m_cRAngle setProgress:fLeftVal animated:FALSE];
    [_m_cPropSpeed setProgress:fRightVal animated:FALSE];
    NSString *sLeftText = [NSString stringWithFormat:@"R. Angle: %.1f",fRudderAngle];
    NSString *sRightText = [NSString stringWithFormat:@"Prop Speed: %.1f",fPropSpeed];
    _m_cRAngleText.text = sLeftText;
    _m_cPropText.text = sRightText;
    if (fRudderAngle==0.0&&fPropSpeed==0.0) {//propellers are already stopped, so stop sign can be hidden
        _m_cStopImage.hidden=TRUE;
        _m_cStopButton.hidden=TRUE;
    }
    else {
        _m_cStopImage.hidden=FALSE;
        _m_cStopButton.hidden=FALSE;
    }
}

-(Captain *) GetCaptain {//return an available captain for commanding the boat
    if (m_pNetCaptain!=nil) {
        return (Captain *)m_pNetCaptain;
    }
    /*else if (m_pBluetoothCaptain) {
        return (Captain *)m_pBluetoothCaptain;
    }*/
    return NULL;
}

-(void)NoConnectionErrMsg {//display message about not being connected to the boat yet
    [self UpdateStatus:@"Error, not connected to boat yet." popupMsg:TRUE errorMsg:TRUE];
}

-(void)UpdateStatus:(NSString *)sStatusText popupMsg:(Boolean)bShowPopupMsg errorMsg:(Boolean)bErr {//update the status text, and show an optional popup message
    _m_cStatusText.text = sStatusText;
    if (bShowPopupMsg) {
        if (bErr) {//show error popup message
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:sStatusText
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        else {//show information popup message
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
                                                            message:sStatusText
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (void) hideKeyboard {
    [self.view endEditing:YES];
}

- (IBAction)StatusButtonPressed:(id)sender {
    NSString *sGPSPosition=@"";
    NSString *sCompassData=@"";
    NSString *sDiagnosticsData=@"";
    if (m_pNetCaptain!=nil) {
        sGPSPosition = [m_pNetCaptain RequestGPSPosition];
        if (sGPSPosition==nil) {
            [self NetCommandFailed];
            return;
        }
        sCompassData = [m_pNetCaptain RequestCompassData];
        if (sCompassData==nil) {
            [self NetCommandFailed];
            return;
        }
        sDiagnosticsData = [m_pNetCaptain RequestDiagnosticsData];
        if (sDiagnosticsData==nil) {
            [self NetCommandFailed];
            return;
        }
    }
    NSString *sStatusText=[NSString stringWithFormat:@"%@, %@, %@",
                           sGPSPosition,sCompassData,sDiagnosticsData];
    _m_cTopStatusText.text = sStatusText;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Status"
                                                    message:sStatusText
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)OnHomePressed:(id)sender {
    if (m_pNetCaptain!=nil) {
        if (m_bShowingHomeButton) {//home button was pressed
            //get current GPS coordinates from phone
            int MAX_NUM_ATTEMPTS = 60;//approx. 1 second delay between attempts
            m_sHomingMsgStatus = @"";
            //check to see if location services are enabled
            BOOL bLocationServicesEnabled = [CLLocationManager locationServicesEnabled];
            if (bLocationServicesEnabled) {
                //_m_cStatusText.text = @"Location services enabled.";
            }
            else {
                //_m_cStatusText.text = @"Location services disabled.";
                return;
            }
            //start getting location
            m_locationManager.delegate = self;
            m_locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            m_locationManager.pausesLocationUpdatesAutomatically = NO;
            [m_locationManager requestWhenInUseAuthorization];
            [m_locationManager startUpdatingLocation];
            
            /*int nGPSAttemptCount = 0;
            Location captainLocation = m_gpsTracker.getLocation();
            while (captainLocation==null&&nGPSAttemptCount<MAX_NUM_ATTEMPTS) {
                try {
                    Thread.sleep(1000);
                }
                catch (Exception e) {
                    //do nothing
                }
                nGPSAttemptCount++;
                captainLocation = m_gpsTracker.getLocation();
            }
            if (captainLocation==null) return;
            m_dHomingLatitude = captainLocation.getLatitude();
            m_dHomingLongitude = captainLocation.getLongitude();*/
            
            //change home picture to "cancel home" picture
            m_bShowingHomeButton=FALSE;
            m_bSendHomingRequest=TRUE;
            UIImage *cancelImg = [UIImage imageNamed:@"xmark.png"];
            if (cancelImg!=nil) {
                [_m_cHomeImage setImage:cancelImg];
            }
            //m_cHomeButton.setBackgroundResource(R.drawable.xmark);
            //m_nTimerMode = HOMING_MODE;
            //StartTimer();
        }
        else {//cancel home function button was pressed
            m_bShowingHomeButton=TRUE;
            _m_cStatusText.text = @"";
            UIImage *homeImg = [UIImage imageNamed:@"house.png"];
            if (homeImg!=nil) {
                [_m_cHomeImage setImage:homeImg];
            }
            [m_locationManager stopUpdatingLocation];
            //send command to boat to cancel the current GPS destination (i.e. instruction to go home)
            //m_nTimerMode = CANCEL_HOMING_MODE;
            //StartTimer();
        }
    }
    else {
        [self NoConnectionErrMsg];//display message about not being connected to the boat yet
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    //NSLog(@"didUpdateToLocation: %@", newLocation);
    const double TARGET_ACCURACY_M = 30.0;//target accuracy of boat position for homing command (in m)
    const double POSCHECK_INTERVAL_SEC = 10.0;//check position of boat this often (in seconds)
    CLLocation *currentLocation = newLocation;
    
    if (currentLocation != nil) {
        NSString *sLongitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        NSString *sLatitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
        NSString *sPositionText = [NSString stringWithFormat:@"pos = %@, %@\n",sLatitude,sLongitude];
        _m_cStatusText.text = sPositionText;
        if (m_pNetCaptain!=nil) {
            
            if (m_bSendHomingRequest) {
                m_bSendHomingRequest = FALSE;
                
                if (![m_pNetCaptain ReturnHome:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude]) {
                    //problem sending homing command to boat, reset m_bSendHomingRequest flag to try again
                    m_bSendHomingRequest = TRUE;
                }
                else {
                    //command for homing was sent successfully, display message
                    NSString *sSuccessMsg = [NSString stringWithFormat:@"Command sent succesfully to bring boat home to this location: %.6f, %.6f",
                                             currentLocation.coordinate.latitude,currentLocation.coordinate.longitude];
                    _m_cTopStatusText.text = sSuccessMsg;
                    m_dHomingLatitude = currentLocation.coordinate.latitude;
                    m_dHomingLongitude = currentLocation.coordinate.longitude;
                    m_lastHomingCheckTime = [NSDate date];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Homing Request Sent"
                                                                    message:sSuccessMsg
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                    
                 }
            }
            else {
                if ([self secondsSinceLastBoatHomingCheck] >= POSCHECK_INTERVAL_SEC) {//check boat position every
                    double dBoatDist = 0.0;
                    if (([self CheckHomingBoatPos:&dBoatDist])&&dBoatDist < TARGET_ACCURACY_M) {
                        //boat has returned to its specified homing location (to within TARGET_ACCURACY_M)
                        //no need to keep getting GPS updates
                        [m_locationManager stopUpdatingLocation];
                        NSString *sSuccessMsg = [NSString stringWithFormat:@"Boat returned to target location: %.6f, %.6f",
                                                 m_dHomingLatitude,m_dHomingLongitude];
                        _m_cTopStatusText.text = sSuccessMsg;
                        m_dHomingLatitude = currentLocation.coordinate.latitude;
                        m_dHomingLongitude = currentLocation.coordinate.longitude;
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Boat returned"
                                                                        message:sSuccessMsg
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        UIImage *homeImg = [UIImage imageNamed:@"house.png"];
                        if (homeImg!=nil) {
                            [_m_cHomeImage setImage:homeImg];
                        }
                    }
                }
            }
            
        }
    }
}

- (double) secondsSinceLastBoatHomingCheck {
    if (m_lastHomingCheckTime==nil) {
        return 0.0;
    }
    NSDate *timeNow = [NSDate date];
    NSTimeInterval timeElapsed = [timeNow timeIntervalSinceDate:m_lastHomingCheckTime];
    return timeElapsed;
}

- (IBAction)OnPicturePressed:(id)sender {
    if (m_pNetCaptain==NULL) {
        [self NoConnectionErrMsg];//display message about not being connected to the boat yet
        return;
    }
    //request image capture from AMOS
    m_boatImage = [m_pNetCaptain RequestVideoImage:65536];//65536 is code for getting image without any feature detection stuff
}

-(BOOL) CheckHomingBoatPos:(double *)dBoatDist {//check distance of boat from intended homing location
    //returns true if the distance of the boat from the homing location could be obtained successfully
    if (m_pNetCaptain==nil) {
        return FALSE;
    }
    double dDistanceFromHomingLocation = [m_pNetCaptain GetBoatDistFromLocation:m_dHomingLatitude longitude:m_dHomingLongitude];
    if (dDistanceFromHomingLocation<0.0) return FALSE;
    *dBoatDist = dDistanceFromHomingLocation;
    return TRUE;
}

@end









