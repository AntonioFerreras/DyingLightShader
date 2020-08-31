#include "/lib/header.glsl"

#extension GL_ARB_shader_texture_lod : enable

/*
const bool colortex7MipmapEnabled = true;
*/

varying vec4 texcoord;

uniform sampler2D gcolor;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex4;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform float frameTimeCounter;
uniform float wetness;
uniform float day;
uniform ivec2 eyeBrightness;
uniform vec2 resolution;
uniform vec3 upPosition;

#include "/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/utility/common_functions.glsl"
#include "/lib/utility/constants.glsl"
#include "/lib/aces/ACES.glsl"
#include "/lib/encoding.glsl"
#include "/lib/raindrops.glsl"


/*
const int colortex0Format = R11F_G11F_B10F;
const int colortex1Format = RGBA16F;
const int colortex2Format = RGBA16_SNORM;
const int colortex4Format = RGBA16_SNORM;
const int colortex3Format = RGBA16F;
const int colortex5Format = RGBA16F;
const int colortex6Format = RGBA16F;
const int colortex7Format = RGBA16F;
const float sunPathRotation = -40.0f; 

const float wetnessHalflife = 80.0;
const float drynessHalflife = 80.0;
*/

#ifdef RTAO_ENABLED
/*
const float ambientOcclusionLevel = 0.0f; 
*/
#endif

void ditherScreen(inout vec3 color) {
    vec3 lestynRGB = vec3(dot(vec2(171.0, 231.0), gl_FragCoord.xy));
         lestynRGB = fract(lestynRGB.rgb / vec3(103.0, 71.0, 97.0));

    color += lestynRGB.rgb / 255.0;
}


void main() {
    vec2 uv = texcoord.st;
    vec3 color = texture2D(gcolor, uv).rgb;

    ColorCorrection m;
	m.lum = vec3(0.2125, 0.7154, 0.0721);
	m.saturation = 0.95 + SAT_MOD;
	m.vibrance = VIB_MOD;
	m.contrast = 1.0 - CONT_MOD;
	m.contrastMidpoint = CONT_MIDPOINT;

	m.gain = vec3(1.0, 1.0, 1.0) + GAIN_MOD; //Tint Adjustment
	m.lift = vec3(0.0, 0.0, 0.0) + LIFT_MOD * 0.01; //Tint Adjustment
	m.InvGamma = vec3(1.0, 1.0, 1.0);

    //Do rain drops on screen
    #ifdef LENSE_RAINDROPS
    if(wetness > 0.01) {
        float dropAmount = clamp(dot(normalize(upPosition), vec3(0, 0, -1)), 0.12, 0.4);

        float coverAmount = pow64(float(eyeBrightness.y)/240.0);
        color = mix(color, doRainDrops(gl_FragCoord.xy, frameTimeCounter, gcolor), pow(wetness, 3.0)*dropAmount*coverAmount);
    }
    #endif

    #ifdef AUTO_EXPOSURE
    float exposureWeight = day;
    color *= (1.0-exposureWeight) + exposureWeight/texture2D(colortex6, texcoord.st).a;
    #else
    color *= MANUAL_EXPOSURE_AMOUNT;
    #endif
    
    color = FilmToneMap(color);

    color = WhiteBalance(color);
	color = Vibrance(color, m);
	color = Saturation(color, m);
    color = Contrast(color, m);
    color = LiftGammaGain(color, m);


    color = linearToSrgb(color);

    color = color * sRGB_2_AP1;

    color = clamp(color, 0.0, 1.0);

    // ditherScreen(color);

    // color = textureLod(colortex7, texcoord.st, 7.0).rgb;


    gl_FragColor = vec4(color.rgb, 1.0f);

}