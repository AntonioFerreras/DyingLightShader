#version 120  

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;    
uniform vec3 cameraPosition;
uniform float frameTimeCounter; 
uniform float wetness; 

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

#include "/lib/shadow_distort.glsl"
#include "/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/survivor_sense.glsl"
#include "/lib/survivor_sense_vert.glsl"
#include "/lib/waving_plants.glsl"

void main() {
	if(mc_Entity.x == 10009) {
		gl_Position = vec4(10.0);
	} else {
		vec4 position = shadowModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
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

		applySurvivorSenseVertexPulseShadow(position);


		gl_Position = gl_ProjectionMatrix * shadowModelView * mix(position, positionRain, pow(wetness, 3.0));
		gl_Position.xyz = distort(gl_Position.xyz);
		
	}
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;


}