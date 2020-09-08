#include "/lib/header.glsl"


#extension GL_ARB_shader_texture_lod : enable

uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D depthtex0;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;    
uniform vec3 previousCameraPosition;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform ivec2 eyeBrightness;
uniform float fog;
uniform float day;
uniform float wetness;
uniform vec3 upPosition;
uniform float viewHeight;
uniform float viewWidth;
uniform float sunset; 
uniform float sunrise; 
uniform float night; 
uniform vec3 sunPosition; 
uniform vec3 moonPosition;
uniform vec3 cameraPosition; 
uniform float frameTimeCounter;
uniform float farDist;    
uniform vec2 resolution;

varying vec2 texcoord;

vec2 invRes = 1.0/resolution;

#include "/settings.glsl"
#include "/lib/utility/common_functions.glsl"
#include "/lib/math.glsl"
#include "/lib/utility/constants.glsl"
#include "/lib/resScales.glsl"
#include "/lib/view.glsl"
#include "/lib/sun.glsl"
#include "/lib/sky.glsl"
#include "/lib/shadows.glsl"
#include "/lib/volumetrics.glsl"
#include "/lib/taa_functions.glsl"

//From Raspberry by Rutherin <3
float calculateAverageLuminance() {
    const float maxLumaRange  = 1.5;
    const float minLumaRange  = 0.001;
    const float exposureDecay = 0.01*EXPOSURE_SPEED;

    float avglod = int(exp2(min(viewWidth, viewHeight))) - 1;

	float averagePrevious = max(texture2DLod(colortex6, vec2(0.0), 0.0).a, 0.0);
    float averageCurrent  = clamp(sqrt(dot(texture2DLod(gcolor, vec2(0.5), avglod).rgb, vec3(0.2125, 0.7154, 0.0721))), minLumaRange, maxLumaRange)*2.5;

    return max(mix(averagePrevious, averageCurrent, exposureDecay), 0.0);
}

/******************  WRITE TO EQUIRECTANGULAR BUFFER & SUN & TAA & EXPOSURE ******************/

void main() {

	/**** WRITE TO EQUI BUFFER ****/

	//Get rotation angles of current place on equirectangular map
	float theta = texcoord.y * 2.0 * PI ;
	float phi = texcoord.x * PI;

	float sin_theta = sin(theta);
	float cos_theta = cos(theta);
	float sin_phi = sin(phi);
	float cos_phi = cos(phi);

	//Find where that point is in viewport space
	vec3 rayDir = vec3(sin_phi * cos_theta, sin_phi * sin_theta, cos_phi);
	vec3 rayDirView = worldToView(rayDir);
	vec2 screenCoords = viewToScreen(rayDirView);

	vec3 equiWrite;
	float dist;
	
	//If that point on equirectangular map is on screen, update environment map at that pos
	//Dont update on pixels very close to edge of the screen to avoid 'windshield wiper' artifact
	if(all(lessThan(screenCoords, vec2(1.0) - invRes*4)) && all(greaterThan(screenCoords, vec2(0.0) + invRes*4))
		&& rayDirView.z < 0.0) {
		equiWrite = max(textureLod(gcolor, screenCoords, 0.0).rgb, 0.0);
		float depth = textureLod(depthtex0, screenCoords, 0.0).r;
		dist = length(getDepthPoint(screenCoords, depth));

	} else {
		//Discard if not acutally visible
		equiWrite = max(textureLod(colortex7, texcoord, 0.0).rgb, 0.0);
		dist = textureLod(colortex7, texcoord, 0.0).a;
	}

	if(all(equal(texture2D(colortex7, texcoord).rgb, vec3(0.0)))) {
		equiWrite = sampleSky(rayDir, vec3(0,6372e3,0), normalize(viewToWorld(sunPosition)), normalize(viewToWorld(moonPosition)), false);
		equiWrite = applyFog(equiWrite, farDist, cameraPosition, viewToWorld(rayDir), 1.0);//Apply fog to sky sample
		dist = farDist;
	}

	/***** TAA *****/
	vec3 color;
	vec3 historyWrite;
	#ifdef TAA_ENABLED

	vec2 reprojectedCoord = reproject(vec3(texcoord, texture2D(depthtex0, texcoord).r));

	//Sample fragment colour and history colour
	color = texture2DLod(gcolor, texcoord, 0.0).rgb;
	vec3 history = texture2DLod(colortex6, reprojectedCoord, 0.0).rgb;

	//Clamp history in neighbour colours space
	vec3 topLeft = texture2DLod(gcolor, texcoord + neighbours[0]*invRes, 0.0).rgb;
	vec3 top = texture2DLod(gcolor, texcoord + neighbours[1]*invRes, 0.0).rgb;
	vec3 topRight = texture2DLod(gcolor, texcoord + neighbours[2]*invRes, 0.0).rgb;
	vec3 midLeft = texture2DLod(gcolor, texcoord + neighbours[3]*invRes, 0.0).rgb;
	vec3 midRight = texture2DLod(gcolor, texcoord + neighbours[4]*invRes, 0.0).rgb;
	vec3 botLeft = texture2DLod(gcolor, texcoord + neighbours[5]*invRes, 0.0).rgb;
	vec3 bot = texture2DLod(gcolor, texcoord + neighbours[6]*invRes, 0.0).rgb;
	vec3 botRight = texture2DLod(gcolor, texcoord + neighbours[7]*invRes, 0.0).rgb;

	vec3 minCol = min(min(min(min(min(min(min(min(topLeft, top), topRight), midLeft), color), midRight), botLeft), bot), botRight); 
	vec3 maxCol = max(max(max(max(max(max(max(max(topLeft, top), topRight), midLeft), color), midRight), botLeft), bot), botRight); 

	// vec3 minCol = min(min(min(min(top, midLeft), color), midRight), bot); 
	// vec3 maxCol = max(max(max(max(top, midLeft), color), midRight), bot); 

	vec3 clampedHist = clamp(history, minCol, maxCol);
	// float clampAmount = distance(clampedHist, history) / Luminance(history);

	//Weigh TAA
	vec2 velocity = (texcoord - reprojectedCoord)/invRes;
	float weight = clamp01(1.0 - sqrt(length(velocity))/2.0) * TAA_WEIGHT;

	color = mix(color, clampedHist, max(weight, 0.5));
	historyWrite = color;

	#else

	color = texture2D(gcolor, texcoord).rgb;
	historyWrite = color;

	#endif

	/**** EXPOSURE *****/

	#ifdef AUTO_EXPOSURE
	float exposure = calculateAverageLuminance();
	#else
	float exposure = 1.0;
	#endif

	/***** SUN ******/

	//Are ya winning Sun??
	float depth = texture2D(depthtex0, texcoord.st).r;
	vec3 depthDir = normalize(getDepthPoint(texcoord.st, depth));
	color += sampleSun(depthDir)*float(depth == 1.0) * (1.0-fog);

/* DRAWBUFFERS:067 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
	gl_FragData[1] = vec4(historyWrite, exposure); //colortex6
	gl_FragData[2] = vec4(equiWrite, dist); //panoramic depthmap
}