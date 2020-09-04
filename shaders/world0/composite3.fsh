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
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

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
	// float noise = texture2D(noisetex, mod(gl_FragCoord.xy, 512.0)/512.0).r;
	// float noise_prime = texture2D(noisetex, mod(gl_FragCoord.xy+0.5, 512.0)/512.0).r;
	// float noise_prime_prime = texture2D(noisetex, mod(gl_FragCoord.xy-0.5, 512.0)/512.0).r;
	// normal.x += (noise*2.0-1.0)*0.004;
	// normal.y += (noise_prime*2.0-1.0)*0.004;
	// normal.z += (noise_prime_prime*2.0-1.0)*0.004;
	// normal = normalize(normal);
	normal = worldToView(normal);
	vec3 specTex = texture2D(colortex3, texcoord).rgb;
	vec3 specular = parseSpecular(specTex);

	float depth = texture2D(depthtex0, texcoord).r;
	vec3 depthViewPoint = getDepthPoint(texcoord, depth);
	vec3 depthWorldPoint = viewToWorld(depthViewPoint);
	vec3 depthViewDir = normalize(depthViewPoint);
	vec3 depthWorldDir = normalize(depthWorldPoint);

	if(depth == 1.0 || length(normal) < 0.01) {
		discard;
	}

	//Apply rain wetness darkening
	// color = mix(color, color*0.8, wetness);

	//Only do reflections on surfaces not too rough
    vec3 reflectionCol = float(specular.r < 0.6) * texture2D(colortex1, texcoord * specularResScale).rgb*4.0;//boxBlur(colortex4, texcoord * specularResScale, 1.5).rgb;//


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
	reflectionCol = mix(reflectionCol*schlick3(depthViewDir, normal, albedo*albedo*specular.y), reflectionCol, float(!isMetal(specTex.g)));

	float volumetricRadiance = texture2D(colortex1, texcoord).a;
	if(specular.r < 0.6) {
		vec3 heldLightSpecular = vec3(0.0);
        float heldItemLight = float(max(heldBlockLightValue, heldBlockLightValue2));
        vec3 dayLightCol = blackbody(DAY_EMITTER_TEMP)*EMITTER_INTENSITY*0.1;
        vec3 nightLightCol = vec3(0, 2, 117)/255.0 * 2.0;
        #ifdef NIGHT_TIME_UV
            vec3 lightCol = mix(dayLightCol, nightLightCol, pow4(night));
        #else
            vec3 lightCol = dayLightCol;
        #endif
		if(heldItemLight > 0.9) {
			heldLightSpecular += ggx(normal, -depthViewDir, -depthViewDir, specular, albedo) * heldItemLight * lightCol * exp(-length(depthViewPoint)*0.35) * 0.03;
		}

	    float flashlightOn = float(night > 0.4 || pow2(eyeBrightness.x+eyeBrightness.y) < 60);
	    float flashlight = getFlashlight(texcoord, length(depthViewPoint));
	    vec3 flashlightSpecular = vec3(0.0);
	    if(flashlightOn > 0.9) {
	    	flashlightSpecular = ggx(normal, -depthViewDir, -depthViewDir, specular, albedo)*flashlightOn*min(flashlight, 0.6)*FLASLIGHT_BRIGHTNESS;
	    }
	    vec3 specularCol = reflectionCol + sunSpecular + flashlightSpecular + heldLightSpecular;
		specularCol = applyFog(reflectionCol + sunSpecular + flashlightSpecular + heldLightSpecular, length(depthWorldPoint), cameraPosition, normalize(depthWorldPoint), volumetricRadiance);//Apply fog to speculars
	    // color = mix(color, specularCol, fresnel);
		// color += albedo*specularCol;
		if(isMetal(specTex.g)) {
	    	color = mix(color, specularCol, fresnel);
		} else {
			color += specularCol*fresnel;
		}
	} else {
	    color += max(sunSpecular*fresnel, 0.0);
	}


	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0); 
}
