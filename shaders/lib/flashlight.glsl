vec2 screen = vec2(viewWidth, viewHeight);

float getFlashlight(vec2 coord, float depth) {

    float dist = distance(coord*screen, vec2(0.5)*screen)/viewWidth * 1.8;
    return max(clamp(((-pow32(dist + 0.4) + 1.0) + 0.65*cos(18.*dist))*exp(-depth*0.26), 0.0, 1.0), exp(-depth*0.5)*0.1);
}