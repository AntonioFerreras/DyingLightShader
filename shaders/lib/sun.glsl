vec3 zenithSunCol = blackbody(4500);
vec3 horizonSunCol = blackbody(2000)*0.6;
vec3 sunCol = mix(zenithSunCol, horizonSunCol, pow(sunrise, 0.2));


vec3 sampleSun(vec3 dir) {

    float sunDist = pow4096(dot(dir, normalize(sunPosition)));

    return sunCol * SUN_BRIGHTNESS * day * sunDist;
}