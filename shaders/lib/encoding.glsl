float encode3x16(vec3 a){
    vec3 m = vec3(31,63,31);
    a = clamp(a,0.0,1.0);
    ivec3 b = ivec3(a*m);
    return float( b.r|(b.g<<5)|(b.b<<11) ) / 65535.;
}

vec3 decode3x16(float a){
    int bf = int(a*65535.);
    return vec3(bf%32, (bf>>5)%64, bf>>11) / vec3(31,63,31);
}
