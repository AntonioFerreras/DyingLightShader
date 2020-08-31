float log10(float x){
    return log(x) / log(10.0);
}
vec2 log10(vec2 x){
    return log(x) / log(10.0);
}
vec3 log10(vec3 x){
    return log(x) / log(10.0);
}

float max3(float x, float y, float z){
    return max(max(x,y),z);
}
float min3(float x, float y, float z){
    return min(min(x,y),z);
}
float max0(float x){
    return max(x, 0);
}
float clamp01(float x){
    return clamp(x, 0., 1.);
}
vec2 clamp01(vec2 x){
    return clamp(x, 0., 1.);
}
vec3 clamp01(vec3 x){
    return clamp(x, 0., 1.);
}

vec3 toSRGB(vec3 color) {
	return mix(color * 12.92, 1.055 * pow(color, vec3(1.0 / 2.4)) - 0.055, vec3(greaterThan(color, vec3(0.0031308))));
}

vec3 toLinear(vec3 color) {
	return mix(color / 12.92, pow((color + 0.055) / 1.055, vec3(2.4)), vec3(greaterThan(color, vec3(0.04045))));
}

float Luminance(in vec3 color)
{
	return dot(color.rgb, vec3(0.2125f, 0.7154f, 0.0721f));
}

#define pow2(x) (x * x)
#define pow3(x) (pow2(x) * x)
#define pow4(x) (pow2(x) * pow2(x))
#define pow16(x) (pow4(x) * pow4(x))
#define pow32(x) (pow16(x) * pow16(x))
#define pow64(x) (pow32(x) * pow32(x))
#define pow128(x) (pow64(x) * pow64(x))
#define pow256(x) (pow128(x) * pow128(x))
#define pow512(x) (pow256(x) * pow256(x))
#define pow2048(x) (pow512(x) * pow512(x) * pow512(x) * pow512(x))
#define pow4096(x) (pow2048(x) * pow2048(x))
#define pow8192(x) (pow4096(x) * pow4096(x))

// Dithering functions
float bayer2(vec2 a){
    a = floor(a);
    return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

#define bayer4(a)   (bayer2(  0.5 * (a)) * 0.25 + bayer2(a))
#define bayer8(a)   (bayer4(  0.5 * (a)) * 0.25 + bayer2(a))
#define bayer16(a)  (bayer8(  0.5 * (a)) * 0.25 + bayer2(a))
#define bayer32(a)  (bayer16( 0.5 * (a)) * 0.25 + bayer2(a))
#define bayer64(a)  (bayer32( 0.5 * (a)) * 0.25 + bayer2(a))
#define bayer128(a) (bayer64( 0.5 * (a)) * 0.25 + bayer2(a))
#define bayer256(a) (bayer128(0.5 * (a)) * 0.25 + bayer2(a))

//RANDOM NUM STUFF

const float seedDelta = 0.001;

float hash1(inout float seed) {
	return fract(sin(seed += seedDelta)*43758.5453123);
}

vec2 hash2(inout float seed) {
	return fract(sin(vec2(seed+=seedDelta, seed+=seedDelta))*vec2(43758.5453123, 22578.1459123));
}

vec3 hash3(inout float seed) {
	return fract(sin(vec3(seed+=seedDelta, seed+=seedDelta, seed+=seedDelta))*vec3(43758.5453123, 22578.1459123, 19642.3490423));
}

uint hashi(uint x, uint y, uint z) {
	x += x >> 11;
	x ^= x << 7;
	x += y;
	x ^= x << 3;
	x += z ^ (x >> 14);
	x ^= x << 6;
	x += x >> 15;
	x ^= x << 5;
	x += x >> 12;
	x ^= x << 9;
	return x;
}

/**
 * Generate a random value in [-1..+1)
 *   http://amindforeverprogramming.blogspot.de/2013/07/random-floats-in-glsl-330.html
 */
float random(vec2 pos, float time) {
	uint mantissaMask = 0x007FFFFFu;
	uint one = 0x3F800000u;
	uvec3 u = floatBitsToUint(vec3(pos, time));
	uint h = hashi(u.x, u.y, u.z);
	return uintBitsToFloat((h & mantissaMask) | one) - 1.0;
}