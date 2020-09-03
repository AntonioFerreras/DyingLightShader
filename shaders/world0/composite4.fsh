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

varying vec2 texcoord;

#include "/settings.glsl"
#include "/lib/utility/common_functions.glsl"
#include "/lib/utility/constants.glsl"
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

/******************  RAIN WETNESS SPECULAR PASS  ******************/

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


void main() {
	vec2 uv = texcoord;


	vec3 color = texture2D(gcolor, uv).rgb;
	vec3 normal = texture2D(gnormal, uv).rgb * 2.0 - 1.0;
	// float noise = texture2D(noisetex, mod(gl_FragCoord.xy, 512.0)/512.0).r;
	// float noise_prime = texture2D(noisetex, mod(gl_FragCoord.xy+0.5, 512.0)/512.0).r;
	// float noise_prime_prime = texture2D(noisetex, mod(gl_FragCoord.xy-0.5, 512.0)/512.0).r;
	// normal.x += (noise*2.0-1.0)*0.004;
	// normal.y += (noise_prime*2.0-1.0)*0.004;
	// normal.z += (noise_prime_prime*2.0-1.0)*0.004;
	// normal = normalize(normal);
	normal = worldToView(normal);



	float depth = texture2D(depthtex0, uv).r;
	vec3 depthViewPoint = getDepthPoint(uv, depth);
	vec3 depthWorldPoint = viewToWorld(depthViewPoint);
	vec3 depthViewDir = normalize(depthViewPoint);
	vec3 depthWorldDir = normalize(depthWorldPoint);

	vec2 lm = texture2D(colortex4, uv).rg;
	vec3 flatNormal = decode3x16(texture2D(gnormal, uv).a) * 2.0 - 1.0;
	flatNormal = normalize(round(flatNormal));
	flatNormal = worldToView(flatNormal);

	//Make flat normal have a little bit of affect from actual normal
	flatNormal = mix(flatNormal, normal, 0.2);


	float wetnessAmount = getWetness(depthWorldPoint + cameraPosition, flatNormal, lm.y);
	
	if(texture2D(colortex4, uv).a >= 0.2 || wetnessAmount < 0.005) {
		/* DRAWBUFFERS:0 */
		gl_FragData[0] = vec4(texture2D(gcolor, uv).rgb, 1.0); 
		return;
	}

	if(depth == 1.0 || length(normal) < 0.01) {
		discard;
	}

	// normal = constructNormal(depth, uv, depthtex0);

	float seed = random(uv, frameTimeCounter);

	vec3 reflectionCol = vec3(0.0);

	vec3 reflectedDir = reflect(depthViewDir, flatNormal);

        
		
	vec3 reflectionPos = vec3(0.0);

	//WEtness intensity
	float fresnel = schlick(depthViewDir, flatNormal, vec3(0.0, 0.02, 0.0));//*getWetness(normal, lm.y);
	

	//Only do reflections on surfaces not too rough
	if(reflectedDir.z < 0.0) {
		reflectionPos = raymarchEquiLONG(depthViewPoint + flatNormal*0.01, reflectedDir).xyz;
		if(all(equal(reflectionPos, vec3(0.0)))) {
			float dist = samplePanoramic(viewToWorld(reflectedDir), 0.0).a;
			reflectionPos = reflectionPos + reflectedDir*dist;
		}
	} else {
		float dist = samplePanoramic(viewToWorld(reflectedDir), 0.0).a;
		reflectionPos = reflectionPos + reflectedDir*dist;
	}
	reflectionCol += getReflectionColour(reflectionPos, reflectedDir, depthWorldPoint, 1.0);

	float volumetricRadiance = texture2D(colortex1, texcoord).a;

	reflectionCol = applyFog(reflectionCol, length(depthWorldPoint), cameraPosition, normalize(depthWorldPoint), volumetricRadiance);//Apply fog to speculars
	
	color += reflectionCol*fresnel*wetnessAmount;

	// color = applyFog(color, length(depthWorldPoint), cameraPosition, normalize(depthWorldPoint), volumetricRadiance);//Apply fog to speculars
	// color = mix(color, reflectionCol, fresnel*wetness);

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
}