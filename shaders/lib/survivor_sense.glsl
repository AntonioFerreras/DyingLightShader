uniform float survivorSenseTime;
uniform float isSneaking;

const float SURVIVOR_SENSE_PULSE_SIZE = 2.5;
const float SURVIVOR_SENSE_DIST = 300.0;


float impulse( float k, float x ){
    float h = k*x;
    return h*exp(1.0-h);
}

float survivorSenseTimeCurved = pow(survivorSenseTime, 2);
float survivorSensePulseDist = SURVIVOR_SENSE_DIST * survivorSenseTimeCurved;

float survivorSensePulseAmount(float groundDist) {
    
    float distFromPulse = survivorSensePulseDist - groundDist;
    if(distFromPulse < 0.0001 || distFromPulse > SURVIVOR_SENSE_PULSE_SIZE || isSneaking == 0.0) {
        return 0.0;
    } else {
        float survivorSenseImpulseSample = map(distFromPulse, 0.0, SURVIVOR_SENSE_PULSE_SIZE, 0.0, 1.0);
        return impulse(6.0, survivorSenseImpulseSample);
    }
}

float survivorSenseFalloff() {
    return 1.0 - survivorSenseTimeCurved;//-pow(survivorSenseTimeCurved, 1.5) + 1.0;
}

float getSurvivorSenseVertOffset(float dist) {
    float offset = survivorSensePulseAmount(dist);
    return offset*(2*survivorSenseTimeCurved + 0.1);
}