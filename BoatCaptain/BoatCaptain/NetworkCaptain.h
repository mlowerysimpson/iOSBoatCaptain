#pragma once
#import "Captain.h"

#define REMOTE_PORTNUM 81 //the remote port number of the BoatServer program that is used for communications
#define PASSCODE_TEXT "AMOS2018" //password used for connecting to AMOS

@interface NetworkCaptain : Captain
-(id)init;//constructor
-(BOOL) ConnectToBoat:(NSString *)sIPAddr;//connect to boat over network (WiFi or Internet)
-(BOOL) ForwardHo;//move forward at default speed
-(BOOL) StarboardHo;//turn to right at default speed
-(BOOL) PortHo;//turn ot left at default speed
-(BOOL) BackHo;//reverse thrusters (move backwards) at default speed
-(BOOL) Stop;//issue a stop signal to the boat to stop the propellers immediately
-(NSString *) GetIPAddr;//return the IP address of the remote boat that we are connected to
-(NSString *) RequestGPSPosition;//request the current GPS position of the boat, gets returned result as a string or nil if an error occurs
-(NSString *) RequestCompassData;//request compass data from the boat, gets returned result as a string or nil if an error occurs
-(NSString *) RequestDiagnosticsData;//request diagnostics data from the boat, gets returned result as a string or nil if an error occurs
-(void) DisconnectFromBoat;//disconnect the network connection to the boat
-(BOOL) ReturnHome:(double)dLatitude longitude:(double)dLongitude;//send command to the boat to tell it to return "home" to the specified lat, long location
-(double) GetBoatDistFromLocation:(double)dLatitudeDeg longitude:(double)dLongitudeDeg;//get distance of the boat from a particular GPS location (input parameters specify latitude and longitude in degrees)
-(UIImage *) RequestVideoImage:(int) nFeatureThreshold;//request an image capture with feature markings in it from the boat


@end

    
	
