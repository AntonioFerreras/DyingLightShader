#include "/lib/header.glsl"

#extension GL_ARB_shader_texture_lod : enable

/*
const bool colortex0MipmapEnabled = true;
const bool colortex7MipmapEnabled = true;
const int noiseTextureResolution = 512;
*/

uniform sampler2D gcolor;
uniform sampler2D colortex6;
uniform sampler2D gnormal;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
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
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform float viewHeight;
uniform float viewWidth;
uniform float near;
uniform float far;
uniform float farDist;
uniform float sunset; 
uniform float night; 
uniform float sunrise; 
uniform float frameTimeCounter;  
uniform float fog;
uniform float day;
uniform float wetness;

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
#include "/lib/shadows.glsl"
#include "/lib/sun.glsl"
#include "/lib/encoding.glsl"
#include "/lib/volumetrics.glsl"
#include "/lib/raytracing.glsl"
#include "/lib/water.glsl"

#define ITERATIONS_NORMAL 18 //28

/******************  WATER PASS  ******************/

vec3 constructNormal(float depthA, vec2 texcoords, sampler2D depthtex) {
    const vec2 offsetB = vec2(0.0,0.001);
    const vec2 offsetC = vec2(0.001,0.0);
  
    float depthB = texture2D(depthtex, texcoords + offsetB).r;
    float depthC = texture2D(depthtex, texcoords + offsetC).r;
  
    vec3 A = getDepthPoint(texcoords, depthA);
	vec3 B = getDepthPoint(texcoords + offsetB, depthB);
	vec3 C = getDepthPoint(texcoords + offsetC, depthC);

	vec3 AB = normalize(B - A);
	vec3 AC = normalize(C - A);

	vec3 normal =  -cross(AB, AC);
	// normal.z = -normal.z;

	return normalize(normal);
}




