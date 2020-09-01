int volumetricSteps = FOG_QUALITY;

float volumetricMarch(vec3 ro, vec3 rd, vec3 rayEnd, float dither) {
    if(fog < 0.01 || day < 0.001) {
        return 1.0;
    }
    vec4 startShadowPos = shadowProjection * (shadowModelView * vec4(ro, 1.0)); //convert to shadow screen space
    vec4 endShadowPos = shadowProjection * (shadowModelView * vec4(rayEnd, 1.0)); //convert to shadow screen space
    vec4 rayStep = normalize(endShadowPos - startShadowPos) * distance(startShadowPos, endShadowPos) / volumetricSteps;
    vec4 rayPos = startShadowPos + rayStep * dither;

    float incomingRadiance = 0.0;
    for(int i = 1; i < volumetricSteps; i++) {
        rayPos += rayStep;

        vec3 shadowPos = distort(rayPos.xyz, getDistortFactor(rayPos.xy)).xyz * 0.5 + 0.5; //apply shadow distortion

        incomingRadiance += texture2D(shadowtex0, shadowPos.xy).r < shadowPos.z ? 0.3 : 1.0;
    }
    incomingRadiance /= volumetricSteps;
	
    return incomingRadiance;
}

vec3 applyFog(vec3 rgb, float distance, vec3 rayOri, vec3 rayDir, float radiance) {
   float b = 0.01;
   

   vec3 sunDir = normalize(viewToWorld(sunPosition));

   float height = rayOri.y - FOG_OFFSET;
   float fogAmount = exp(-height*b) * (1.0-exp( -distance*rayDir.y*b ))/rayDir.y;
   float sunAmount = max( dot( rayDir, sunDir ), 0.0 );

   vec3 mieCol = sunCol * SUN_BRIGHTNESS * day;
   vec3 atmosphericExtinctionCol = vec3(0.5,0.6,0.7); 
   vec3 morningFogCol = vec3(161, 133, 74)/255.0;
   vec3 rainFogCol = vec3(137, 142, 156)/255.0 * max(day, 0.06);
   vec3 fogExtinctionCol = mix(mix(morningFogCol, atmosphericExtinctionCol, night), rainFogCol, wetness);
   vec3 extinctionCol = mix(atmosphericExtinctionCol, fogExtinctionCol, pow(fog, 0.3));

   vec3 fogColor  = mix(extinctionCol, mieCol, pow(sunAmount, 2.0)*0.15);

   float minc = mix(0.06, 0.015, night);
   float maxc = 2.2*FOG_INTENSITY;

   float c = map(fog, 0.0, 1.0, minc, maxc);

   return mix( rgb, fogColor, clamp(c*fogAmount*radiance, 0.0, 0.93) )*mix(1.0, 0.8, pow2(wetness));
}

// vec3 calculateVolumetricFog(float radiance, )