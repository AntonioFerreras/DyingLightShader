#include "/lib/header.glsl"

uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D depthtex0;
uniform sampler2D colortex7;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;    
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
uniform float far;    

varying vec2 texcoord;


/******************  WRITE TO EQUIRECTANGULAR BUFFER  ******************/

void main() {
	
	vec3 color = texture2D(gcolor, texcoord).rgb;

	

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}