//
//  NetworkCaptain.m
//  BoatCaptain
//
//  Created by Murray Simpson on 2018-04-20.
//  Copyright © 2018 Simpson's Helpful Software. All rights reserved.
//

#import "NetworkCaptain.h"
#import <CoreFoundation/CoreFoundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import "Util.h"


@implementation NetworkCaptain

NSString *m_sConnectedIPAddr;//ip address of server that boat and this program connect to
UIImage *m_boatImage = nil;//image received from boat
CFReadStreamRef m_readStream = NULL;
CFWriteStreamRef m_writeStream = NULL;
Boolean m_bCleanedUp=FALSE;
Boolean m_bConnected=FALSE;


-(id)init {
    m_bCleanedUp=FALSE;
    m_sConnectedIPAddr=@"";
    m_bConnected=FALSE;
    m_readStream=NULL;
    m_writeStream=NULL;
    return [super init];
}

-(void)cleanup {
    if (m_readStream!=nil) {
        CFReadStreamClose(m_readStream);
    }
    if (m_writeStream!=nil) {
        CFWriteStreamClose(m_writeStream);
    }
    m_readStream=NULL;
    m_writeStream=NULL;
    m_sConnectedIPAddr=@"";
}

-(BOOL)ConnectToBoat:(NSString *)sIPAddr {
    if (m_writeStream!=NULL) {
        [self cleanup];
    }
    m_sConnectedIPAddr=@"";
    int nPortNum = REMOTE_PORTNUM;
    CFStringRef cfBoatIP = (__bridge CFStringRef)sIPAddr;
    CFHostRef cfBoatHost = CFHostCreateWithName(kCFAllocatorDefault, cfBoatIP);
    
    
    CFStreamCreatePairWithSocketToCFHost(kCFAllocatorDefault, cfBoatHost, (SInt32)nPortNum, &m_readStream, &m_writeStream);
    
    if (m_readStream==NULL||m_writeStream==NULL) {
        [self cleanup];
        return FALSE;//failed to connect to remote host
    }
    //open both streams (actually connects to the remote host at this point)
    if (!CFReadStreamOpen(m_readStream)) {
        [self cleanup];
        return FALSE;
    }
    if (!CFWriteStreamOpen(m_writeStream)) {
        [self cleanup];
        return FALSE;
    }
    char *szPassCode = PASSCODE_TEXT;
    int nNumPassCodeBytes = strlen(szPassCode);
    int nNumSent = CFWriteStreamWrite(m_writeStream,(UInt8 *)szPassCode,nNumPassCodeBytes);
    if (nNumSent!=nNumPassCodeBytes) {
        [self cleanup];
        [self DisplayLastSockError];
        return FALSE;
    }
    
    m_sConnectedIPAddr = sIPAddr;
    return TRUE;//connected OK
}

-(BOOL) ForwardHo {//move forward
    struct PROPELLER_STATE propState;
    if (![super ForwardHo:(struct PROPELLER_STATE *)&propState]) {
        return FALSE;
    }
    struct REMOTE_COMMAND rc;
    rc.nCommand = THRUST_ON;
    rc.nNumDataBytes = sizeof(rc);
    rc.pDataBytes = (unsigned char *)&propState;
    return [self SendNetworkCommand:(struct REMOTE_COMMAND *)&rc];
}

-(BOOL) StarboardHo {//turn to right
    struct PROPELLER_STATE propState;
    if (![super StarboardHo:(struct PROPELLER_STATE *)&propState]) {
        return FALSE;
    }
    struct REMOTE_COMMAND rc;
    rc.nCommand = THRUST_ON;
    rc.nNumDataBytes = sizeof(rc);
    rc.pDataBytes = (unsigned char *)&propState;
    return [self SendNetworkCommand:(struct REMOTE_COMMAND *)&rc];
}

-(BOOL) PortHo {//turn to left
    struct PROPELLER_STATE propState;
    if (![super PortHo:(struct PROPELLER_STATE *)&propState]) {
        return FALSE;
    }
    struct REMOTE_COMMAND rc;
    rc.nCommand = THRUST_ON;
    rc.nNumDataBytes = sizeof(rc);
    rc.pDataBytes = (unsigned char *)&propState;
    return [self SendNetworkCommand:(struct REMOTE_COMMAND *)&rc];
}

