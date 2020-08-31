#define clamp01(x) clamp(x, 0.0, 1.0)

#define max0(x) max(x, 0.0)
#define max1(x) max(x, 1.0)
#define min0(x) min(x, 0.0)
#define min1(x) min(x, 1.0)

#define max3(x,y,z)       max(x,max(y,z))
#define max4(x,y,z,w)     max(x,max(y,max(z,w)))
#define max5(a,b,c,d,e)   max4(a,b,c,max(d,e))
#define max6(a,b,c,d,e,f) max5(a,b,c,d,max(e,f))

#define min3(a,b,c)       min(min(a,b),c)
#define min4(a,b,c,d)     min(min3(a,b,c),d)
#define min5(a,b,c,d,e)   min(min4(a,b,c,d),e)
#define min6(a,b,c,d,e,f) min(min5(a,b,c,d,e),f)

float maxof(vec2 x) { return max(x.x, x.y); }
float maxof(vec3 x) { return max(x.x, max(x.y, x.z)); }
float minof(vec2 x) { return min(x.x, x.y); }
float minof(vec3 x) { return min(x.x, min(x.y, x.z)); }

float linearstep(float e0, float e1, float x) {
	return clamp((x - e0) / (e1 - e0), 0.0, 1.0);
}

vec3 clampNormal(const vec3 n, const vec3 v) {
    float NoV = clamp(dot(n, -v), 0.0, 1.0);
    return normalize(NoV * v + n);
}

