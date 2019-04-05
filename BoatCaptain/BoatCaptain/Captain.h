#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CommandList.h"

#define DEFAULT_SPEED 3 //default speed for propeller-based commands
#define MAX_SPEED 10 //maximum speed for propeller-based commanes
#define MAX_ANGLE 45 //maximum allowed rudder angle (i.e. rudder angle allowed between -MAX_ANGLE and +MAX_ANGLE


@interface Captain : NSObject
@property struct PROPELLER_STATE m_currentPropState;//the current state of the propellers, initialize left & right to zero speed
@property struct IMU_DATASAMPLE m_compassData;//the data from the inertial measurement unit
@property int m_nNumSensorsAvailable;//the number of sensors available on the boat
@property double m_dLatitude;//latitude of boat in degrees (-90 to 90)
@property double m_dLongitude;//longitude of boat in degrees (-180 to 180)
@property time_t m_gpsTime;//timestamp of gps data packet
@property struct SENSOR_INFO m_sensorInfo;
@property float m_fWaterTemp;//temperature of water temperature sensor in deg C
@property float m_fPH;//pH measurement of water (0 to 14)
@property float m_fWaterTurbidity;//water turbidity measurement
@property float m_fBatteryVoltage;//measurement of the battery voltage in volts
@property BOOL m_bLeakDetected;//true if a leak was detected on AMOS, otherwise false
@property float m_fCurrentDraw;//the amount of current drawn by the +12V supply on AMOS (in A)
@property int m_nSolarCharging;//> 0 if AMOS is being charged by solar power, otherwise 0
@property float m_fHumidity;//the humidity inside the main enclosure of AMOS
@property float m_fHumidityTemp;//the temperature as measured by the humidity sensor in AMOS
@property float m_fWirelessRXPower;//received wireless power level (for serial wireless transceiver) at boat, measured in dBm

-(id)init;//constructor
- (struct PROPELLER_STATE *) GetCurrentPropState;//returns the current state of the propellers as a pointer to a PROPELLER_STATE structure
- (BOOL) ForwardHo:(struct PROPELLER_STATE *) pPropState;//move forward, increase forward speed (up to limit)
- (BOOL) StarboardHo:(struct PROPELLER_STATE *) propState;//move to right, increase right turning speed (up to limit)
- (BOOL) PortHo:(struct PROPELLER_STATE *) propState;//move to left, increase left turning speed (up to limit)
- (BOOL) BackHo:(struct PROPELLER_STATE *) propState;//move backward, increase backward speed (up to limit)
- (BOOL) Stop:(struct PROPELLER_STATE *) propState;//immediately stop propellers
- (void) DisplayLastSockError;//display the most recent Sockets error code
- (void) DisplayError:(NSString *)error;//display popup error message
- (struct BOAT_DATA *) CreateBoatData:(int) nDataType;//create boat
- (BOOL) ProcessBoatData:(struct BOAT_DATA *)pBoatData;//process data from boat, return true if boat data could be successfully processed
- (NSString *) FormatGPSData;//format the current GPS data as a string, ex: 45.334523� N, 62.562533� W, 2018-06-18, 17:23:00
- (NSString *) FormatCompassData;//format the current compass data as a string, ex: Heading = 175.2�, Roll = 1.4�, Pitch = 1.8�, Temp = 19.2 �C
- (NSString *) FormatLeakData;//format the received leak sensor data
- (NSString *) FormatVoltage;//format the available voltage
- (NSString *) FormatDiagnosticsData;//format the received diagnostics data

@end


