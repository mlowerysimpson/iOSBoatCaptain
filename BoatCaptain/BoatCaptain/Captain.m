//
//  Captain.m
//  BoatCaptain
//
//  Created by Murray Simpson on 2018-04-20.
//  Copyright © 2018 Simpson's Helpful Software. All rights reserved.
//

#import "Captain.h"
#import "CommandList.h"
#import "Util.h"
#import <errno.h>


@implementation Captain

struct BOAT_DATA m_mostRecentBoatData;//structure holds most recently received boat data


-(id)init {//constructor
    _m_currentPropState.fRudderAngle=0;
    _m_currentPropState.fPropSpeed=0;
    _m_nNumSensorsAvailable=0;
    _m_dLatitude=0.0;
    _m_dLongitude=0.0;
    _m_gpsTime=0;
    _m_fWaterTemp=0;
    _m_fPH=0;
    _m_fWaterTurbidity=0;
    _m_fBatteryVoltage=0;
    _m_bLeakDetected=FALSE;
    _m_fCurrentDraw=0;
    _m_nSolarCharging=0;
    _m_fHumidity=0;
    _m_fHumidityTemp=0;
    _m_fWirelessRXPower=0;
    
    memset(&_m_compassData,0,SIZEOF_IMU_DATA);
    return [super init];
}

-(BOOL) ForwardHo:(struct PROPELLER_STATE *)pPropState {//move forward, increase forward speed (up to limit)
    [self IncrementForwardSpeed];
    [self CopyCurrentPropState:pPropState];
    return TRUE;
}

-(BOOL) StarboardHo:(struct PROPELLER_STATE *)pPropState {//move to right, increase right turning speed (up to limit)
    [self IncrementRightSpeed];
    [self CopyCurrentPropState:pPropState];
    return TRUE;
}

-(BOOL) PortHo:(struct PROPELLER_STATE *)pPropState {//move to left, increase left turning speed (up to limit)
    [self IncrementLeftSpeed];
    [self CopyCurrentPropState:pPropState];
    return TRUE;
}

-(BOOL) BackHo:(struct PROPELLER_STATE *)pPropState {//move backward, increase backward speed (up to limit)
    [self IncrementBackSpeed];
    [self CopyCurrentPropState:pPropState];
    return TRUE;
}

- (BOOL) Stop:(struct PROPELLER_STATE *) propState {//immediately stop propellers
    propState->fRudderAngle=0;
    propState->fPropSpeed=0;
    _m_currentPropState.fRudderAngle=0.0;
    _m_currentPropState.fPropSpeed=0.0;
    return TRUE;
}

-(struct PROPELLER_STATE *) GetCurrentPropState {//returns the current state of the propellers as a pointer to a PROPELLER_STATE structure
    return &_m_currentPropState;
}


//functions for modifying the state of the propellers
-(void) IncrementForwardSpeed {//increase speed in forward direction for both props
    //if one or more props are negative, then just increase the speed of the negative props
    float fRudderAngle = _m_currentPropState.fRudderAngle;
    float fPropSpeed = _m_currentPropState.fPropSpeed;
    fPropSpeed++;
    if (fPropSpeed>MAX_SPEED) fPropSpeed = MAX_SPEED;
    _m_currentPropState.fRudderAngle = fRudderAngle;
    _m_currentPropState.fPropSpeed = fPropSpeed;
}

-(void) IncrementRightSpeed {//increase speed in right direction only
    float fRudderAngle = _m_currentPropState.fRudderAngle;
    float fPropSpeed = _m_currentPropState.fPropSpeed;
    fRudderAngle++;
    if (fRudderAngle>MAX_ANGLE) {
        fRudderAngle = MAX_ANGLE;
    }
    _m_currentPropState.fPropSpeed = fPropSpeed;
    _m_currentPropState.fRudderAngle = fRudderAngle;
}

