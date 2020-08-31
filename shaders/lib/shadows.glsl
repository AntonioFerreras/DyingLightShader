#include "/lib/shadow_distort.glsl"

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;


const int shadowMapResolution = 2048; //Resolution of the shadow map. Higher numbers mean more accurate shadows. [128 256 512 1024 2048 4096 8192]
const float invShadowMapRes = 1.0/shadowMapResolution;

const bool shadowcolor0Nearest = false;
const bool shadowtex0Nearest = false;
const bool shadowtex1Nearest = false;

// float getShadowBias(vec3 viewPos) {
//     return mix(0.008, 0.01, clamp(length(viewPos)/12.0, 0.0, 1.0));
// }

// vec3 shadow(vec3 p, vec3 n) {
	
//     float lightDot = dot(n, normalize(sunPosition));
//     if(lightDot > 0.0) {
//         vec4 playerPos = gbufferModelViewInverse * vec4(p, 1.0);
// 		vec4 shadowPos = shadowProjection * (shadowModelView * playerPos); //convert to shadow screen space
// 		float distortFactor = getDistortFactor(shadowPos.xy);
// 		shadowPos.xyz = distort(shadowPos.xyz, distortFactor); //apply shadow distortion
// 		shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
// 		shadowPos.z -= SHADOW_BIAS * (distortFactor * distortFactor) / abs(lightDot); //apply shadow bias

//         if (shadowPos.w > 0.0) {
// 			//for invisible and colored shadows, first check the closest OPAQUE thing to the sun.
// 			if (texture2D(shadowtex0, shadowPos.xy).r < shadowPos.z) {
// 				//surface is in shadows. reduce light level.
// 				return vec3(0.0);
// 			} else {
// 				//surface is in direct sunlight. increase light level.
// 				//when colored shadows are enabled and there's nothing OPAQUE between us and the sun,
// 				//perform a 2nd check to see if there's anything translucent between us and the sun.
// 				vec3 s = vec3(1.0);
// 				return s;
// 				if (texture2D(shadowtex0, shadowPos.xy).r < shadowPos.z) {
// 					//surface has translucent object between it and the sun. modify its color.
// 					//if the block light is high, modify the color less.
// 					vec4 shadowLightColor = texture2D(shadowcolor0, shadowPos.xy);
// 					//make colors more intense when the shadow light color is more opaque.
// 					shadowLightColor.rgb = mix(vec3(1.0), shadowLightColor.rgb, shadowLightColor.a);
// 					// //also make colors less intense when the block light level is high.
// 					// shadowLightColor.rgb = mix(shadowLightColor.rgb, vec3(1.0), lm.x);
// 					// //apply the color.
// 					s *= shadowLightColor.rgb;
// 					return s;
// 				}
// 			}
// 		}
//     } else {
//         return vec3(0.0);
//     }
// }


float shadowFast(vec3 p, vec3 n) {
	
    float lightDot = dot(n, normalize(sunPosition));
    if(lightDot > 0.0) {
        vec4 playerPos = gbufferModelViewInverse * vec4(p, 1.0);
		vec4 shadowPos = shadowProjection * (shadowModelView * playerPos); //convert to shadow screen space
		float distortFactor = getDistortFactor(shadowPos.xy);
		shadowPos.xyz = distort(shadowPos.xyz, distortFactor); //apply shadow distortion
		shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
		float shadowBias =  SHADOW_BIAS * (distortFactor * distortFactor);
		shadowPos.z -= shadowBias; //apply shadow bias

        if (shadowPos.w > 0.0) {
			return step(shadowPos.z - texture2D(shadowtex0, shadowPos.xy).r, shadowBias);
		} 
		return 0.0;
    } else {
        return 0.0;
    }
}

float shadow(vec3 p, vec3 n) {
	
    float lightDot = dot(n, normalize(sunPosition));
    if(lightDot > 0.0) {
        vec4 playerPos = gbufferModelViewInverse * vec4(p, 1.0);
		vec4 shadowPos = shadowProjection * (shadowModelView * playerPos); //convert to shadow screen space
		float distortFactor = getDistortFactor(shadowPos.xy);
		shadowPos.xyz = distort(shadowPos.xyz, distortFactor); //apply shadow distortion
		shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
		float shadowBias =  SHADOW_BIAS * (distortFactor * distortFactor);
		shadowPos.z -= shadowBias; //apply shadow bias

		float distancetoCam = length(p);
		int kernelSize = 5;
		if(distancetoCam > 30.0) {
			kernelSize = 3;
		}
		// if(distancetoCam > 50.0) {
		// 	kernelSize = 3;
		// }
		if(distancetoCam > 90.0) {
			kernelSize = 1;
		}
	

		int kernelHalf = (kernelSize - 1) / 2;
        if (shadowPos.w > 0.0) {
			float s = 0.0;

    		for (int y = -kernelHalf ; y <= kernelHalf ; y++) {
        		for (int x = -kernelHalf ; x <= kernelHalf ; x++) {
					vec2 offsets = vec2(x * invShadowMapRes, y * invShadowMapRes);
            		vec2 offsetPos = vec2(shadowPos.xy + offsets);
            		// s += float(texture2D_bilinear(shadowtex0, offsetPos, vec2(shadowMapResolution)).r >= shadowPos.z);
					float shadowSample = texture2D(shadowtex0, offsetPos).r;
					s += step(shadowPos.z - shadowSample, shadowBias);
        		}
    		}
			s /= kernelSize*kernelSize;
			return s;
		}
		return 0.0;
    } else {
        return 0.0;
    }
}