#include "/lib/header.glsl"

#include "/lib/utility/common_functions.glsl"
#include "/lib/encoding.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform sampler2D normals;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform float viewWidth, viewHeight;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying float isWater;
varying mat3 tbnMatrixWorld;

#include "/lib/math.glsl"
#include "/lib/view.glsl"


const bool colortex4Clear = false;

void main() {
	vec4 color = texture2D(texture, texcoord);
	// vec3 depthViewPoint = getDepthPoint(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	// vec3 depthWorldPoint = viewToWorld(depthViewPoint, 1.0);
	// color *= texture2D(lightmap, lmcoord);
	color.rgb *= 1.0-color.a;
	color.rgb *= 1.5;

	//If water
	if(isWater > 0.0) {
		color.rgb = vec3(0);	
	}
	float waterOrNah = isWater > 0.0 ? 0.5 : 0.2;

	float encodedColor = encode3x16(color.rgb);

	//Normals stuff
	vec3 normal = normalize(vec3(0,0,1) * tbnMatrixWorld);

	if(normal.y > 0.9 && waterOrNah > 0.2) {
		waterOrNah = 1.0;
	}

/* DRAWBUFFERS:4 */
	gl_FragData[0] = vec4(lmcoord, encodedColor, waterOrNah); //colortex4
}