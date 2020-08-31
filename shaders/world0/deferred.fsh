#include "/lib/header.glsl"

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
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
#include "/lib/sky.glsl"

void main() {
	vec3 color = vec3(0.0);

	if(all(lessThan(texcoord, vec2(atmosResScale)))) {
		vec3 rdV = rayDirection(texcoord*atmosInvResScale);
		vec3 rdW = rayDirectionWorld(texcoord*atmosInvResScale);
		color = sampleSky(rdW, vec3(0,6372e3,0), normalize(viewToWorld(sunPosition)), normalize(viewToWorld(moonPosition)), false);

		// vec3 sunAngle = viewToWorld(normalize(sunPosition), 0.0);
		// sunAngle.y = -0.4;
		// sunAngle = worldToView(sunAngle, 0.0);

		// color = mix(color, pow(vec3(253, 212, 125)/255.0, vec3(5.2)), clamp(pow64(min(1.0 + rdW.y, 1.0))*pow(1.0-night, 3)*sunset*pow(dot(rdV, sunAngle), 3.0), 0.0, 0.99));
	} else if(all(greaterThan(texcoord, vec2(0.99)))) {
		color = sampleSky(vec3(0.0, 1.0, 0.0), vec3(0,6372e3,0), normalize(viewToWorld(sunPosition)), normalize(viewToWorld(moonPosition)), false);
	}
	


/* DRAWBUFFERS:5 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}