void main() {
	float waterOrNah = texture2D(colortex4, texcoord).a;
	if(waterOrNah < 0.2) {
		/* DRAWBUFFERS:0 */
		gl_FragData[0] = vec4(texture2D(gcolor, texcoord).rgb, 1.0); 
		return;
	}

	
	// Water point
	float depth = texture2D(depthtex0, texcoord).r;
	vec3 depthViewPoint = getDepthPoint(texcoord, depth);
	vec3 depthViewDir = normalize(depthViewPoint);
	vec3 depthWorldPoint = viewToWorld(depthViewPoint);
	vec3 depthWorldDir = normalize(depthWorldPoint);

	// Water normals
	vec3 flatNormal = viewToWorld(constructNormal(depth, texcoord, depthtex0));
	vec3 normal = flatNormal;
	float waveHeight = 0.0;
	if(waterOrNah > 0.9) {
		int iterations = 18;
		float bias = dot(normalize(upPosition), -depthViewDir);
		float normalDepth = map(pow(bias, 0.2), 0.0, 1.0, 0.05, 1.0);
		iterations = int(map(pow(bias, 0.25), 0.0, 1.0, 6.0, 34.0));
		normal = getWaterNormal((depthWorldPoint + cameraPosition).xz, iterations, normalDepth, waveHeight);
	
	}
	normal = worldToView(normal);

	// Underwater point
	vec2 refractedCoord = calcRefract(texcoord, normal);
	vec3 color = texture2D(gcolor, refractedCoord).rgb;
	float depth1 = texture2D(depthtex1, refractedCoord).r;
	vec3 depth1ViewPoint = getDepthPoint(refractedCoord, depth1);

	float distanceTransmitted = distance(depthViewPoint, depth1ViewPoint);

	//Apply Beer-Lambert law 
	color *= exp(-mix(WATER_ABSORP, WATER_ABSORP_FOG, fog) * distanceTransmitted*2.0);

	//Scattering
	vec3 scatter = (vec3(8, 15, 18)/255.0);
	color = mix(color, scatter, (1.0-exp(-distanceTransmitted*0.2))*day*(1.0-fog)*0.99);

	// vec3 H = normalize(waveHeight + viewToWorld(sunPosition));
	// float viewDotH = pow(clamp01(dot(depthWorldDir, -H)), 5.0);
	// color = color + (1.0 - WATER_ABSORP)*viewDotH;

	vec3 specularity = vec3(0.1, 0.02, 0.0);

	//Fresnel
	float fresnel = schlick(depthViewDir, normal, specularity);


	float shadow = shadowFast(depthViewPoint, normal);
	vec3 sunSpecular = ggx(normal, -depthViewDir, normalize(sunPosition), specularity, vec3(1.0))*sunCol*SUN_BRIGHTNESS*shadow* (1.0-fog) ;
	// vec3 foggedSunSpecular = applyFog(sunSpecular, 9999.0, depthWorldPoint + cameraPosition, viewToWorld(normalize(sunPosition)), 1.0);
	// sunSpecular = mix(sunSpecular, foggedSunSpecular, shadow);

	//Reflections
	vec3 reflectedDir = reflect(depthViewDir, normal);
	vec3 reflectionPos = vec3(0.0);
	vec3 reflectionCol = vec3(0.0);

	// if(reflectedDir.z < 0.0 || true) {
		reflectionPos = raymarchEquiLONG(depthViewPoint + flatNormal*0.6, reflectedDir).xyz;
		if(all(equal(reflectionPos, vec3(0.0)))) {
			float dist = samplePanoramic(viewToWorld(reflectedDir), 0.0).a;
			reflectionPos = reflectionPos + reflectedDir*dist;
		}
	// }
	//  else {
	// 	float dist = samplePanoramic(viewToWorld(reflectedDir), 0.0).a;
	// 	reflectionPos = reflectionPos + reflectedDir*dist;
	// }
	reflectionCol = getReflectionColour(reflectionPos, reflectedDir, depthWorldPoint, 0.0);

	if(length(reflectionPos) < length(depthViewPoint)) {//all(lessThan(panoramicSample.rgb, vec3(0.0))) || 
		reflectionCol = sampleSky(viewToWorld(reflectedDir), vec3(0,6372e3,0), normalize(viewToWorld(sunPosition)), normalize(viewToWorld(moonPosition)), false);
		reflectionCol = applyFog(reflectionCol, farDist, depthWorldPoint, viewToWorld(reflectedDir), 1.0); // Apply fog to sky sample
	}
	// if(all(equal(reflectionPos, vec4(0.0)))) {
	// 	// vec3 sampleDir = approxParallax(depthViewPoint, reflectedDir);
	// 	vec3 sampleDir = worldToView(correct(viewToWorld(reflectedDir), depthWorldPoint));
	// 	vec4 panoramicSample = samplePanoramic(viewToWorld(sampleDir), 0);
	// 	reflectionCol = panoramicSample.rgb;
		// if(panoramicSample.a < depth || panoramicSample.a == 1.0) {//all(lessThan(panoramicSample.rgb, vec3(0.0))) || 
		// 	reflectionCol = sampleSky(viewToWorld(reflectedDir), vec3(0,6372e3,0), normalize(viewToWorld(sunPosition)), normalize(viewToWorld(moonPosition)), false);
		// 	reflectionCol = applyFog(reflectionCol, 99.0, depthWorldPoint, viewToWorld(reflectedDir), 1.0); // Apply fog to sky sample
		// }
	// } else {
	// 	reflectionCol = textureLod(gcolor, viewToScreen(reflectionPos.xyz), 2).rgb;
	// }
	// if(dot(normal, -depthViewDir) < 0.03) {
	// 	fresnel = 0.1;
	// }
	float volumetricRadiance = texture2D(colortex2, texcoord).a;
	color = mix(color, reflectionCol + sunSpecular, fresnel);
	// color += (color, reflectionCol + sunSpecular)*fresnel;
	color = applyFog(color, length(depthWorldPoint), cameraPosition, normalize(depthWorldPoint), volumetricRadiance);//Apply fog to complete water


/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0); 
}