-(void) IncrementLeftSpeed {//increase speed in left direction only
    float fRudderAngle = _m_currentPropState.fRudderAngle;
    float fPropSpeed = _m_currentPropState.fPropSpeed;
    fRudderAngle--;
    if (fRudderAngle<-MAX_ANGLE) {
        fRudderAngle = -MAX_ANGLE;
    }
    _m_currentPropState.fPropSpeed = fPropSpeed;
    _m_currentPropState.fRudderAngle = fRudderAngle;
}

- (void) IncrementBackSpeed {//increase speed in back direction only
    //if one or more props are positive, then just decrease the speed of the positive props
    float fRudderAngle = _m_currentPropState.fRudderAngle;
    float fPropSpeed = _m_currentPropState.fPropSpeed;
    fPropSpeed--;
    if (fPropSpeed<-MAX_SPEED) {
        fPropSpeed=-MAX_SPEED;
    }
    _m_currentPropState.fPropSpeed = fPropSpeed;
    _m_currentPropState.fRudderAngle = fRudderAngle;
}

- (void) CopyCurrentPropState:(struct PROPELLER_STATE *)pPropState {//copies the current propeller state into pPropState
    memcpy(pPropState,&_m_currentPropState,sizeof(_m_currentPropState));
}

- (void) DisplayLastSockError {//display the most recent Sockets error code
    int nLastSockError = errno;
    NSString *sSockErrMsg = [NSString stringWithFormat:@"Socket error: %d",nLastSockError];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:sSockErrMsg
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void) DisplayError:(NSString *)error {//display popup error message
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:error
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (struct BOAT_DATA *) CreateBoatData:(int) nDataType {//create boat data
    if (nDataType==GPS_DATA_PACKET) {
        m_mostRecentBoatData.nPacketType = GPS_DATA_PACKET;
        m_mostRecentBoatData.nDataSize = SIZEOF_GPS_DATA;//sizeof(GPS_DATA);
        memset(m_mostRecentBoatData.dataBytes,0,m_mostRecentBoatData.nDataSize);
        m_mostRecentBoatData.checkSum = [self CalculateChecksum: &m_mostRecentBoatData];//checksum needs to be recalculated whenever pAMOSData changes
    }
    else if (nDataType==COMPASS_DATA_PACKET) {
        m_mostRecentBoatData.nPacketType = COMPASS_DATA_PACKET;
        m_mostRecentBoatData.nDataSize = SIZEOF_IMU_DATA;//sizeof(IMU_DATASAMPLE);
        memset(m_mostRecentBoatData.dataBytes,0,m_mostRecentBoatData.nDataSize);
        m_mostRecentBoatData.checkSum = [self CalculateChecksum: &m_mostRecentBoatData];//checksum needs to be recalculated whenever pAMOSData changes
    }
    else if (nDataType==BATTVOLTAGE_DATA_PACKET) {
        m_mostRecentBoatData.nPacketType = BATTVOLTAGE_DATA_PACKET;
        m_mostRecentBoatData.nDataSize = 4;//sizeof(float);
        memset(m_mostRecentBoatData.dataBytes,0,m_mostRecentBoatData.nDataSize);
        m_mostRecentBoatData.checkSum = [self CalculateChecksum: &m_mostRecentBoatData];//checksum needs to be recalculated whenever pAMOSData changes
    }
    else if (nDataType==SUPPORTED_SENSOR_DATA) {
        m_mostRecentBoatData.nPacketType = SUPPORTED_SENSOR_DATA;
        m_mostRecentBoatData.nDataSize = 4;//sizeof(int);//just getting the number of sensors first, will then get a second packet of info later that corresponds to the actual sensor types
        memset(m_mostRecentBoatData.dataBytes,0,m_mostRecentBoatData.nDataSize);
        m_mostRecentBoatData.checkSum = [self CalculateChecksum: &m_mostRecentBoatData];//checksum needs to be recalculated whenever pAMOSData changes
    }
    else if (nDataType==SENSOR_TYPES_INFO) {
        m_mostRecentBoatData.nPacketType = SENSOR_TYPES_INFO;
        m_mostRecentBoatData.nDataSize = 0;//needs to be assigned later
        m_mostRecentBoatData.checkSum = 0;//needs to be assigned later
    }
    else if (nDataType==WATER_TEMP_DATA_PACKET) {
        m_mostRecentBoatData.nPacketType = WATER_TEMP_DATA_PACKET;
        m_mostRecentBoatData.nDataSize = 4;//sizeof(float);
        memset(m_mostRecentBoatData.dataBytes,0,m_mostRecentBoatData.nDataSize);
        m_mostRecentBoatData.checkSum = [self CalculateChecksum: &m_mostRecentBoatData];//checksum needs to be recalculated whenever pAMOSData changes
    }
    else if (nDataType==WATER_PH_DATA_PACKET) {
        m_mostRecentBoatData.nPacketType = WATER_PH_DATA_PACKET;
        m_mostRecentBoatData.nDataSize = sizeof(float);
        memset(m_mostRecentBoatData.dataBytes,0,m_mostRecentBoatData.nDataSize);
        m_mostRecentBoatData.checkSum = [self CalculateChecksum: &m_mostRecentBoatData];//checksum needs to be recalculated whenever pAMOSData changes
    }
    else if (nDataType==WATER_TURBIDITY_DATA_PACKET) {
        m_mostRecentBoatData.nPacketType = WATER_TURBIDITY_DATA_PACKET;
        m_mostRecentBoatData.nDataSize = sizeof(float);
        memset(m_mostRecentBoatData.dataBytes,0,m_mostRecentBoatData.nDataSize);
        m_mostRecentBoatData.checkSum = [self CalculateChecksum: &m_mostRecentBoatData];//checksum needs to be recalculated whenever pAMOSData changes
    }
    else if (nDataType==VIDEO_DATA_PACKET) {
        m_mostRecentBoatData.nPacketType = VIDEO_DATA_PACKET;
        m_mostRecentBoatData.nDataSize = sizeof(int);
        memset(m_mostRecentBoatData.dataBytes,0,m_mostRecentBoatData.nDataSize);
        m_mostRecentBoatData.checkSum = [self CalculateChecksum: &m_mostRecentBoatData];//checksum needs to be recalculated whenever pAMOSData changes
    }
    else if (nDataType==LEAK_DATA_PACKET) {
        m_mostRecentBoatData.nPacketType = LEAK_DATA_PACKET;
        m_mostRecentBoatData.nDataSize = sizeof(int);
        memset(m_mostRecentBoatData.dataBytes,0,m_mostRecentBoatData.nDataSize);
        m_mostRecentBoatData.checkSum = [self CalculateChecksum: &m_mostRecentBoatData];//checksum needs to be recalculated
    }
    else if (nDataType==DIAGNOSTICS_DATA_PACKET) {
        m_mostRecentBoatData.nPacketType = DIAGNOSTICS_DATA_PACKET;
        m_mostRecentBoatData.nDataSize = 24;
        memset(m_mostRecentBoatData.dataBytes,0,m_mostRecentBoatData.nDataSize);
        m_mostRecentBoatData.checkSum = [self CalculateChecksum: &m_mostRecentBoatData];//checksum needs to be recalculated
    }
    return &m_mostRecentBoatData;
}


- (unsigned char) CalculateChecksum:(struct BOAT_DATA *)pData {//calculate simple 8-bit checksum for BOAT_DATA structure
    unsigned char ucChecksum = 0;
    unsigned char *pBytes = (unsigned char *)pData;
    int nNumToCheck = 2*sizeof(int) + pData->nDataSize;
    for (int i=0;i<nNumToCheck;i++) {
        ucChecksum+=pBytes[i];
    }
    return ucChecksum;
}

-(BOOL) ProcessBoatData:(struct BOAT_DATA *)pBoatData {//process data from boat, return true if boat data could be successfully processed
    if (pBoatData->nPacketType==GPS_DATA_PACKET) {
        if (pBoatData->nDataSize!=SIZEOF_GPS_DATA) {//sizeof(GPS_DATA)) {
            return FALSE;
        }
        memcpy(&_m_dLatitude,pBoatData->dataBytes,sizeof(double));
        memcpy(&_m_dLongitude,&pBoatData->dataBytes[sizeof(double)],sizeof(double));
        time_t gpsTime;
        memcpy(&gpsTime,&pBoatData->dataBytes[2*sizeof(double)],sizeof(time_t));
        _m_gpsTime = gpsTime;
        return TRUE;
    }
    else if (pBoatData->nPacketType==COMPASS_DATA_PACKET) {
        if (pBoatData->nDataSize!=SIZEOF_IMU_DATA) {//sizeof(IMU_DATASAMPLE)) {
            return FALSE;
        }
        memcpy(&_m_compassData,pBoatData->dataBytes,SIZEOF_IMU_DATA);//sizeof(IMU_DATASAMPLE));
        return TRUE;
    }
    else if (pBoatData->nPacketType==SUPPORTED_SENSOR_DATA) {
        //reset sensor types and number of sensors
        _m_nNumSensorsAvailable = 0;
        if (pBoatData->nDataSize!=sizeof(int)) {
            return FALSE;
        }
        memcpy(&_m_nNumSensorsAvailable,pBoatData->dataBytes,sizeof(int));//calling function needs to read in additional packet to determine sensor types
        if (_m_nNumSensorsAvailable>MAX_SENSORS) {
            //something wrong, should not be this many sensors
            return FALSE;
        }
        return TRUE;
    }
    else if (pBoatData->nPacketType==SENSOR_TYPES_INFO) {
        //make sure that enough data was received to define each of the sensor types
        if (pBoatData->nDataSize!=(_m_nNumSensorsAvailable*sizeof(int))) {
            return FALSE;
        }
        for (int i=0;i<_m_nNumSensorsAvailable;i++) {
            memcpy(&_m_sensorInfo.sensorTypes[i],&pBoatData->dataBytes[4*i],sizeof(int));
        }
        return TRUE;
    }
    else if (pBoatData->nPacketType==WATER_TEMP_DATA_PACKET) {
        if (pBoatData->nDataSize!=sizeof(float)) {
            return FALSE;
        }
        _m_fWaterTemp = [Util BytesToFloat:pBoatData->dataBytes];
        return TRUE;
    }
    else if (pBoatData->nPacketType==WATER_PH_DATA_PACKET) {
        if (pBoatData->nDataSize!=sizeof(float)) {
            return FALSE;
        }
        _m_fPH = [Util BytesToFloat:pBoatData->dataBytes];
        return TRUE;
    }
    else if (pBoatData->nPacketType==WATER_TURBIDITY_DATA_PACKET) {
        if (pBoatData->nDataSize!=sizeof(float)) {
            return FALSE;
        }
        _m_fWaterTurbidity = [Util BytesToFloat:pBoatData->dataBytes];
        return TRUE;
    }
    else if (pBoatData->nPacketType==BATTVOLTAGE_DATA_PACKET) {
        if (pBoatData->nDataSize!=sizeof(float)) {
            return FALSE;
        }
        _m_fBatteryVoltage = [Util BytesToFloat:pBoatData->dataBytes];
        return TRUE;
    }
    else if (pBoatData->nPacketType==LEAK_DATA_PACKET) {
        if (pBoatData->nDataSize!=sizeof(int)) {
            return FALSE;
        }
        _m_bLeakDetected = (BOOL)[Util BytesToInt:pBoatData->dataBytes];
        return TRUE;
    }
    else if (pBoatData->nPacketType==DIAGNOSTICS_DATA_PACKET) {
        if (pBoatData->nDataSize!=24) {
            return FALSE;
        }
        _m_fBatteryVoltage = [Util BytesToFloat:pBoatData->dataBytes];
        _m_fCurrentDraw = [Util BytesToFloat:&pBoatData->dataBytes[sizeof(float)]];
        _m_fHumidity = [Util BytesToFloat:&pBoatData->dataBytes[2*sizeof(float)]];
        _m_fHumidityTemp = [Util BytesToFloat:&pBoatData->dataBytes[3*sizeof(float)]];
        _m_fWirelessRXPower = [Util BytesToFloat:&pBoatData->dataBytes[4*sizeof(float)]];
        _m_nSolarCharging = [Util BytesToInt:&pBoatData->dataBytes[5*sizeof(float)]];
        return TRUE;
    }
    return FALSE;
}

-(NSString *) FormatGPSData {//format the current GPS data as a string, ex: 45.334523� N, 62.562533� W, 2018-06-18, 17:23:00
    char szDegSymbol[2];
    szDegSymbol[0] = (char)248;
    szDegSymbol[1] = 0;
    NSString *sRetval=@"";
    NSString *sSN = @"N";
    if (_m_dLatitude<0) sSN = @"S";
    NSString *sEW = @"E";
    if (_m_dLongitude<0) sEW = @"W";
    
    if (_m_gpsTime>0) {
        struct tm *t = localtime(&_m_gpsTime);
        if (t!=nil) {
            sRetval = [NSString stringWithFormat:@"%.6f%s %@, %.6f%s %@, %d-%02d-%02d, %02d:%02d:%02d",fabs(_m_dLatitude),szDegSymbol,sSN,fabs(_m_dLongitude),szDegSymbol,sEW,t->tm_year+1900,
                       t->tm_mon+1,t->tm_mday,t->tm_hour,t->tm_min,t->tm_sec];
        }
    }
    else if (_m_gpsTime==0) {
        //gps data not available
        sRetval = @"GPS: N.A.";
    }
    return sRetval;
}

- (NSString *) FormatCompassData {//format the current compass data as a string, ex: Heading = 175.2�, Roll = 1.4�, Pitch = 1.8�, Temp = 19.2 �C
    //char szDegSymbol[2];
    //szDegSymbol[0] = (char)248;
    //szDegSymbol[1] = 0;
    //NSString *sRetval=[NSString stringWithFormat:@"Heading = %.1f%s, Roll = %.1f%s, Pitch = %.1f%s, Temp = %.1f %sC",_m_compassData.heading,szDegSymbol,_m_compassData.roll,szDegSymbol,_m_compassData.pitch,szDegSymbol,(_m_compassData.mag_temperature+_m_compassData.acc_gyro_temperature)/2,szDegSymbol];
    NSString *sRetval = [NSString stringWithFormat:@"Heading = %.1f°, Roll = %.1f°, Pitch = %.1f°, Temp = %.1f °C",_m_compassData.heading,_m_compassData.roll,
                         _m_compassData.pitch,(_m_compassData.mag_temperature + _m_compassData.acc_gyro_temperature)/2];
    return sRetval;
    
}

- (NSString *) FormatLeakData {//format the received leak sensor data
    NSString *sLeakData=@"Leak Detected: NO";
    if (_m_bLeakDetected) {
        sLeakData=@"Leak Detected: YES";
    }
    return sLeakData;
}

- (NSString *) FormatVoltage {//format the available voltage
    NSString *sVoltage=@"";
    sVoltage = [NSString stringWithFormat:@"Voltage = %.2f V",_m_fBatteryVoltage];
    return sVoltage;
}

- (NSString *) FormatDiagnosticsData {//format the received diagnostics data
    NSString *sRXPower=@"";
    if (_m_fWirelessRXPower!=0) {
        sRXPower = [NSString stringWithFormat:@"RX Power: %.0f dBm",_m_fWirelessRXPower];
    }
    else {
        sRXPower = @"RX Power: N.A.";
    }
    NSString *sDiagData=@"";
    if (_m_nSolarCharging>0) {
        sDiagData = [NSString stringWithFormat:@"Voltage: %.3f V, Current (@12 V): %.2f A, RH = %.1f %%, Temp = %.1f °C, Solar: YES, ",
                     _m_fBatteryVoltage, _m_fCurrentDraw, _m_fHumidity, _m_fHumidityTemp];
    }
    else {
        sDiagData = [NSString stringWithFormat:@"Voltage: %.3f V, Current (@12 V): %.2f A, RH = %.1f %%, Temp = %.1f °C, Solar: NO, ",_m_fBatteryVoltage, _m_fCurrentDraw, _m_fHumidity, _m_fHumidityTemp];
    }
    sDiagData = [sDiagData stringByAppendingString:sRXPower];
    return sDiagData;
}

@end






