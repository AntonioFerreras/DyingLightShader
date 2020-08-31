#include "/lib/header.glsl"

#extension GL_ARB_shader_texture_lod : enable

/*
const bool colortex0MipmapEnabled = true;
const bool colortex7MipmapEnabled = true;
const int noiseTextureResolution = 512;
*/

uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D depthtex0;
uniform sampler2D colortex1;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex7;
uniform sampler2D noisetex;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;    
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 cameraPosition;
uniform vec3 upPosition;
uniform float viewHeight;
uniform float viewWidth;
uniform float near;
uniform float far;
uniform float sunset; 
uniform float night; 
uniform float sunrise; 
uniform ivec2 eyeBrightness;
uniform float fog;
uniform float day;
uniform float wetness;

varying vec2 texcoord;

#include "/settings.glsl"
#include "/lib/utility/common_functions.glsl"
#include "/lib/utility/constants.glsl"
#include "/lib/utility/texture_filter.glsl"
#include "/lib/resScales.glsl"
#include "/lib/math.glsl"
#include "/lib/view.glsl"
#include "/lib/sky.glsl"
#include "/lib/materials.glsl"
#include "/lib/flashlight.glsl"
#include "/lib/sun.glsl"
#include "/lib/shadows.glsl"
#include "/lib/encoding.glsl"
#include "/lib/volumetrics.glsl"
#include "/lib/raytracing.glsl"

/******************  SPECULAR APPLICATION PASS  ******************/

vec2 invScreenRes = 1.0 / vec2(viewWidth, viewHeight);

void main() {
    vec3 color = texture2D(gcolor, texcoord).rgb;
	vec3 normal = texture2D(gnormal, texcoord).rgb * 2.0 - 1.0;
	float noise = texture2D(noisetex, mod(gl_FragCoord.xy, 512.0)/512.0).r;
	float noise_prime = texture2D(noisetex, mod(gl_FragCoord.xy+0.5, 512.0)/512.0).r;
	float noise_prime_prime = texture2D(noisetex, mod(gl_FragCoord.xy-0.5, 512.0)/512.0).r;
	// normal.x += (noise*2.0-1.0)*0.004;
	// normal.y += (noise_prime*2.0-1.0)*0.004;
	// normal.z += (noise_prime_prime*2.0-1.0)*0.004;
	normal = normalize(normal);
	normal = worldToView(normal);
	vec3 specTex = texture2D(colortex3, texcoord).rgb;
	vec3 specular = parseSpecular(specTex);

	float depth = texture2D(depthtex0, texcoord).r;
	vec3 depthViewPoint = getDepthPoint(texcoord, depth);
	vec3 depthWorldPoint = viewToWorld(depthViewPoint);
	vec3 depthViewDir = normalize(depthViewPoint);
	vec3 depthWorldDir = normalize(depthWorldPoint);

	// if(depth == 1.0) {
	// 	discard;
	// }

	//Apply rain wetness darkening
	// color = mix(color, color*0.8, wetness);

	//Only do reflections on surfaces not too rough
    vec3 reflectionCol = vec3(0.0);
	if(specular.r < 0.6) {
		// if(dot(normal, -depthViewDir) < 0.13) {
		// 	normal = getSecondBestNormal(normal, -depthViewDir);
		// };
		
        reflectionCol = texture2D(colortex1, texcoord * specularResScale).rgb*4.0;//boxBlur(colortex4, texcoord * specularResScale, 1.5).rgb;//

        

        //Apply weight (BRDF/PDF)
        

        // vec3 result = vec3(0.0);
        // vec3 weightSum = vec3(0.0);

        // int size = 1;

        // for (int y = -size ; y <= size ; y++) {
        // 	for (int x = -size ; x <= size ; x++) {
		// 		vec2 offsets = vec2(x * invScreenRes.x, y * invScreenRes.y);
        //         vec2 offsetPos = texcoord + offsets;

        //         vec3 reflectedPos = texture2D(colortex4, offsetPos).xyz;
        //         vec3 reflectedDir = normalize(reflectedPos - depthViewPoint);
        //         vec3 reflectedCol = getReflectionColour(reflectedPos, reflectedDir, depthWorldPoint);

        //         // vec3 BRDF = ggx(normal, -depthViewDir, reflectedDir, specular, vec3(1.0));
        //         // float pdf = texture2D(colortex4, offsetPos).a;
        //         // vec3 weight = BRDF/max(pdf, 1e-5);
        //         vec3 weight = vec3(1.0);

        //         // reflectedCol /= 1.0 + Luminance(reflectedCol);

        //         result += reflectedCol * weight;
        //         weightSum += weight;

        //     }
        // }
        // result /= weightSum;
        // // result /= 1.0 + Luminance(result);

        // reflectionCol = result;


	}


    //Fresnel
	float fresnel = schlick(depthViewDir, normal, specular);
	fresnel = mix(fresnel*fresnel, fresnel, float(isMetal(specTex.g)));

	//Direct sun light 
	vec4 albedoAndSun = texture2D(colortex5, texcoord);
	vec3 albedo = albedoAndSun.rgb;
	float sunShadow = albedoAndSun.a;
	// vec3 fogAmount = applyFog(vec3(1.0), 9999.0, depthWorldPoint + cameraPosition, viewToWorld(normalize(sunPosition)), 1.0);
	vec3 sunSpecular = ggx(normal, -depthViewDir, normalize(sunPosition), specular, albedo)*sunCol*SUN_BRIGHTNESS*sunShadow * (1.0-fog)*0.2;

	//Apply albedo tint
	if(isMetal(specTex.g)) {
	    reflectionCol *= albedo*albedo;
	}
	float volumetricRadiance = texture2D(colortex1, texcoord).a;
	if(specular.r < 0.6) {
	    float flashlightOn = float(night > 0.4 || pow2(eyeBrightness.x+eyeBrightness.y) < 60);
	    float flashlight = getFlashlight(texcoord, length(depthViewPoint));
	    vec3 flashlightSpecular = vec3(0.0);
	    if(flashlightOn > 0.9) {
	    	flashlightSpecular = ggx(normal, -depthViewDir, -depthViewDir, specular, albedo)*flashlightOn*min(flashlight, 0.6)*FLASLIGHT_BRIGHTNESS;
	    }
	    vec3 specularCol = applyFog(reflectionCol + sunSpecular + flashlightSpecular, length(depthWorldPoint), cameraPosition, normalize(depthWorldPoint), volumetricRadiance);//Apply fog to speculars
	    // color = mix(color, specularCol, fresnel);
		// color += albedo*specularCol;
		if(isMetal(specTex.g)) {
	    	color = mix(color, specularCol, fresnel);
		} else {
			color +=specularCol*fresnel;
		}
	} else {
	    color += max(sunSpecular*fresnel, 0.0);
	}


	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0); 
}
