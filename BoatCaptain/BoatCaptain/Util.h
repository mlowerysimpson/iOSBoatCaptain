//
//  Util.h
//  BoatCaptain
//
//  Created by Murray Simpson on 2018-12-12.
//  Copyright © 2018 Simpson's Helpful Software. All rights reserved.
//
#pragma once


@interface Util : NSObject


-(id)init;//constructor
+ (float) BytesToFloat:(unsigned char *)dataBytes;//convert bytes to floating point
+ (int) BytesToInt:(unsigned char *)dataBytes;//convert bytes to integer
+ (void) DoubleToBytes:(double)dVal bytes:(unsigned char *)dataBytes;//convert double to bytes
+ (void) IntToBytes:(int)nVal bytes:(unsigned char *)dataBytes;//convert int to bytes
+ (void) ReverseByteOrder:(unsigned char *)bytes numBytes:(int)nNumberOfBytes;//AMOS expects bytes in reverse order
+ (double) ComputeDistBetweenPts:(double)dLatitudeDeg1 longitude1:(double)dLongitudeDeg1
                       latitude2:(double)dLatitudeDeg2 longitude2:(double)dLongitudeDeg2;//ComputeDistBetweenPts: use GPS locations of 2 points to get the distance between those 2 points
@end




