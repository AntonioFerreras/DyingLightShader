vec2 wavedx(vec2 position, vec2 direction, float frequency, float speed, float timeshift) {
    float x = dot(direction, position) * frequency + timeshift * speed * WATER_WAVE_SPEED;
    float wave = exp(sin(x) - 1.0);
    float dx = -wave * cos(x);
    return vec2(wave, dx);
}

float getWaves(vec2 position, int iterations){
	// position *= 50.0;
	// return sin(position.x + frameTimeCounter) * cos(position.y + frameTimeCounter);
    float iter = 0.0;
    float phase = 1.8;
    float weight = 1.0;
    float w = 0.0;
    float ws = 0.0;
    for(int i =0 ; i<iterations; i++){
        vec2 p = vec2(sin(iter), cos(iter));
        vec2 res = wavedx(position, p, phase, 1.0, frameTimeCounter);
        position += normalize(p) * res.y * weight * 0.0048;
        w += res.x * weight;
        iter += 12.0;
        ws += weight;
        weight = mix(weight, 0.0, 0.2);
        phase *= 1.18;
    }
    return w / ws;
}
vec3 getWaterNormal(vec2 pos, int iter, float depth, out float height){
	pos *= 1.9;
    float e = 0.08;//Epsilon
    vec2 ex = vec2(e, 0);
    float H = getWaves(pos.xy * 0.1, iter) * depth;
    vec3 a = vec3(pos.x, H, pos.y);
	float firstWave = getWaves(pos.xy * 0.1 - ex.xy * 0.1, iter);
	height = firstWave;
    vec3 normal = normalize(cross(normalize(a-vec3(pos.x - e, firstWave * depth, pos.y)),
    normalize(a-vec3(pos.x, getWaves(pos.xy * 0.1 + ex.yx * 0.1, iter) * depth, pos.y + e))));
    return normal;
}

vec2 calcRefract(vec2 coord, vec3 normal) {
	float depth0 = texture2D(depthtex0, coord).r;	
	float depth1 = texture2D(depthtex1, coord).r;	
	if(depth0 >= depth1) return coord;

	vec3 depthPoint0 = getDepthPoint(coord, depth0);
	vec3 depthPoint1 = getDepthPoint(coord, depth1);

	vec3 normalFlat = vec3(0.0, 1.0, 0.0);

	float refractionDepth = min(distance(depthPoint0, depthPoint1), 0.5);

	vec2 refractedCoord = coord + (viewToWorld(normal).xz - normalFlat.xz) * refractionDepth / depthPoint0.z;

	float refractedDepth = texture2D(depthtex1, refractedCoord).r;
	return depth0 > refractedDepth ? coord : refractedCoord;
}

const vec3 WATER_ABSORP = vec3(WATER_ABSORP_R, WATER_ABSORP_G, WATER_ABSORP_B);
const vec3 WATER_ABSORP_FOG = vec3(0.2, 0.15, 0.12);