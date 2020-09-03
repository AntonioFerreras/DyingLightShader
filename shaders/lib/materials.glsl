vec3 cosWeightedRandomHemisphereDirection(vec3 n, inout float seed) {
    vec2 r = hash2(seed);
    vec3  uu = normalize(cross(n, vec3(0.0, 1.0, 1.0)));
    vec3  vv = cross(uu, n);

    float ra = sqrt(r.y);
    float rx = ra*cos(6.2831*r.x);
    float ry = ra*sin(6.2831*r.x);
    float rz = sqrt(1.0-r.y);
    vec3  rr = vec3(rx*uu + ry*vv + rz*n);

    return normalize(rr);
}

//BRDF
vec3 ggx(vec3 n, vec3 v, vec3 l, vec3 specularity, vec3 albedo) {
    float alpha = specularity.x*specularity.x;
    float alpha2 = alpha * alpha;

    float dotNL = clamp(dot(n, l), 0., 1.);
    float dotNV = clamp(dot(n, v), 0., 1.);

    vec3 h = normalize(v + l);
    float dotNH = clamp(dot(n, h), 0., 1.);
    float dotLH = clamp(dot(l, h), 0., 1.);

    // GGX microfacet distribution function
    float den = (alpha2 - 1.0) * dotNH * dotNH + 1.0;
    float D = alpha2 / (PI * den * den);

    // Fresnel with Schlick approximation
    vec3 F0 = specularity.y*albedo;

    vec3 F = F0 + (1.0 - F0) * pow(1. - dotLH, 5.0);

    // Smith joint masking-shadowing function
    float k = .5 * alpha;
    float G = 1.0 / ((dotNL * (1.0 - k) + k) * (dotNV * (1.0 - k) + k));

    //pdf = max(D * dotNH /(4.0*dotLH), 0.00001);
    return max(D * F * G, 0.0001);
}

//Sample ggx direction & PDF
vec3 ggx_sample(vec3 n, vec3 v, float roughness, out float pdf, inout float seed) {

    float alpha = roughness*roughness;
    float alpha2 = alpha * alpha;

    float epsilon = clamp(mix(hash1(seed), 0.0, 0.6), 0.001, 1.);
    float cosTheta2 = (1. - epsilon) / (epsilon * (alpha2 - 1.) + 1.);
    float cosTheta = sqrt(cosTheta2);
    float sinTheta = sqrt(1. - cosTheta2);

    float phi = 2. * PI * hash1(seed);

    // Spherical to cartesian
    vec3 t = normalize(cross(n.yzx, n));
    vec3 b = cross(n, t);

    vec3 microNormal = (t * cos(phi) + b * sin(phi)) * sinTheta + n * cosTheta;

    vec3 l = reflect(-v, microNormal);

    // Sample weight
    float den = (alpha2 - 1.) * cosTheta2 + 1.;
    float D = alpha2 / (PI * den * den);
    float p = D * cosTheta / (4. * dot(microNormal, v));
    pdf = (.5 / PI) / (p + 1e-6);
    pdf = 1.0/pdf;

//    if (dot(l, n) < 0.)
//        weight = 0.000000;

    return l;
}

vec3 parseSpecular(vec3 data) {
    float roughness = max(0.089, 1 - data.x);
    float f0 = clamp(data.y, 0.02, 1.0);
    float subsurface = 0;
    // return vec3(1.0, 1.0, 0.0);
    return vec3(roughness, f0, subsurface);
}

float schlick(vec3 incident, vec3 normal, vec3 specularity) {
    float F0 = specularity.y;
    float cosTheta = clamp(dot(-incident, normal), 0.0, 1.0);

    return clamp(F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0), 0.0, 1.0);
}

vec3 schlick3(vec3 incident, vec3 normal, vec3 F0) {
    float cosTheta = clamp(dot(-incident, normal), 0.0, 1.0);

    return clamp(F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0), 0.0, 1.0);
}

bool isMetal(float f0) {
   return (f0 > 220.0/255.0);
}