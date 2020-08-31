#include "/lib/header.glsl"


#extension GL_ARB_shader_texture_lod : enable

/*
const bool colortex0MipmapEnabled = true;
const bool colortex7MipmapEnabled = true;
const int noiseTextureResolution = 512;
*/

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

const bool colortex7Clear = false;

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

/******************  WRITE TO EQUIRECTANGULAR BUFFER  ******************/

void main() {

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

	vec3 color;
	float dist;
	vec2 pixelSize = vec2(1.0)/vec2(viewWidth, viewHeight);
	
	//If that point on equirectangular map is on screen, update environment map at that pos
	//Dont update on pixels very close to edge of the screen to avoid 'windshield wiper' artifact
	if(all(lessThan(screenCoords, vec2(1.0) - pixelSize*4)) && all(greaterThan(screenCoords, vec2(0.0) + pixelSize*4))
		&& rayDirView.z < 0.0) {
		color = textureLod(gcolor, screenCoords, 0.0).rgb;
		float depth = textureLod(depthtex0, screenCoords, 0.0).r;
		dist = length(getDepthPoint(screenCoords, depth));

	} else {
		//Discard if not acutally visible
		color = textureLod(colortex7, texcoord, 0.0).rgb;
		dist = textureLod(colortex7, texcoord, 0.0).a;
	}

	if(all(equal(texture2D(colortex7, texcoord).rgb, vec3(0.0)))) {
		color = sampleSky(rayDir, vec3(0,6372e3,0), normalize(viewToWorld(sunPosition)), normalize(viewToWorld(moonPosition)), false);
		color = applyFog(color, far, cameraPosition, viewToWorld(rayDir), 1.0);//Apply fog to sky sample
		dist = far;
	}
	

/* DRAWBUFFERS:7 */
	gl_FragData[0] = vec4(color, dist); //panoramic depthmap
}