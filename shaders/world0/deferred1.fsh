#include "/lib/header.glsl"

#extension GL_ARB_shader_texture_lod : enable

uniform sampler2D gcolor;
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
uniform float farDist;
uniform float sunset; 
uniform float night; 
uniform float sunrise; 
uniform ivec2 eyeBrightness;
uniform float fog;
uniform float day;
uniform float wetness;
uniform float frameTimeCounter;
uniform int frameCounter;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

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
#include "/lib/taa_functions.glsl"

/******************  CALCULATE RTAO & GI  ******************/

void main() {
	vec3 lighting = vec3(0.0);

	vec2 uv = texcoord * invRtaoResScale;
	float depth = texture2D(depthtex0, uv).r;
	float depthDist = getDepthPoint(uv, depth).z;
	vec3 specular = texture2D(colortex3, uv).rgb;
	specular = parseSpecular(specular);

	vec3 normal = decodeNormal3x16(texture2D(colortex1, uv).a);

	if(all(lessThan(texcoord, vec2(rtaoResScale))) && depth != 1.0) {

		vec3 depthViewPoint = getDepthPoint(uv, depth);
		vec3 depthWorldPoint = viewToWorld(depthViewPoint);
		
		vec4 lm = texture2D(colortex4, uv);
		lm.x = pow(lm.x, 2.2);

		//Ray quality
		// int raySteps = 8;
		// float stepSize = 1.0;
		// float growth = 1.0;
		// if(lm.x > 0.3) {
		// 	raySteps = 12;
		// 	stepSize = 0.1;
		// 	growth = 1.0;
		// }
		int raySteps = int(mix(8, 15, pow(lm.x, 0.3)));
		float stepSize = mix(1.0, 0.1, pow(lm.x, 0.3));
		float growth = (lm.x < 0.01) ? 1.3 : 1.0;

		float ao = pow3(texture2D(gcolor, uv).a);

		vec3 indirect = vec3(0.0);

		//generate seed
		float seed = random(uv, frameTimeCounter);

		//Calculate indirect
		for(int i = 0; i < ERGI_RAYS; i++) {
			vec3 reflectedDir = cosWeightedRandomHemisphereDirection(normal, seed);//reflect(depthViewDir, normal);

			vec3 reflectionPos = vec3(0.0);

			reflectionPos = raymarchEquiGI(depthViewPoint + normal*0.01, reflectedDir, raySteps, stepSize, growth).xyz;
			if(all(equal(reflectionPos, vec3(0.0)))) {
				float dist = samplePanoramic(viewToWorld(reflectedDir), 0.0).a;
				reflectionPos = reflectionPos + reflectedDir*dist;
			}

			float dist = samplePanoramic(viewToWorld(reflectedDir), 0.0).a;
			float closeness = clamp(pow2(clamp(dist, 0.0, 2.0)), 0.3, 1.0);

			//If the ray went to sky, make it affected by sky lightmap
			float isSky = float(samplePanoramic(viewToWorld(reflectedDir), 0.0).a > 90);
			float skyAmount = mix(1.0, pow2(lm.y), isSky);

			indirect += getReflectionColour(reflectionPos, reflectedDir, depthWorldPoint, 5.0)*skyAmount;
		}
		indirect /= ERGI_RAYS;

		//Make indirect more saturated
		// indirect = mix(indirect, vec3(Luminance(indirect)), vec3(1.0 - 1.15));
		lighting += indirect;

	}
	vec2 reprojectedCoords = reproject(vec3(uv, texture2D(depthtex0, uv).r));
	vec3 history = textureLod(colortex2, reprojectedCoords*rtaoResScale, 0.0).rgb;

	float previousDepth = texture2D(depthtex0, reprojectedCoords).r;
	float previousDist = getDepthPoint(reprojectedCoords, previousDepth).z;
	vec3 previousNormal = decodeNormal3x16(texture2D(colortex1, reprojectedCoords).a);

	float weight = 0.9;
	if( clamp(reprojectedCoords, 0.0, 1.0) != reprojectedCoords) {
		weight = 0.0;
	}

	vec3 write = mix(lighting, history, weight);


/* DRAWBUFFERS:2 */
	gl_FragData[0] = vec4(write, texture2D(colortex2, texcoord).a); //colortex2 (ao gi accumulate)
}