//
//  Util.m
//  BoatCaptain
//
//  Created by Murray Simpson on 2018-12-12.
//  Copyright © 2018 Simpson's Helpful Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Util.h"

@implementation Util

-(id)init {//constructor
 
    return [super init];
}

+ (float) BytesToFloat:(unsigned char *)dataBytes {
    float fRetval = 0;
    memcpy(&fRetval,dataBytes,sizeof(float));
    return fRetval;
}

+ (int) BytesToInt:(unsigned char *)dataBytes {
    int nRetval = 0;
    memcpy(&nRetval,dataBytes,sizeof(int));
    return nRetval;
}

+ (void) DoubleToBytes:(double)dVal bytes:(unsigned char *)dataBytes {//convert double to bytes
    memcpy(dataBytes,&dVal,sizeof(double));
}

+ (void) IntToBytes:(int)nVal bytes:(unsigned char *)dataBytes {//convert int to bytes
    memcpy(dataBytes,&nVal,sizeof(int));
}

+ (void) ReverseByteOrder:(unsigned char *)bytes numBytes:(int)nNumberOfBytes {//reverse order of bytes
    if (nNumberOfBytes>8) return;
    unsigned char reversedBytes[8];
    for (int i=0;i<nNumberOfBytes;i++) {
        reversedBytes[i] = bytes[nNumberOfBytes-i-1];
    }
    //copy back to bytes
    memcpy(bytes,reversedBytes,nNumberOfBytes);
}

//ComputeDistBetweenPts: use GPS locations of 2 points to get the distance between those 2 points
//dLatitudeDeg1 = latitude (in degrees) of the 1st point
//dLongitudeDeg1 = longitude (in degrees) of the 2nd point
//dLatitudeDeg2 = latitude (in degrees) of the 2nd point
//dLongitudeDeg2 = longitude (in degrees) of the 2nd point
//returns distance (in m) between the 2 points
+ (double) ComputeDistBetweenPts:(double)dLatitudeDeg1 longitude1:(double)dLongitudeDeg1
                       latitude2:(double)dLatitudeDeg2 longitude2:(double)dLongitudeDeg2 {
    const double EARTH_RADIUS_EQUATOR_M = 6378150.0;//radius of Earth at the equator in m
    const double EARTH_RADIUS_POLE_M = 6356890.0;//radius of Earth at the poles in m
    double dLatitudeRad1 = dLatitudeDeg1*M_PI / 180.0;//latitude of 1st point in radians
    double dLongitudeRad1 = dLongitudeDeg1*M_PI / 180.0;//longitude of 1st point in radians
    double dLatitudeRad2 = dLatitudeDeg2*M_PI / 180.0;//latitude of 2nd point in radians
    double dLongitudeRad2 = dLongitudeDeg2*M_PI / 180.0;//longitude of 2nd point in radians
    double dAvgLatitude = (dLatitudeRad1 + dLatitudeRad2)/2;
    double dNorthSouthRadius = cos(dAvgLatitude)*EARTH_RADIUS_EQUATOR_M + sin(fabs(dAvgLatitude))*EARTH_RADIUS_POLE_M;
    double dEastWestRadius = cos(dAvgLatitude)*dNorthSouthRadius;
    double dLatitudeDif = dLatitudeDeg2- dLatitudeDeg1;//difference between latitudes in degrees
    double dLongitudeDif = dLongitudeDeg2 - dLongitudeDeg1;//difference between longitudes in degrees
    //following might be necessary near the International Date Line (i.e. +/- 180 deg longitude)
    if (dLongitudeDif>180) {
        dLongitudeDif-=360;
    }
    else if (dLongitudeDif<-180) {
        dLongitudeDif+=360;
    }
    double dLatitudeDifRad = dLatitudeDif * M_PI / 180.0;//latitude difference in radians
    double dLongitudeDifRad = dLongitudeDif * M_PI / 180.0;//longitude difference in radians
    double dNorthSouthComponent = dNorthSouthRadius * dLatitudeDifRad;//north-south component of distance to destination in m
    double dEastWestComponent = dEastWestRadius * dLongitudeDifRad;//east-west component of distance to destination in m
    double dDist = sqrt(dNorthSouthComponent*dNorthSouthComponent + dEastWestComponent*dEastWestComponent);
    return dDist;
}

@end
