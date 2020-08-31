#include "/lib/header.glsl"

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

void main() {
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	
	position.xz += position.y*0.2;//Make it slanted 

    gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
}