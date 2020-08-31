

vec3 getDepthPoint(vec2 coord, float depth) {
    vec4 pos;
    pos.xy = coord;
    pos.z = depth;
    pos.w = 1.0;
    pos.xyz = pos.xyz * 2.0 - 1.0; //convert from the 0-1 range to the -1 to +1 range
    pos = gbufferProjectionInverse * pos;
    pos.xyz /= pos.w;
    
    return pos.xyz;
}

vec3 worldToView(vec3 worldPos) {

    vec4 pos = vec4(worldPos, 0.0);
    pos = gbufferModelView * pos;

    return pos.xyz;
}

vec3 viewToWorld(vec3 viewPos) {

    vec4 pos;
    pos.xyz = viewPos;
    pos.w = 0.0;
    pos = gbufferModelViewInverse * pos;

    return pos.xyz;
}

vec3 clipToView(vec3 clipPos, float isPosition) {
    vec4 pos;
    pos.xyz = clipPos;
    pos.w = isPosition;
    pos = gbufferProjectionInverse * pos;

    return pos.xyz;
}

vec3 rayDirection(vec2 coord) {
    vec4 dir;

    dir.xy = coord * 2.0 - 1.0;
    dir.z = 1.0;
    dir.w = 1.0;
    dir = gbufferProjectionInverse * dir;

    //now in unprojected space, but still rotated relative to your camera.
    dir.xyz /= dir.w; //black magic

    //now un-rotated
    return normalize(dir.xyz);
}

vec3 rayDirectionWorld(vec2 coord) {
    vec4 dir;

    dir.xy = coord * 2.0 - 1.0;
    dir.z = 1.0;
    dir.w = 1.0;
    dir = gbufferProjectionInverse * dir;

    //now in unprojected space, but still rotated relative to your camera.
    dir.xyz /= dir.w; //black magic

    //now un-rotated
    return viewToWorld(normalize(dir.xyz));
}

vec2 viewToScreen(vec3 positionCameraSpace) {
    vec4 positionNdcSpace = gbufferProjection * vec4(positionCameraSpace, 1.0);
    positionNdcSpace.xyz /= positionNdcSpace.w;
    
    return positionNdcSpace.xy * 0.5 + 0.5;
}