-(BOOL) BackHo {//move backward
    struct PROPELLER_STATE propState;
    if (![super BackHo:(struct PROPELLER_STATE *)&propState]) {
        return FALSE;
    }
    struct REMOTE_COMMAND rc;
    rc.nCommand = THRUST_ON;
    rc.nNumDataBytes = sizeof(rc);
    rc.pDataBytes = (unsigned char *)&propState;
    return [self SendNetworkCommand:(struct REMOTE_COMMAND *)&rc];
}

-(BOOL) Stop {//issue a stop signal to the boat to stop the propellers immediately
    struct PROPELLER_STATE propState;
    if (![super Stop:(struct PROPELLER_STATE *)&propState]) {
        return FALSE;
    }
    struct REMOTE_COMMAND rc;
    rc.nCommand = THRUST_ON;
    rc.nNumDataBytes = sizeof(rc);
    rc.pDataBytes = (unsigned char *)&propState;
    return [self SendNetworkCommand:(struct REMOTE_COMMAND *)&rc];
}

//SendNetworkCommand: sends a remote command out over the network
//pRC = REMOTE_COMMAND structure describing the command to be sent to the boat
//returns true if command was successfully sent, false otherwise
-(BOOL) SendNetworkCommand:(struct REMOTE_COMMAND *)pRC {
    const double TIMEOUT_SEC = 5.0;//timeout in seconds for getting a response from the boat
    if (m_readStream == NULL||m_writeStream==NULL) {
        return FALSE;//not connected yet
    }
    //first send command bytes
    unsigned char commandBytes[4];
    commandBytes[0] = (unsigned char)((pRC->nCommand&0xff000000)>>24);
    commandBytes[1] = (unsigned char)((pRC->nCommand&0x00ff0000)>>16);
    commandBytes[2] = (unsigned char)((pRC->nCommand&0x0000ff00)>>8);
    commandBytes[3] = (unsigned char)(pRC->nCommand&0x000000ff);
    int nNumSent = CFWriteStreamWrite(m_writeStream,(UInt8 *)commandBytes,4);
    if (nNumSent!=4) {
        [self DisplayLastSockError];
        return FALSE;
    }
    if (pRC->pDataBytes!=NULL) {//need to send data along with command
        unsigned char dataSizeBytes[4];
        dataSizeBytes[0] = (unsigned char)((pRC->nNumDataBytes&0xff000000)>>24);
        dataSizeBytes[1] = (unsigned char)((pRC->nNumDataBytes&0x00ff0000)>>16);
        dataSizeBytes[2] = (unsigned char)((pRC->nNumDataBytes&0x0000ff00)>>8);
        dataSizeBytes[3] = (unsigned char)(pRC->nNumDataBytes&0x000000ff);
        nNumSent = CFWriteStreamWrite(m_writeStream,(UInt8 *)dataSizeBytes, 4);
        if (nNumSent!=4) {
            [self DisplayLastSockError];
            return FALSE;
        }
        //send actual data
        nNumSent = CFWriteStreamWrite(m_writeStream,(UInt8 *)pRC->pDataBytes,pRC->nNumDataBytes);
        if (nNumSent!=pRC->nNumDataBytes) {
            [self DisplayLastSockError];
            return FALSE;
        }
    }
    //get confirmation from remote boat
    unsigned char inBuf[4];
    NSDate *startTime = [NSDate date];
    NSDate *timeNow = [NSDate date];
    NSTimeInterval timeElapsed = [timeNow timeIntervalSinceDate:startTime];
    int nNumReceived = 0;
    while (nNumReceived<4&&timeElapsed<TIMEOUT_SEC) {
        if (CFReadStreamHasBytesAvailable(m_readStream)) {
            int nR = CFReadStreamRead(m_readStream,(UInt8 *)inBuf,4);
            if (nR<0) {
                [self DisplayLastSockError];
                return FALSE;
            }
            else nNumReceived+=nR;
        }
        timeNow = [NSDate date];
        timeElapsed = [timeNow timeIntervalSinceDate:startTime];
    }
    if (nNumReceived==0) {
        [self DisplayError:@"Timed out trying to receive data from boat."];
        return FALSE;
    }
    
    else if (nNumReceived<4) {
        NSString *sErrMsg = [NSString stringWithFormat:@"Only %d of 4 bytes received from boat.",nNumReceived];
        [self DisplayError:sErrMsg];
        return FALSE;
    }
    int nResponse = (inBuf[0]<<24) + (inBuf[1]<<16) + (inBuf[2]<<8) + inBuf[3];
    if (nResponse!=pRC->nCommand) {
        [self DisplayError:@"Error, invalid confirmation response from boat."];
        return FALSE;
    }
    return TRUE;//command was sent successfully
}

