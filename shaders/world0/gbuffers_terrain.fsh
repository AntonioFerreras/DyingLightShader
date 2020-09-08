#include "/lib/header.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex6;
uniform float viewWidth;
uniform float viewHeight;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying mat3 tbnMatrixWorld;

varying float isLeaves;
varying float isPlant;
varying float isTopPlant;
varying float isFence;

varying float isEmissive;

#include "/lib/math.glsl"
#include "/lib/view.glsl"
#include "/lib/encoding.glsl"

vec3 calculateSpecularMaps(vec2 coord) {
    vec3 specular = texture2D(specular, coord).rgb;
    return specular;
}

vec4 getTangentNormals(vec2 coord) {
    vec4 normal = texture2D(normals,  coord) * 2.0 - 1.0;
    return vec4(normal.x, normal.y, normal.z, normal.w);
}

void main() {
	vec4 color = texture2D(texture, texcoord);
    color.rgba *= glcolor.rgba;
    
	//color *= texture2D(lightmap, lmcoord);

	//Normal mapping
    vec4 normalTex = getTangentNormals(texcoord.st);
    vec3 normal = normalize(normalTex.rgb * tbnMatrixWorld);
    vec3 flatNormal = normalize(vec3(0,0,1) * tbnMatrixWorld);
    float encodedNormal = encodeNormal3x16(normal); 
    float encodedFlatNormal = encodeNormal3x16(flatNormal); 

	float depth = normalTex.w;

    // normal = worldToView(normal, 0.0);

    //Specular mapping
    vec3 specularity = calculateSpecularMaps(texcoord.st);

    //Subsurface
    float subsurface = 0.0;
    subsurface = sign(isLeaves)*1.0 + sign(isPlant)*1.6 + sign(isTopPlant)*1.59 + sign(isFence)*0.1;

    vec2 uv = gl_FragCoord.xy/vec2(viewWidth, viewHeight);

    float emissiveAndSubsurface = encode2x16(vec2(sign(isEmissive), subsurface*0.5));
    
/* DRAWBUFFERS:0134 */
	gl_FragData[0] = vec4(color.rgb, color.a); //gcolor
	gl_FragData[1] = vec4(texture2D(colortex1, uv).rgb, encodedNormal); //colortex1
	gl_FragData[2] = vec4(specularity.rg, emissiveAndSubsurface, encodedFlatNormal); //colortex3
	gl_FragData[3] = vec4(lmcoord, 0.0, 0.0); //colortex4
}