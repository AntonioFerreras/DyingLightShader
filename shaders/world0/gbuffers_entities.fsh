#include "/lib/header.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform vec4 entityColor;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D depthtex0;
uniform float viewWidth;
uniform float viewHeight;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying float highlight;
varying mat3 tbnMatrixWorld;

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
	
	//Normal mapping
    vec4 normalTex = getTangentNormals(texcoord.st);
    vec3 normal = normalize(normalTex.rgb * tbnMatrixWorld);
	vec3 flatNormal = normalize(vec3(0,0,1) * tbnMatrixWorld);
    float encodedFlatNormal = encode3x16(flatNormal * 0.5 + 0.5); 
	float depth = normalTex.w;

    normal = worldToView(normal);

    //Specular mapping
    vec3 specularity = calculateSpecularMaps(texcoord.st);

	vec2 lm = lmcoord;

	if(highlight == 0.0) {
		color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
		//color *= texture2D(lightmap, lmcoord);
	} else {
		float alpha = 1.0 - highlight;
		color.rgb = mix(color.rgb, entityColor.rgb, alpha);
		float brightness = mix((color.r + color.g + color.b)/3.0, 1.0, 0.6);
		//float thickness = 0.1;
		//float outline = clamp(float(mod(gl_FragCoord.x, 40.0) < 15.0), 0.5, 0.7);
		//color.rgb = mix(color.rgb, vec3(255., 132., 31.)/255., outline * highlight);
		vec3 baseColour = vec3(0.03);
		vec3 emissionColour = vec3(255, 111, 0)/255.;

		vec3 dirToCamera = -rayDirection(gl_FragCoord.xy/vec2(viewWidth, viewHeight));
		float facing = dot(normal, dirToCamera);
		color.rgb = mix(emissionColour, baseColour, smoothstep(0.0, 1.0, facing))*brightness*highlight*1.3;

		normal = vec3(999.0);
	}

	normal = viewToWorld(normal);

/* DRAWBUFFERS:0234 */
	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(normal* 0.5 + 0.5, encodedFlatNormal); //gnormal
	gl_FragData[2] = vec4(specularity.rg, 0.0, 0.5); //colortex3
	gl_FragData[3] = vec4(lm, 0.0, 0.0); //colortex4
}