-(NSString *) GetIPAddr {//return the IP address of the remote boat that we are connected to
    return m_sConnectedIPAddr;
}

-(void) DisconnectFromBoat {//disconnect the network connection to the boat
    [self cleanup];
}

-(NSString *) RequestGPSPosition {//request the current GPS position of the boat, gets returned result as a string or nil if an error occurs
    NSString *sGPSPosition=@"";
    struct REMOTE_COMMAND rc;
    rc.nCommand = GPS_DATA_PACKET;
    rc.nNumDataBytes = 0;
    rc.pDataBytes = nil;
    if ([self SendNetworkCommand:(struct REMOTE_COMMAND *)&rc]) {
        if (![self ReceiveBoatData]) {
            return nil;
        }
    }
    else {
        return nil;
    }
    sGPSPosition = [self FormatGPSData];
    return sGPSPosition;
}

-(NSString *) RequestCompassData {//query the boat for its compass data (heading, roll, and pitch angles, as well as temperature). Returns true if successful
    NSString *sCompassData=@"";
    struct REMOTE_COMMAND rc;
    rc.nCommand = COMPASS_DATA_PACKET;
    rc.nNumDataBytes = 0;
    rc.pDataBytes = NULL;
    if ([self SendNetworkCommand:(struct REMOTE_COMMAND *)&rc]) {
        if (![self ReceiveBoatData])  {
            return nil;
        }
    }
    else {
        return nil;
    }
    sCompassData = [self FormatCompassData];
    return sCompassData;
}

-(NSString *) RequestDiagnosticsData {
    NSString *sRetval = @"";
    //request leak sensor data
    struct REMOTE_COMMAND rc;
    rc.nCommand = LEAK_DATA_PACKET;
    rc.nNumDataBytes = 0;
    rc.pDataBytes = NULL;
    if ([self SendNetworkCommand:(struct REMOTE_COMMAND *)&rc]) {
        if (![self ReceiveBoatData]) {
            return nil;
        }
    }
    else {
        return nil;
    }
    NSString *sLeakInfo = [self FormatLeakData];//format the received leak sensor data
    sRetval = [sRetval stringByAppendingString:sLeakInfo];
    sRetval = [sRetval stringByAppendingString:@", "];
    
    
    //diagnostics data (current draw)
    rc.nCommand = DIAGNOSTICS_DATA_PACKET;
    rc.nNumDataBytes = 0;
    rc.pDataBytes = NULL;
    if ([self SendNetworkCommand:(struct REMOTE_COMMAND *)&rc]) {
        if (![self ReceiveBoatData]) {
            return nil;
        }
    }
    else {
        return nil;
    }
    NSString *sDiagData = [self FormatDiagnosticsData];//format the received diagnostics data
    sRetval = [sRetval stringByAppendingString:sDiagData];
    return sRetval;
}



