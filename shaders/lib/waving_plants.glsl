
float basePlantSpeed = 1.5;
float baseLeaveSpeed = 1.0;
const float PI48 = 150.796447372;
float PI48T = PI48*frameTimeCounter*WAVING_PLANTS_SPEED;

vec3 waveLeaves(vec3 pos) {
    float magnitude = abs(sin(dot(vec4(frameTimeCounter*baseLeaveSpeed*WAVING_PLANTS_SPEED, pos),vec4(1.0,0.005,0.005,0.005)))*0.5+0.72)*0.013;
    vec3 offset = (sin(PI48T*baseLeaveSpeed*vec3(0.0063,0.0224,0.0015)*1.5 - pos))*magnitude*1.6;
    offset.xz *= 2;
    offset.y *= 0.3;
    return pos+offset;
}

vec3 wavePlants(vec3 pos) {
    float magnitude = abs(sin(dot(vec4(frameTimeCounter*basePlantSpeed*WAVING_PLANTS_SPEED, pos),vec4(1.0,0.005,0.005,0.005)))*0.5+0.72)*0.013;
    vec3 offset = (sin(PI48T*basePlantSpeed*vec3(0.0063,0.0224,0.0015)*1.5 - pos))*magnitude*1.6;
    offset.xz *= 4;
    offset.y *= 0.3;
    return pos + offset;
}

float basePlantSpeedRain = 4.7;
float baseLeaveSpeedRain = 2.0;

vec3 waveLeavesRain(vec3 pos) {
    float val = 3.0*dot(vec4(frameTimeCounter*baseLeaveSpeedRain*WAVING_PLANTS_SPEED, pos),vec4(1.0,0.005,0.005,0.005));
    float magnitude = abs(clamp(val,-1.,1.)*0.5+0.72)*0.013;
    vec3 val2 = PI48T*baseLeaveSpeedRain*vec3(0.0063,0.0224,0.0015)*1.5 - pos;
    vec3 offset = ((sin(val2) + 0.4*cos(1.8*val2)))*magnitude*1.6;
    offset.y *= 0.3;
    offset.xz *= 2;
    return pos+offset;
}

vec3 wavePlantsRain(vec3 pos) {
    float val = 3.0*dot(vec4(frameTimeCounter*basePlantSpeedRain*WAVING_PLANTS_SPEED, pos),vec4(1.0,0.005,0.005,0.005));
    float magnitude = abs(clamp(val,-1.,1.)*0.5+0.72)*0.013;
    vec3 val2 = PI48T*basePlantSpeedRain*vec3(0.0063,0.0224,0.0015)*1.5 - pos;
    vec3 offset = ((sin(val2) + 0.4*cos(1.8*val2)))*magnitude*1.6;
    offset.xz *= 4;
    offset.y *= 0.1;
    return pos + offset;
}