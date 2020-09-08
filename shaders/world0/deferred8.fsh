#include "/lib/header.glsl"

#extension GL_ARB_shader_texture_lod : enable

/*
const bool colortex7MipmapEnabled = true;
*/

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D gnormal;
uniform sampler2D noisetex;
uniform sampler2D colortex1;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex7;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;  
uniform float viewHeight, viewWidth;
uniform vec3 cameraPosition;
uniform vec3 sunPosition; 
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;    
uniform float frameTimeCounter;
uniform float far;
uniform float day;
uniform float fog;
uniform float night;
uniform float sunset; 
uniform float wetness; 
uniform float sunrise; 
uniform ivec2 eyeBrightness;

varying vec2 texcoord;

// colortex0 = gcolor = game colour.rgb + vanillaAO.a
// colortex1 = aoGI.rgb + normals.a
// colortex2 = aoGIHistory.rgb + volumetricRadiance.a
// colortex3 = specularity.rg + (emission & subsurface).b + flatNormals.a
// colortex4 = lightmaps.rg + transMask.b + isWater.a 
// colortex5 = sky / albedo.rgb + shadow.a
// colortex6 = TAA.rgb + exposure.a
// colortex7 = temporal buffer for equirectangular environment map

#include "/settings.glsl"
#include "/lib/resScales.glsl"
#include "/lib/utility/common_functions.glsl"
#include "/lib/utility/constants.glsl"
#include "/lib/utility/texture_filter.glsl"
#include "/lib/view.glsl"
#include "/lib/math.glsl"
#include "/lib/sky.glsl"
#include "/lib/survivor_sense.glsl"
#include "/lib/flashlight.glsl"
#include "/lib/shadows.glsl"
#include "/lib/encoding.glsl"
#include "/lib/materials.glsl"
#include "/lib/sun.glsl"
#include "/lib/volumetrics.glsl"
#include "/lib/raytracing.glsl"

vec3 dayLightCol = blackbody(DAY_EMITTER_TEMP)*EMITTER_INTENSITY*0.1;
vec3 nightLightCol = vec3(0, 2, 117)/255.0 * 2.0;
#ifdef NIGHT_TIME_UV
vec3 lightCol = mix(dayLightCol, nightLightCol, pow4(night));
#else
vec3 lightCol = dayLightCol;
#endif

const vec3 nightAmbient = vec3(9, 16, 41)/255.0 * 0.03;

vec3 flashLightCol = blackbody(FLASHLIGHT_TEMP);

vec3 directLight(vec3 p, vec3 n, out float sunShadow) {
	if(day < 0.001 || fog > 0.99) {
		return vec3(0.0);
	}
	sunShadow = shadow(p, n);
	return clamp(dot(normalize(sunPosition), n), 0.0, 1.0) * SUN_BRIGHTNESS * sunCol * sunShadow * day;
}

vec2 getVelocity() {
	vec3 previousRDWorld = (inverse(gbufferPreviousModelView) * vec4(0, 0, -1, 0)).xyz;
	return worldToView(previousRDWorld).xy;
}

vec3 subsurface(vec3 viewPoint, vec3 lightDir) {
	vec3 worldPoint = viewToWorld(viewPoint);

	vec4 playerPos = gbufferModelViewInverse * vec4(viewPoint, 1.0);
	vec4 shadowPos = shadowProjection * (shadowModelView * playerPos); //convert to shadow screen space
	float distortFactor = getDistortFactor(shadowPos.xy);
	shadowPos.xyz = distort(shadowPos.xyz, distortFactor); //apply shadow distortion
	shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
	float shadowBias =  SHADOW_BIAS * (distortFactor * distortFactor);
	// shadowPos.z -= shadowBias; //apply shadow bias
	shadowPos.z -= 0.0001;

	float shadowZ = texture2D(shadowtex0, shadowPos.xy).r;

	float travelDist = shadowPos.z - shadowZ;

	vec3 sunLight = SUN_BRIGHTNESS * sunCol * day;

	float VdotL = clamp(dot(-normalize(viewPoint), -lightDir), 0.0, 1.0);
	VdotL = max(pow(VdotL, 3.0), 0.3);



	if(travelDist < 0.0)  {
		return sunLight * VdotL;
	}
	// return max(sunLight * (travelDist/0.1), vec3(0.0));
	return sunLight*exp(-travelDist*1000.00) * VdotL;
}