//ReceiveBoatData: receive network data from the boat
//returns true if boat data could be successfully received and processed
-(BOOL) ReceiveBoatData {//receive data from boat over network
    const double TIMEOUT_SEC = 5.0;//timeout in seconds for getting a response from the boat
    if (m_readStream == NULL) {
        return FALSE;//not connected yet
    }
    int nNumBytesToReceive=2*sizeof(int);
    //first receive the data type from the boat and the number of data bytes
    int nDataType=0;
    int nDataSize=0;
    unsigned char inBuf[1024];
    memset(inBuf,0,1024);
   
    NSDate *startTime = [NSDate date];
    NSDate *timeNow = [NSDate date];
    NSTimeInterval timeElapsed = [timeNow timeIntervalSinceDate:startTime];
    int nNumReceived = 0;
    int nNumRemaining = nNumBytesToReceive;
    while (nNumReceived<nNumBytesToReceive&&timeElapsed<TIMEOUT_SEC) {
        if (CFReadStreamHasBytesAvailable(m_readStream)) {
            int nR = CFReadStreamRead(m_readStream,(UInt8 *)inBuf,nNumRemaining);
            if (nR<0) {
                [self DisplayLastSockError];
                return FALSE;
            }
            else {
                nNumReceived+=nR;
                nNumRemaining-=nR;
            }
        }
        timeNow = [NSDate date];
        timeElapsed = [timeNow timeIntervalSinceDate:startTime];
    }
    if (nNumReceived<nNumBytesToReceive) {
        //error occurred,
        return FALSE;//timeout trying to receive data
    }
    memcpy(&nDataType,inBuf,sizeof(int));
    memcpy(&nDataSize,&inBuf[sizeof(int)],sizeof(int));
    //create structure for receiving boat data
    struct BOAT_DATA *pBoatData = [self CreateBoatData:nDataType];
    if (pBoatData==nil) {
        return FALSE;//unable to create this data type
    }
    //special case for sensor types
    if (nDataType==SENSOR_TYPES_INFO) {
        pBoatData->nDataSize=self.m_nNumSensorsAvailable*sizeof(int);
    }
    if (pBoatData->nDataSize!=nDataSize) {
        return false;//unexpected data size
    }
    nNumBytesToReceive = pBoatData->nDataSize+1;
    if (nNumBytesToReceive>1024) {
        return false;//trying to receive too many bytes, something wrong!
    }
    
    startTime = [NSDate date];
    timeNow = [NSDate date];
    timeElapsed = [timeNow timeIntervalSinceDate:startTime];
    nNumReceived = 0;
    nNumRemaining = nNumBytesToReceive;
    while (nNumReceived<nNumBytesToReceive&&timeElapsed<TIMEOUT_SEC) {
        if (CFReadStreamHasBytesAvailable(m_readStream)) {
            int nR = CFReadStreamRead(m_readStream,(UInt8 *)inBuf,nNumRemaining);
            if (nR<0) {
                [self DisplayLastSockError];
                return FALSE;
            }
            else {
                nNumReceived+=nR;
                nNumBytesToReceive-=nR;
            }
        }
        timeNow = [NSDate date];
        timeElapsed = [timeNow timeIntervalSinceDate:startTime];
    }

    if (nNumReceived<nNumBytesToReceive) {
        //timeout trying to receive data
        return FALSE;
    }

    memcpy(pBoatData->dataBytes,inBuf,pBoatData->nDataSize);
    pBoatData->checkSum = (unsigned char)inBuf[nNumBytesToReceive-1];
    //special case for video capture frame
    BOOL bSkipProcessData=FALSE;
    if (pBoatData->nPacketType==VIDEO_DATA_PACKET) {
        bSkipProcessData=TRUE;
        int nImageBytes = [Util BytesToInt:pBoatData->dataBytes];
        //make sure image is not super large
        if (nImageBytes<10000000) {
            int count = 24;
            unsigned char *videoBytes = (unsigned char *)calloc(nImageBytes, sizeof(unsigned char));
            nNumReceived = [self ReceiveLargeDataChunk:videoBytes numVideoBytes:nImageBytes];
            if (nNumReceived==nImageBytes) {//image bytes received successfully, save to temporary image file
                NSData *pImgData = [NSData dataWithBytes:videoBytes length:nNumReceived];
                if (pImgData!=nil) {
                    m_boatImage = [UIImage imageWithData:pImgData];
                }
            }
            free(videoBytes);
        }
    }
    if (!bSkipProcessData&&![self ProcessBoatData:pBoatData]) {
        return FALSE;
    }
    return TRUE;//command was sent successfully
}

