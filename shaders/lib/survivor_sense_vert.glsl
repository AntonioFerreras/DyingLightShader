

void applySurvivorSenseVertexPulse(inout vec4 pos) {
	//Change vertex to world space
    // vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
    #ifdef SURVIVOR_SENSE_ENABLED
    //Do curvature
    float dist = length(pos.xz);
    float offset = getSurvivorSenseVertOffset(dist);
    pos.y -= offset;
    #endif
    //Change back to clip space
    // pos = gl_ProjectionMatrix * gbufferModelView * position;
}
void applySurvivorSenseVertexPulseShadow(inout vec4 pos) {
	// vec4 position = shadowModelViewInverse * gl_ModelViewMatrix * gl_Vertex;


    #ifdef SURVIVOR_SENSE_ENABLED
    //Do curvature
    float dist = length(pos.xz);
    float offset = getSurvivorSenseVertOffset(dist);
    pos.y -= offset;
    #endif

    //Change back to clip space
    // pos = gl_ProjectionMatrix * shadowModelView * position;
}