#include "/lib/header.glsl"

#extension GL_ARB_shader_texture_lod : enable



uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D colortex6;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform float viewHeight;
uniform float viewWidth; 
uniform float day; 
uniform float sunrise; 
uniform vec2 resolution;

varying vec2 texcoord;

const bool colortex6Clear = false;

vec2 invRes = 1.0/resolution;

#include "/lib/utility/common_functions.glsl"
#include "/lib/math.glsl"
#include "/lib/view.glsl"
#include "/lib/sun.glsl"
#include "/lib/taa_functions.glsl"

/******************  SUN & TAA & EXPOSURE ******************/

//From Raspberry by Rutherin <3
float calculateAverageLuminance() {
    const float maxLumaRange  = 1.5;
    const float minLumaRange  = 0.01;
    const float exposureDecay = 0.01*EXPOSURE_SPEED;

    float avglod = int(exp2(min(viewWidth, viewHeight))) - 1;

	float averagePrevious = texture2DLod(colortex6, vec2(0.0), 0.0).a;
    float averageCurrent  = clamp(sqrt(dot(texture2DLod(gcolor, vec2(0.5), avglod).rgb, vec3(0.2125, 0.7154, 0.0721))), minLumaRange, maxLumaRange)*2.5;

    return mix(averagePrevious, averageCurrent, exposureDecay);
}


void main() {
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

	color = mix(color, clampedHist, weight);
	historyWrite = color;

	#else

	color = texture2D(gcolor, texcoord).rgb;
	historyWrite = color;

	#endif

	#ifdef AUTO_EXPOSURE
	float exposure = calculateAverageLuminance();
	#else
	float exposure = 1.0;
	#endif

	//Are ya winning Sun??
	float depth = texture2D(depthtex0, texcoord.st).r;
	vec3 depthDir = normalize(getDepthPoint(texcoord.st, depth));
	color += sampleSun(depthDir)*float(depth == 1.0);

/* DRAWBUFFERS:06 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
	gl_FragData[1] = vec4(historyWrite, exposure); //colortex6
}