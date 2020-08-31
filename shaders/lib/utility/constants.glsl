/*--------------------*/
#define PI    radians(180.0)
#define HPI   PI * 0.5
#define TAU   PI * 2.0
#define RCPPI 1.0 / PI
#define PHI   sqrt(5.0) * 0.5 + 0.5
#define GOLDEN_ANGLE TAU / PHI / PHI
#define LOG2 log(2.0)
#define RCPLOG2 1.0 / LOG2

//1/7
#define K  0.142857142857
//3/7
#define Ko 0.428571428571

#define lumaCoeff       vec3(0.2125, 0.7154, 0.0721)
#define RGB_Wavelengths vec3(750.0, 570.0, 495.0)

#define air_IOR   1.0002
#define water_IOR 1.3333
#define BK7_IOR   1.5176
#define IORtoF0(IOR) pow2(abs((1.0 - IOR) / (1.0 + IOR)))

#define waterAbsorbCoeff     vec3(0.996078, 0.406863, 0.25098) * 0.125 / LOG2
#define waterScatterCoeff    vec3(0.01) / LOG2

#define mieScatteringAngle   0.86

const float sunAngularRadius  = radians(0.75);
const float sinSunAngle       = sin(sunAngularRadius);
const float cosSunAngle       = cos(sunAngularRadius);
const float sunSolidAngle     = radians(360.0) * (1.0 - cosSunAngle);

const float moonAngularRadius = radians(0.70);
const float sinMoonAngle      = sin(sunAngularRadius);
const float cosMoonAngle      = cos(sunAngularRadius);
const float moonSolidAngle    = radians(360.0) * (1.0 - cosMoonAngle);

const float windDirectionDeg  = 32.0;
const float windDirectionRad  = radians(windDirectionDeg);
const vec2  windDirection     = vec2(sin(windDirectionRad), cos(windDirectionRad));

const vec3  sunIlluminance   = vec3(1.0, 0.949, 0.937); // 5e3
const vec3  sunLuminance     = sunIlluminance / sunSolidAngle;

const vec3  moonAlbedo       = vec3(0.136) * 100.0;
const vec3  moonLuminance    = moonAlbedo * sunIlluminance;
const vec3  moonIlluminance  = moonLuminance * moonSolidAngle;

const vec3  sunTint          = sunLuminance; //sunIlluminance / sunSolidAngle
const vec3  moonTint         = moonLuminance;

const float colorEncodeConstant = (length(sunTint) + length(moonTint)) * 0.5;