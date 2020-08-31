#include "/lib/header.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

void main() {
	vec4 color = vec4(vec3(0.9), texture2D(texture, texcoord).a) * glcolor;
	color *= texture2D(lightmap, lmcoord);

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}