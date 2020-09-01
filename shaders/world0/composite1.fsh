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


vec2 wavedx(vec2 position, vec2 direction, float frequency, float speed, float timeshift) {
    float x = dot(direction, position) * frequency + timeshift * speed * WATER_WAVE_SPEED;
    float wave = exp(sin(x) - 1.0);
    float dx = -wave * cos(x);
    return vec2(wave, dx);
}

float getWaves(vec2 position, int iterations){
	// position *= 50.0;
	// return sin(position.x + frameTimeCounter) * cos(position.y + frameTimeCounter);
    float iter = 0.0;
    float phase = 1.8;
    float weight = 1.0;
    float w = 0.0;
    float ws = 0.0;
    for(int i =0 ; i<iterations; i++){
        vec2 p = vec2(sin(iter), cos(iter));
        vec2 res = wavedx(position, p, phase, 1.0, frameTimeCounter);
        position += normalize(p) * res.y * weight * 0.0048;
        w += res.x * weight;
        iter += 12.0;
        ws += weight;
        weight = mix(weight, 0.0, 0.2);
        phase *= 1.18;
    }
    return w / ws;
}
vec3 getWaterNormal(vec2 pos, int iter, float depth){
	pos *= 1.9;
    float e = 0.08;//Epsilon
    vec2 ex = vec2(e, 0);
    float H = getWaves(pos.xy * 0.1, iter) * depth;
    vec3 a = vec3(pos.x, H, pos.y);
    vec3 normal = normalize(cross(normalize(a-vec3(pos.x - e, getWaves(pos.xy * 0.1 - ex.xy * 0.1, iter) * depth, pos.y)),
    normalize(a-vec3(pos.x, getWaves(pos.xy * 0.1 + ex.yx * 0.1, iter) * depth, pos.y + e))));
    return normal;
}

vec2 calcRefract(vec2 coord, vec3 normal) {
	float depth0 = texture2D(depthtex0, coord).r;	
	float depth1 = texture2D(depthtex1, coord).r;	
	if(depth0 >= depth1) return coord;

	vec3 depthPoint0 = getDepthPoint(coord, depth0);
	vec3 depthPoint1 = getDepthPoint(coord, depth1);

	vec3 normalFlat = vec3(0.0, 1.0, 0.0);

	float refractionDepth = min(distance(depthPoint0, depthPoint1), 0.5);

	vec2 refractedCoord = coord + (viewToWorld(normal).xz - normalFlat.xz) * refractionDepth / depthPoint0.z;

	float refractedDepth = texture2D(depthtex1, refractedCoord).r;
	return depth0 > refractedDepth ? coord : refractedCoord;
}

const vec3 WATER_ABSORP = vec3(WATER_ABSORP_R, WATER_ABSORP_G, WATER_ABSORP_B);
const vec3 WATER_ABSORP_FOG = vec3(0.2, 0.15, 0.12);

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
	if(waterOrNah > 0.9) {
		int iterations = 18;
		float bias = dot(normalize(upPosition), -depthViewDir);
		float normalDepth = map(pow(bias, 0.2), 0.0, 1.0, 0.05, 1.0);
		iterations = int(map(pow(bias, 0.25), 0.0, 1.0, 6.0, 34.0));
		normal = getWaterNormal((depthWorldPoint + cameraPosition).xz, iterations, normalDepth);
	
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
	float volumetricRadiance = texture2D(colortex1, texcoord).a;
	color = mix(color, reflectionCol + sunSpecular, fresnel);
	color = applyFog(color, length(depthWorldPoint), cameraPosition, normalize(depthWorldPoint), volumetricRadiance);//Apply fog to complete water


/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0); 
}