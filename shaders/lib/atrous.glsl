vec3 atrous(vec2 coord, int pass) {
    int kernel = 1 << pass;
	float weights = 0.0;

    float origDepth = textureLod(depthtex0, coord, 0).r;
    float origDist = getDepthPoint(coord, origDepth).z;
	vec3 origNormal = decodeNormal3x16(textureLod(colortex1, coord, 0).a);

    vec3 col = vec3(0);

	for (int i = -kernel; i <= kernel; i += 1 << pass) {
		for (int j = -kernel; j <= kernel; j += 1 << pass) {
			ivec2 icoord = ivec2(gl_FragCoord.xy) + ivec2(vec2(i,j));
			
			vec3 normal = decodeNormal3x16(texelFetch(colortex1, icoord, 0).a);
			float depth = texelFetch(depthtex0, icoord, 0).r;
            float depthDist = getDepthPoint(vec2(icoord)*vec2(viewWidth, viewHeight), depth).z;
			vec3 color = texelFetch(colortex1, icoord, 0).rgb;
			
			float weight = 1.0;
            weight *= pow(length(16 - vec2(i,j)) / 16.0, 2.0);
			// weight *= clamp01(dot(origNormal, normal)*24-23);
			weight *= pow128(max0(dot(origNormal, normal)));
			// weight *= clamp01(1.0-abs(origDepth - depth));

			weight *= clamp01(1.0-abs(origDist - depthDist));

            if(depth == 1.0) {
                weight = 0.0;
            }
			
			col += color * weight;
			weights += weight;
		}
	}
    col = col / weights;

    return col;
}