#include "/lib/header.glsl"

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D gnormal;
uniform sampler2D noisetex;
uniform sampler2D colortex2;
uniform vec3 cameraPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform sampler2D colortex4;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;    
uniform vec3 sunPosition; 
uniform float sunrise;
uniform float day;
uniform float night;
uniform float morning;
uniform float wetness;
uniform float fog;
uniform float frameTimeCounter;
uniform float farDist;
uniform float viewHeight, viewWidth;

varying vec2 texcoord;

#include "/lib/view.glsl"
#include "/lib/utility/common_functions.glsl"
#include "/lib/math.glsl"
#include "/lib/survivor_sense.glsl"
#include "/lib/encoding.glsl"
#include "/lib/sun.glsl"
#include "/lib/shadows.glsl"
#include "/lib/volumetrics.glsl"

void main() {
	vec3 color = texture2D(gcolor, texcoord).rgb;
	float depth = texture2D(depthtex0, texcoord).r;

    vec3 depthViewPoint = getDepthPoint(texcoord, depth);
    vec3 depthWorldPoint = viewToWorld(depthViewPoint);

   //Apply survivor sense
   #ifdef SURVIVOR_SENSE_ENABLED
   if(depth < 0.9999999999) {
        float groundDepthDist = length(depthWorldPoint.xz);

        float survPulse = survivorSensePulseAmount(groundDepthDist);

        color = mix(color, vec3(SURVIVOR_SENSE_R, SURVIVOR_SENSE_G, SURVIVOR_SENSE_B), survPulse*survivorSenseFalloff()*0.4*SURVIVOR_SENSE_INTENSITY);
   }
   #endif

   //Apply translucents
   vec3 transMask = decode3x16(texture2D(colortex4, texcoord).b);
	
   if(!all(equal(transMask, vec3(0.0)))) {
	color *= transMask;
   }

   //Apply volumetrics
   float dither = fract(texture2D(noisetex, mod(gl_FragCoord.xy, 512.0)/512.0).r + frameTimeCounter*4.12348543);
   float incomingVolumetricRadiance = 1.0;
   if(fog > 0.001) {
      incomingVolumetricRadiance = volumetricMarch(vec3(0.0), normalize(depthWorldPoint), depthWorldPoint, dither);
   }
   
   color = applyFog(color, length(depthWorldPoint), cameraPosition, normalize(depthWorldPoint), incomingVolumetricRadiance);

/* DRAWBUFFERS:02 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
   gl_FragData[1] = vec4(texture2D(colortex2, texcoord).rgb, incomingVolumetricRadiance);
}