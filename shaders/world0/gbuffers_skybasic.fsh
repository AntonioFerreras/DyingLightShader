#include "/lib/header.glsl"

uniform float viewHeight;
uniform float viewWidth;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;

varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

void main() {
	discard;
}