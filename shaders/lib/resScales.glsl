const float atmosResScale = 0.14;
const float atmosInvResScale = 1.0/atmosResScale;

#define ERGI_RES 0.25 // Resolution scale of GI [0.25 0.5 0.75 1.0]

#ifdef ERGI_ENABLED
const float rtaoResScale = ERGI_RES;
#else
const float rtaoResScale = 1.0;
#endif
const float invRtaoResScale = 1.0/rtaoResScale;