void main() {
	vec3 color = texture2D(gcolor, texcoord).rgb;
	vec3 normal = decodeNormal3x16(texture2D(colortex1, texcoord).a);//texture2D(gnormal, texcoord).rgb * 2.0 - 1.0;
	normal = worldToView(normal);
	vec3 specular = texture2D(colortex3, texcoord).rgb;
	specular = parseSpecular(specular);


	vec2 emissionAndSubsurface = decode2x16(texture2D(colortex3, texcoord).b);
	float isEmissive = emissionAndSubsurface.x;
	float subsurfaceAmount = emissionAndSubsurface.y*2.0;

	float depth0 = texture2D(depthtex0, texcoord).r;
	vec4 lm = texture2D(colortex4, texcoord);
	lm.x = pow(lm.x, 2.2);

	if(length(normal) < 0.01) {
		/* DRAWBUFFERS:05 */
		gl_FragData[0] = vec4(toLinear(color), 1.0); //gcolor
		gl_FragData[1] = vec4(vec3(1.0), 1.0); // colortex5
		return;
	}

	if(depth0 == 1.0) {
		color = texture2D(colortex5, texcoord*atmosResScale).rgb;
		/* DRAWBUFFERS:0 */
		gl_FragData[0] = vec4(color, 1.0); //gcolor
		return;
	}
	


	vec3 depth0ViewPoint = getDepthPoint(texcoord, depth0);
	vec3 depth0WorldPoint = viewToWorld(depth0ViewPoint);

	vec3 rayDir = normalize(depth0ViewPoint);

	vec2 velocity = getVelocity();

	//FLASHLIGHT
	float flashlightOn = float(night > 0.4 || pow2(eyeBrightness.x+eyeBrightness.y) < 60);
	float flashlight = getFlashlight(texcoord - clamp(velocity*FLASHLIGHT_LAG_AMOUNT, -0.6, 0.6), length(depth0ViewPoint))*clamp(dot(normal, vec3(0,0,1)), 0.2, 1.0)*flashlightOn;

	vec3 albedo = vec3(0.0);
	vec3 sunDir = normalize(sunPosition);
	float sunShadow = 0.0;
	albedo = toLinear(color);
	albedo *= vec3(245,236,217)/255.0;

	#ifdef WHITE_WORLD
	albedo = vec3(1.0);
	#endif
	
	//SUNLIGHT
	float noise_1 = fract(texture2D(noisetex, mod(gl_FragCoord.xy, 512.0)/512.0).r + frameTimeCounter*4.12348543);
	float noise_2 = fract(texture2D(noisetex, mod(gl_FragCoord.xy+0.5, 512.0)/512.0).r + frameTimeCounter*4.12348543);
	float noise_3 = fract(texture2D(noisetex, mod(gl_FragCoord.xy-0.5, 512.0)/512.0).r + frameTimeCounter*4.12348543);
	vec3 noise = vec3(noise_1, noise_2, noise_3) * 2.0 - 1.0; // -1 to 1
	vec3 sunLight = directLight(depth0ViewPoint+noise*0.02, normal, sunShadow) * (1.0-fog);
	// vec3 foggedSunLight = applyFog(sunLight, 9999.0, depth0WorldPoint + cameraPosition, viewToWorld(sunDir), 1.0);
	// sunLight = mix(sunLight, foggedSunLight, sunShadow);
		
	//AMBIENT & BLOCKLIGHT

	#ifdef ERGI_ENABLED
	vec3 ambient = texture2D(colortex1, texcoord).rgb;
	vec3 blockLight = pow2(lm.x)*lightCol*EMITTER_INTENSITY*0.5;
	#else
	float ao = pow3(texture2D(gcolor, texcoord).a);
	vec3 dayAmbient = mix(texture2D(colortex5, vec2(1.0)).rgb, vec3(0.15), 0.7);
	vec3 ambient = mix(dayAmbient, nightAmbient, pow(night, 0.5));//*1.3
	ambient = ambient*pow2(lm.y)*ao*AMBIENT_INTENSITY;
	vec3 blockLight = pow2(lm.x)*lightCol*EMITTER_INTENSITY;
	#endif

	//Subsurface
	if(subsurfaceAmount > 1.599) { // Make grass SSS have nice gradient
		float y = mod(depth0WorldPoint.y + cameraPosition.y + gbufferModelViewInverse[3].y, 1.0);
		subsurfaceAmount *= pow(1.5*y, 2.0) + 0.15;
	} else if(subsurfaceAmount > 1.55) {
		subsurfaceAmount *= 2.4;
	}
	vec3 subsurface = subsurface(depth0ViewPoint+noise*0.02, sunDir) * subsurfaceAmount * max(1.0-fog, 0.1);

	//EMission
	vec3 emission = pow(length(albedo), 4.0) * isEmissive * lightCol * 30.0 * albedo;

	// vec3 irradiance = samplePanoramic(viewToWorld(normal), 3).rgb;
	// vec3 indirectRayPos = raymarchEqui(depth0ViewPoint, normal).xyz;
	// vec3 irradiance = samplePanoramic(viewToWorld(indirectRayPos), 8).rgb;

	//Apply scene lighting
	color = albedo*(sunLight + ambient + blockLight + min(flashlight*flashLightCol, 0.6)*FLASLIGHT_BRIGHTNESS + subsurface) + emission;

/* DRAWBUFFERS:05 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
	gl_FragData[1] = vec4(albedo, sunShadow); // colortex5
}