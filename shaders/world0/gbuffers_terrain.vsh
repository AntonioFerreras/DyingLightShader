#include "/lib/header.glsl"

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;    
uniform vec3 cameraPosition;
uniform float frameTimeCounter; 
uniform float wetness;
uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;

attribute vec3 mc_Entity;
attribute vec4 at_tangent;
attribute vec4 mc_midTexCoord;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying mat3 tbnMatrixWorld;

varying float isLeaves;
varying float isPlant;
varying float isTopPlant;
varying float isFence;

varying float isEmissive;

#include "/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/survivor_sense.glsl"
#include "/lib/survivor_sense_vert.glsl"
#include "/lib/waving_plants.glsl"
#include "/lib/taa_shit.glsl"

mat3 calculateTBN() {
	vec3 normal   = normalize(gl_NormalMatrix * gl_Normal);
	vec3 tangent  = normalize(gl_NormalMatrix * (at_tangent.xyz / at_tangent.w));

         normal   = mat3(gbufferModelViewInverse) * normal;
         tangent  = mat3(gbufferModelViewInverse) * tangent;

	vec3 binormal = normalize(cross(tangent, normal));

         return transpose(mat3(tangent, binormal, normal));
}

void main() {

	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	vec4 positionRain = position;
	position.xyz += cameraPosition;
	positionRain.xyz += cameraPosition;

    if(mc_Entity.x == 10013) {
        position.xyz = waveLeaves(position.xyz);
		positionRain.xyz = waveLeavesRain(positionRain.xyz);
    } else if((mc_Entity.x == 10002 || mc_Entity.x == 10003 || mc_Entity.x == 10005) && gl_MultiTexCoord0.t < mc_midTexCoord.t) {
        //Grass and flowers, only for vertices on top
        position.xyz = wavePlants(position.xyz);
		positionRain.xyz = wavePlantsRain(positionRain.xyz);
    } else if(mc_Entity.x == 10004) {
        position.xyz = wavePlants(position.xyz);        
		positionRain.xyz = wavePlantsRain(positionRain.xyz);
    }

	position.xyz -= cameraPosition;
	positionRain.xyz -= cameraPosition;

	applySurvivorSenseVertexPulse(position);

    gl_Position = gl_ProjectionMatrix * gbufferModelView * mix(position, positionRain, pow(wetness, 3.0));

	
	#ifdef TAA_ENABLED
    gl_Position.xy += jitter(2.0) * gl_Position.w;
    #endif

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	tbnMatrixWorld = calculateTBN();

	

	// Block type
	int entity = int(mc_Entity.x);
	isLeaves = float(entity == 10013);
	isPlant = float(entity == 10002 || entity == 10003 || entity == 10005 || entity == 10006);
	isTopPlant = float(entity == 10004);
	isFence = float(entity == 10016 || entity == 10017);
	isEmissive = float(entity == 10019 || entity == 10007);
}