-(BOOL) ReturnHome:(double)dLatitude longitude:(double)dLongitude {//send command to the boat to tell it to return "home" to the specified lat, long location
    //latitude and longitude are specified in degrees
    struct REMOTE_COMMAND rc;
    rc.nCommand = GPS_DESTINATION_PACKET;
    rc.nNumDataBytes = 16;
    unsigned char latitude_bytes[8];
    unsigned char longitude_bytes[8];
    [Util DoubleToBytes:dLatitude bytes:latitude_bytes];
    [Util DoubleToBytes:dLongitude bytes:longitude_bytes];
    [Util ReverseByteOrder:latitude_bytes numBytes:8];//AMOS expects bytes in reverse order
    [Util ReverseByteOrder:longitude_bytes numBytes:8];//AMOS expects bytes in reverse order
  
    for (int i=0;i<8;i++) {
        rc.pDataBytes[i]=latitude_bytes[i];
        rc.pDataBytes[8+i]=longitude_bytes[i];
    }
    if (![self SendNetworkCommand:(struct REMOTE_COMMAND *)&rc]) {
        return FALSE;
    }
    return TRUE;
}

-(double) GetBoatDistFromLocation:(double)dLatitudeDeg longitude:(double)dLongitudeDeg {//get distance of the boat from a particular GPS location (input parameters specify latitude and longitude in degrees)
    //returns < 0 if an error occurred getting the boat location
    //distance is returned in m
    NSString *sGPSPosition = [self RequestGPSPosition];
    if (sGPSPosition==nil) {
        return -1.0;
    }
    double dDistFromLocation = [Util ComputeDistBetweenPts:self.m_dLatitude longitude1:self.m_dLongitude latitude2:dLatitudeDeg longitude2:dLongitudeDeg];
    return dDistFromLocation;
}

//RequestVideoImage: request an image capture with feature markings in it from the boat
//nFeatureThreshold = feature threshold value from 0 to 255 that is used to control how feature markings
//are determined in the image. nFeatureThreshold==0 disables or removes feature markers from the image.
//returns string path of image filename
-(UIImage *) RequestVideoImage:(int) nFeatureThreshold {
    struct REMOTE_COMMAND rc;
    rc.nCommand = VIDEO_DATA_PACKET;
    rc.nNumDataBytes = 4;
    [Util IntToBytes:nFeatureThreshold bytes:rc.pDataBytes];
    [Util ReverseByteOrder:rc.pDataBytes numBytes:4];

    if ([self SendNetworkCommand:(struct REMOTE_COMMAND *)&rc]) {
        if (![self ReceiveBoatData]) {
            return nil;
        }
    }
    else {
        return nil;
    }
    return m_boatImage;
}

//ReceiveLargeDataChunk: tries to receive a large chunk of data over network socket connection
//videoBytes = pointer to unsigned char array of bytes that will hold the video data
//nImageBytes = the number of bytes to receive over the socket connection
//returns the number of bytes that were successfully read
-(int) ReceiveLargeDataChunk:(unsigned char *) videoBytes numVideoBytes:(int) nImageBytes {
    const int TIMEOUT_SEC = 5;//maximum length of timeout in seconds without getting any data
    int nNumRemaining = nImageBytes;
    int nNumReceived=0;
    NSDate *startTime = [NSDate date];
    NSDate *timeNow = [NSDate date];
    NSTimeInterval timeElapsed = [timeNow timeIntervalSinceDate:startTime];

    while (nNumReceived<nImageBytes&&timeElapsed<TIMEOUT_SEC) {
        if (CFReadStreamHasBytesAvailable(m_readStream)) {
            int nR = CFReadStreamRead(m_readStream,(UInt8 *)&videoBytes[nNumReceived],nNumRemaining);
            if (nR<0) {
                [self DisplayLastSockError];
                return FALSE;
            }
            else {
                nNumReceived+=nR;
                nNumRemaining-=nR;
                //got some data, so reset time for timeout purposes
                startTime = [NSDate date];
            }
        }
        timeNow = [NSDate date];
        timeElapsed = [timeNow timeIntervalSinceDate:startTime];
    }
    if (nNumReceived<nImageBytes) {
        //error occurred,
        return 0;//timeout trying to receive data
    }
    return nImageBytes;
}


@end





