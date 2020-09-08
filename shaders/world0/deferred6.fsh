#include "/lib/header.glsl"

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D colortex1;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition; 
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition; 
uniform vec3 upPosition;
uniform float viewHeight;
uniform float viewWidth;
uniform float sunset; 
uniform float night; 

varying vec2 texcoord;

#include "/settings.glsl"
#include "/lib/utility/common_functions.glsl"
#include "/lib/utility/constants.glsl"
#include "/lib/resScales.glsl"
#include "/lib/view.glsl"
#include "/lib/encoding.glsl"
#include "/lib/atrous.glsl"

/******************  FILTER GI PASS 4  ******************/


void main() {

	vec3 color = atrous(texcoord, 3).rgb;
	
	


/* DRAWBUFFERS:1 */
	gl_FragData[0] = vec4(color, texture2D(colortex1, texcoord).a); //colortex1 (ao gi upscaled)
}