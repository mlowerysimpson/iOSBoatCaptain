//CommandList.h
//list of possible commands
#define THRUST_ON 0//turn one or both propellers on at defined speed and direction
#define THRUST_OFF 1//turn both propellers off
#define CPU_TEMP_PACKET 2//request temperature of the Compute Module chip
#define COMPASS_DATA_PACKET 3//request compass / tilt data
#define GPS_DATA_PACKET 4//request GPS data
#define BATTVOLTAGE_DATA_PACKET 11//battery voltage data packet
#define SUPPORTED_SENSOR_DATA 12//find out what types of sensor data the boat is capable of collecting
#define SENSOR_TYPES_INFO 13//code that indicates that sensor type info will follow (see SensorDataFile.h for definitions of the sensor types)
#define WATER_TEMP_DATA_PACKET 14//water temperature data packet
#define WATER_PH_DATA_PACKET 15//water pH data packet
#define VIDEO_DATA_PACKET 17//screen capture from video camera data packet
#define GPS_DESTINATION_PACKET 18//GPS destination packet (used to tell the boat where to go)
#define WATER_TURBIDITY_DATA_PACKET 19//water turbidity data packet
#define LEAK_DATA_PACKET 20//leak info data packet
#define DIAGNOSTICS_DATA_PACKET 21//diagnostics info data packet
#define CANCEL_OPERATION 22//cancel the operation currently in progress

#define MAX_DATA_BYTES 1024//maximum # of data bytes to receive in a single packet
#define MAX_SENSORS 128 //maximum # of connected sensors on AMOS

#define SIZEOF_GPS_DATA 24 //number of bytes in GPS data packet
#define SIZEOF_IMU_DATA 120 //number of bytes in IMU data packet

//structure used for sending commands
struct REMOTE_COMMAND {//structure used for sending / receiving remote commands
	int nCommand;//command code sent from remote host
	int nNumDataBytes;//number of data bytes included with command
	unsigned char *pDataBytes;//remotely received data bytes, may be NULL if no data bytes were received
};

//structure used for specifying propeller speed
struct PROPELLER_STATE {
	float fRudderAngle;//angle of rudder in degrees
	float fPropSpeed;//propeller speed (arbitrary units)
};

//structure used for holding boat data
struct BOAT_DATA {
    int nPacketType;//packet code describing what type of data this is
    int nDataSize;//number of dataBytes
    unsigned char dataBytes[MAX_DATA_BYTES];
    unsigned char checkSum;//simple 8-bit checksum of everything in this structure, except this checkSum byte
};

//structure used for GPS data
struct GPS_DATA {
    double dLatitude;//latitude in degrees (-90 to +90)
    double dLongitude;//longitude in degrees (-180 to +180)
    time_t gps_time;//time of the GPS reading
};

//structure used for inertial measurement unit data
struct IMU_DATASAMPLE {//full data sample from inertial measurement unit
    double sample_time_sec;//the time of the sample in seconds
    double acc_data[3];//acceleration data in G
    double mag_data[3];//magnetometer data (Gauss)
    double angular_rate[3];//angular rate (deg/sec)
    double mag_temperature;//temperature of the LIS3MDL chip
    double acc_gyro_temperature;//temperature of the LSM6DS33 chip
    double heading;//computed heading value in degrees (direction that the +X axis of the IMU is pointed) 0 to 360
    double pitch;//computed pitch angle in degrees (direction above horizontal that the +X axis of the IMU is pointed -90 to 90
    double roll;//computed roll angle in degrees (direction around +X axis that the +Y axis of the IMU is pointed -180 to +180
};

//structure used for describing types of sensors
struct SENSOR_INFO {
    int sensorTypes[MAX_SENSORS];
};
