const vec2 neighbours[8] = vec2[8] ( vec2(-1.0, 1.0),  vec2(0.0, 1.0),  vec2(1.0, 1.0),
                                     vec2(-1.0,  0.0),  /* center */    vec2(1.0, 0.0), 
                                     vec2(-1.0, -1.0), vec2(0.0, -1.0), vec2(1.0, -1.0) );

vec2 reproject(vec3 coord) {
    vec4 pos = vec4(coord, 1.0) * 2.0 - 1.0;
    pos = gbufferProjectionInverse * pos;
    pos = pos / pos.w;
    pos = gbufferModelViewInverse * pos;
    pos += vec4(cameraPosition - previousCameraPosition, 0.0);
    pos = gbufferPreviousModelView * pos;
    pos = gbufferPreviousProjection * pos;
    return (pos.xy/pos.w) * 0.5 + 0.5;
}