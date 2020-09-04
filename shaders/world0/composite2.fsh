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
uniform float frameTimeCounter;
uniform int frameCounter;

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
#include "/lib/taa_shit.glsl"

/******************  SPECULAR RAY MARCH PASS  ******************/

void main() {
	vec2 uv = texcoord * invSpecularResScale;

	if(texture2D(colortex4, uv).a >= 0.2 || any(greaterThan(texcoord, vec2(specularResScale)))) {
		/* DRAWBUFFERS:01 */
		gl_FragData[0] = vec4(texture2D(gcolor, uv).rgb, 1.0); 
		gl_FragData[1] = vec4(vec3(1.0), 1.0); 
		return;
	}

	vec3 color = texture2D(gcolor, uv).rgb;
	vec2 lm = texture2D(colortex4, uv).rg;
	vec3 normal = texture2D(gnormal, uv).rgb * 2.0 - 1.0;
	// float noise = texture2D(noisetex, mod(gl_FragCoord.xy, 512.0)/512.0).r;
	// float noise_prime = texture2D(noisetex, mod(gl_FragCoord.xy+0.5, 512.0)/512.0).r;
	// float noise_prime_prime = texture2D(noisetex, mod(gl_FragCoord.xy-0.5, 512.0)/512.0).r;
	// normal.x += (noise*2.0-1.0)*0.004;
	// normal.y += (noise_prime*2.0-1.0)*0.004;
	// normal.z += (noise_prime_prime*2.0-1.0)*0.004;
	// normal = normalize(normal);
	normal = worldToView(normal);
	vec3 specTex = texture2D(colortex3, uv).rgb;
	vec3 specular = parseSpecular(specTex);

	float depth = texture2D(depthtex0, uv).r;
	vec3 depthViewPoint = getDepthPoint(uv, depth);
	vec3 depthWorldPoint = viewToWorld(depthViewPoint);
	vec3 depthViewDir = normalize(depthViewPoint);
	vec3 depthWorldDir = normalize(depthWorldPoint);

	if(depth == 1.0 || length(normal) < 0.01) {
		discard;
	}

	float seed = random(uv, frameTimeCounter);

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



/* DRAWBUFFERS:1 */
	// gl_FragData[0] = vec4(color, 1.0);
	gl_FragData[0] = vec4(reflectionCol*0.25, texture2D(colortex1, uv).a);
}