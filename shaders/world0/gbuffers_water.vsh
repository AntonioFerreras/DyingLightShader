#include "/lib/header.glsl"

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;    
uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying float isWater;
varying mat3 tbnMatrixWorld;
attribute vec4 at_tangent;

attribute vec3 mc_Entity;

#include "/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/survivor_sense.glsl"
#include "/lib/survivor_sense_vert.glsl"
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

	applySurvivorSenseVertexPulse(position);

    gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	isWater = float(int(mc_Entity.x) == 10009);

	#ifdef TAA_ENABLED
    gl_Position.xy += jitter(2.0) * gl_Position.w;
    #endif
	
	tbnMatrixWorld = calculateTBN();
}