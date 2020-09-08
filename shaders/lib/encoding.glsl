float encode2x16(vec2 a){
    ivec2 bf = ivec2(a*255.);
    return float( bf.x|(bf.y<<8) ) / 65535.;
}

vec2 decode2x16(float a){
    int bf = int(a*65535.);
    return vec2(bf%256, bf>>8) / 255.;
}

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

float encodeNormal3x16(vec3 a){
    vec3 b  = abs(a);
    vec2 p  = a.xy / (b.x + b.y + b.z);
    vec2 sp = vec2(greaterThanEqual(p, vec2(0.0))) * 2.0 - 1.0;

    vec2 encoded = a.z <= 0.0 ? (1.0 - abs(p.yx)) * sp : p;

    encoded = encoded * 0.5 + 0.5;

    return encode2x16(encoded);
}

vec3 decodeNormal3x16(float encoded){
    vec2 a = decode2x16(encoded);

    a = a * 2.0 - 1.0;
    vec2 b = abs(a);
    float z = 1.0 - b.x - b.y;
    vec2 sa = vec2(greaterThanEqual(a, vec2(0.0))) * 2.0 - 1.0;

    vec3 decoded = normalize(vec3(
        z < 0.0 ? (1.0 - b.yx) * sa : a.xy,
        z
    ));

    return decoded;
}