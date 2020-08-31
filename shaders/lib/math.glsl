// vec3 constructNormal(float depth, vec2 texcoords, sampler2D depthtex) {
//     const vec2 offset1 = vec2(0.0,0.0001);
//     const vec2 offset2 = vec2(0.0001,0.0);
  
//     float depth1 = texture2D(depthtex, texcoords + offset1).r;
//     float depth2 = texture2D(depthtex, texcoords + offset2).r;
  
//     vec3 p1 = vec3(offset1, depth1 - depth);
//     vec3 p2 = vec3(offset2, depth2 - depth);
  
//     vec3 normal = cross(p1, p2);
//     normal.z = -normal.z;
  
//     normal = normalize(normal);
//     return vec3(normal.x, normal.z, normal.y);
// }


float map(float n, float start1, float stop1, float start2, float stop2) {
    return ((n - start1) / (stop1 - start1)) * (stop2 - start2) + start2;
}

vec3 blackbody(float t) {
    // http://en.wikipedia.org/wiki/Planckian_locus

    vec4 vx = vec4(-0.2661239e9,-0.2343580e6,0.8776956e3,0.179910);
    vec4 vy = vec4(-1.1063814,-1.34811020,2.18555832,-0.20219683);
    float it = 1./t;
    float it2= it*it;
    float x = dot(vx,vec4(it*it2,it2,it,1.));
    float x2 = x*x;
    float y = dot(vy,vec4(x*x2,x2,x,1.));
    float z = 1. - x - y;

    // http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
    mat3 xyzToSrgb = mat3(
    3.2404542,-1.5371385,-0.4985314,
    -0.9692660, 1.8760108, 0.0415560,
    0.0556434,-0.2040259, 1.0572252
    );

    vec3 srgb = vec3(x/y,1.,z/y) * xyzToSrgb;
    return max(srgb,0.);
}