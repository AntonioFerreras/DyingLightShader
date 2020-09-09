#include "/lib/header.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying mat3 tbnMatrixWorld;

#include "/lib/math.glsl"
#include "/lib/view.glsl"

vec3 calculateSpecularMaps(vec2 coord) {
    vec3 specular = texture2D(specular, coord).rgb;
    return specular;
}

vec4 getTangentNormals(vec2 coord) {
    vec4 normal = texture2D(normals,  coord) * 2.0 - 1.0;
    return vec4(normal.x, normal.y, normal.z, normal.w);
}

void main() {
    discard;
	vec4 color = texture2D(texture, texcoord) * glcolor;
	//color *= texture2D(lightmap, lmcoord);

	//Normal mapping
    vec4 normalTex = getTangentNormals(texcoord.st);
    vec3 normal = normalize(normalTex.rgb * tbnMatrixWorld);
	float depth = normalTex.w;

    // normal = worldToView(normal, 0.0);

    //Specular mapping
    vec3 specularity = calculateSpecularMaps(texcoord.st);

/* DRAWBUFFERS:0 */ //234
	gl_FragData[0] = vec4(0.0); //gcolor
	// gl_FragData[1] = vec4(normal* 0.5 + 0.5, 1.0); //gnormal
    // gl_FragData[2] = vec4(specularity, 1.0); //gnormal
	// gl_FragData[3] = vec4(lmcoord, 0.0, 0.0); //colortex4
}