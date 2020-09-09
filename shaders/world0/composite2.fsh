#include "/lib/header.glsl"

#extension GL_ARB_shader_texture_lod : enable

uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D depthtex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
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
uniform float frameTimeCounter;
uniform int frameCounter;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

varying vec2 texcoord;

#include "/settings.glsl"
#include "/lib/utility/common_functions.glsl"
#include "/lib/utility/constants.glsl"
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


vec2 rand(vec2 c){
    mat2 m = mat2(12.9898,.16180,78.233,.31415);
	return fract(sin(m * c) * vec2(43758.5453, 14142.1));
}

vec2 noise(vec2 p){
	vec2 co = floor(p);
	vec2 mu = fract(p);
	mu = 3.*mu*mu-2.*mu*mu*mu;
	vec2 a = rand((co+vec2(0.,0.)));
	vec2 b = rand((co+vec2(1.,0.)));
	vec2 c = rand((co+vec2(0.,1.)));
	vec2 d = rand((co+vec2(1.,1.)));
	return mix(mix(a, b, mu.x), mix(c, d, mu.x), mu.y);
}

float getWetness(vec3 pos, vec3 normal, float skyLightMap) {
	float normalElevation = max(viewToWorld(normal).y, 0.0);

	float covered = 28.0/32.0;
    float uncovered = 31.0/32.0;

    float coverAmount = map(skyLightMap, covered, uncovered, 0.0, 1.0);

	float puddle = noise(pos.xz*0.3).x*0.6 + noise(pos.xz*0.6).x*0.3 + noise(pos.xz*2.0).x*0.1;
	puddle = pow(puddle, 1.7);
    return clamp(puddle*pow2(wetness)*coverAmount*normalElevation, 0.0, 1.0);
}

/******************  SPECULAR PASS & WETNESS PASS ******************/

void main() {

	if(texture2D(colortex4, texcoord).a >= 0.2) {
		/* DRAWBUFFERS:01 */
		gl_FragData[0] = vec4(texture2D(gcolor, texcoord).rgb, 1.0); 
		gl_FragData[1] = vec4(vec3(1.0), 1.0); 
		return;
	}

	vec3 color = texture2D(gcolor, texcoord).rgb;
	vec2 lm = texture2D(colortex4, texcoord).rg;

	vec3 normal = decodeNormal3x16(texture2D(colortex1, texcoord).a);//texture2D(gnormal, texcoord).rgb * 2.0 - 1.0;
	normal = worldToView(normal);
	vec3 flatNormal = decodeNormal3x16(texture2D(colortex3, texcoord).a);
	flatNormal = worldToView(flatNormal);

	vec3 specTex = texture2D(colortex3, texcoord).rgb;
	vec3 specular = parseSpecular(specTex);

	float depth = texture2D(depthtex0, texcoord).r;
	vec3 depthViewPoint = getDepthPoint(texcoord, depth);
	vec3 depthWorldPoint = viewToWorld(depthViewPoint);
	vec3 depthViewDir = normalize(depthViewPoint);
	vec3 depthWorldDir = normalize(depthWorldPoint);

	float volumetricRadiance = texture2D(colortex2, texcoord).a;

	//When sky or survivor sense'd mob
	if(depth == 1.0 || texture2D(colortex1, texcoord).a == 1.0) {
		discard;
	}

	float seed = random(texcoord, frameTimeCounter);

	vec3 reflectionCol = vec3(0.0);

	if(specular.r < 0.6) {
		// vec3 weightSum = vec3(0.0);

		for(int s = 0; s < SPECULAR_RAYS; s++) {
			float pdf;
			vec3 reflectedDir = ggx_sample(normal, -depthViewDir, specular.r, pdf, seed);//reflect(depthViewDir, normal);
			// vec3 BRDF = ggx(normal, -depthViewDir, reflectedDir, specular, vec3(1.0));
         	// vec3 weight = BRDF/max(pdf, 1e-5);
        
		
			vec3 reflectionPos = vec3(0.0);

			//Only do reflections on surfaces not too rough
			// if(reflectedDir.z < 0.0) {
				reflectionPos = raymarchEqui(depthViewPoint + normal*0.01, reflectedDir).xyz;
				if(all(equal(reflectionPos, vec3(0.0)))) {
					float dist = samplePanoramic(viewToWorld(reflectedDir), 0.0).a;
					reflectionPos = reflectionPos + reflectedDir*dist;
				}
			// } else {
			// 	float dist = samplePanoramic(viewToWorld(reflectedDir), 0.0).a;
			// 	reflectionPos = reflectionPos + reflectedDir*dist;
			// }
			// reflectionCol /= 1.0 + Luminance(reflectionCol);
			reflectionCol += getReflectionColour(reflectionPos, reflectedDir, depthWorldPoint, 2.0);// * weight; *pow2(samplePanoramic(viewToWorld(reflectedDir), 0.0).a*0.01)
			// weightSum += weight;
		}
		reflectionCol /= SPECULAR_RAYS;//weightSum;//SPECULAR_RAYS;
		// reflectionCol /= 1.1 + Luminance(reflectionCol);
	}

	/*** APPLY SPECULAR ****/

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


	/**** RAIN WETNESS ****/
	
	//Make wetness normal have a little bit of affect from actual normal
	vec3 wetnessNormal = mix(flatNormal, normal, 0.2);
	float wetnessAmount = getWetness(depthWorldPoint + cameraPosition, wetnessNormal, lm.y);

	if(wetnessAmount > 0.001) {

		vec3 rainReflectionCol = vec3(0.0);

		vec3 rainReflectedDir = reflect(depthViewDir, wetnessNormal);

			
			
		vec3 rainReflectionPos = vec3(0.0);

		//WEtness intensity
		float wetnessFresnel = schlick(depthViewDir, wetnessNormal, vec3(0.0, 0.02, 0.0));//*getWetness(normal, lm.y);
		
		rainReflectionPos = raymarchEquiLONG(depthViewPoint + wetnessNormal*0.01, rainReflectedDir).xyz;
		if(all(equal(rainReflectionPos, vec3(0.0)))) {
			float dist = samplePanoramic(viewToWorld(rainReflectedDir), 0.0).a;
			rainReflectionPos = rainReflectionPos + rainReflectedDir*dist;
		}
		rainReflectionCol += getReflectionColour(rainReflectionPos, rainReflectedDir, depthWorldPoint, 1.0);

		

		rainReflectionCol = applyFog(rainReflectionCol, length(depthWorldPoint), cameraPosition, normalize(depthWorldPoint), volumetricRadiance);//Apply fog to speculars
		
		color += rainReflectionCol*wetnessFresnel*wetnessAmount;

	}
/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
	// gl_FragData[0] = vec4(reflectionCol*0.25, texture2D(colortex1, texcoord).a);
}