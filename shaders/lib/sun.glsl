vec3 zenithSunCol = blackbody(4000);
vec3 horizonSunCol = blackbody(2000)*0.6;
vec3 sunCol = mix(zenithSunCol, horizonSunCol, pow(sunrise, 0.2));