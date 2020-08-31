vec4 samplePanoramic(vec3 worldPos, float lodLevel) {
	worldPos = normalize(worldPos);

	float theta = atan(worldPos.y, worldPos.x);
    if(theta < 0.0) {
        theta = 2.0*PI + theta;
    }
    float phi = acos(worldPos.z);

	vec2 sampleUV = vec2(phi / PI, theta / (2.0*PI));

    return textureLod(colortex7, sampleUV, lodLevel);
}

vec4 samplePanoramicNormal(vec3 worldPos) {
	worldPos = normalize(worldPos);

	float theta = atan(worldPos.y, worldPos.x);
    if(theta < 0.0) {
        theta = 2.0*PI + theta;
    }
    float phi = acos(worldPos.z);

	vec2 sampleUV = vec2(phi / PI, theta / (2.0*PI));

    return texture2D(colortex1, sampleUV);
}

vec3 getReflectionColour(vec3 reflectedPos, vec3 reflectedDir, vec3 depthWorldPoint, float mipLevel) {
    vec3 reflectionCol = vec3(0.0);
    if(!all(equal(reflectedPos, vec3(0.0)))) {
		vec4 panoramicSample = samplePanoramic(viewToWorld(reflectedPos), mipLevel);
		reflectionCol = panoramicSample.rgb;
    } else {
		reflectionCol = sampleSky(viewToWorld(reflectedDir), vec3(0,6372e3,0), normalize(viewToWorld(sunPosition)), normalize(viewToWorld(moonPosition)), false);
		reflectionCol = applyFog(reflectionCol, far, depthWorldPoint, viewToWorld(reflectedDir), 1.0);//Apply fog to sky sample
	}
    return reflectionCol;
}

// vec3 binarySearch(vec3 origin, vec3 direction, int iterationLimit) {
// 	float deltaDepth = 1;
// 	while (iterationLimit-- != 0 && deltaDepth > 0.001) {
// 		deltaDepth = origin.z - texture(positionInGBuffer, convertViewSpaceToTextureSpace(origin)).z;
// 		origin += (deltaDepth > 0) ? direction : -direction;
// 		direction /= 2;
// 	}
// 	return origin;
// }

const float rayStepSize = 1.0;//0.3;

const int maxSteps = 8;
const int refinementSteps = 6;

vec4 raymarchEqui(vec3 start, vec3 rd) {
	// if(rd.z > 0.0) {
	// 	return vec4(0.0);
	// }

	vec3 ro = start;
	float dist = 0.0;
	float dir = 1.0;
	float stepSize = rayStepSize;
	int goodInterection = 0;

	// ro = start + rd*stepSize*dither;
	
	for(int i = 0; i < maxSteps; i++) {
		//March ray
		dist += stepSize;
		ro = start + rd*dist;

		// vec2 screenCoord = viewToScreen(ro);
		// if(any(greaterThan(screenCoord, vec2(1.0))) || any(lessThan(screenCoord, vec2(0.0)))) {
		// 	return vec4(ro, length(ro));
		// }

		//Get depth & difference
		float depthDist = samplePanoramic(viewToWorld(ro), 0.0).a;
		float rayCamDist = length(ro);
		float depth_diff = depthDist - rayCamDist;

		//Get normal
		// vec3 normal = worldToView(samplePanoramicNormal(viewToWorld(ro)).rgb * 2.0 - 1.0);

		//Check if ray went behind depth
		if(depth_diff <= 0.0 && depth_diff > -stepSize*2.2 && i > 0) {//   && depth_diff > -stepSize*1.5  && dot(normal, -rd) > 0.0
			goodInterection = 1;
			// for(int j = 0; j < refinementSteps; j++) {
			// 	depthDist = samplePanoramic(viewToWorld(ro), 0.0).a;
			// 	rayCamDist = length(ro);
			// 	depth_diff = depthDist - rayCamDist;

			// 	dir *= (depth_diff < 0.0) ? -1.0 : 1.0;

			// 	stepSize *= 0.5;
			// 	dist += stepSize*dir;
			// 	ro = start + rd*dist;
			// }

			return vec4(ro, distance(start, ro));
		} else {
			goodInterection = 0;
		}
		// if(distance(start, ro) > 3.0) {
			stepSize *= 1.3;
		// }

	}
	// return vec4(0.0);
	return vec4(ro, distance(start, ro)) * goodInterection;

	

}

const float rayStepSizeLONG = 1.0;//0.3;

vec4 raymarchEquiLONG(vec3 start, vec3 rd) {

	vec3 ro = start;
	float dist = 0.0;
	float dir = 1.0;
	float stepSize = rayStepSizeLONG;
	int goodInterection = 0;

	// ro = start + rd*stepSize*dither;
	
	for(int i = 0; i < 20; i++) {
		//March ray
		dist += stepSize;
		ro = start + rd*dist;

		// vec2 screenCoord = viewToScreen(ro);
		// if(any(greaterThan(screenCoord, vec2(1.0))) || any(lessThan(screenCoord, vec2(0.0)))) {
		// 	return vec4(ro, length(ro));
		// }

		//Get depth & difference
		float depthDist = samplePanoramic(viewToWorld(ro), 0.0).a;
		float rayCamDist = length(ro);
		float depth_diff = depthDist - rayCamDist;

		//Get normal
		// vec3 normal = worldToView(samplePanoramicNormal(viewToWorld(ro)).rgb * 2.0 - 1.0);

		//Check if ray went behind depth
		if(depth_diff <= 0.0 && depth_diff > -stepSize*2.2 && i > 0) {//   && depth_diff > -stepSize*1.5  && dot(normal, -rd) > 0.0
			goodInterection = 1;

			return vec4(ro, distance(start, ro));
		} else {
			goodInterection = 0;
		}
		// if(distance(start, ro) > 3.0) {
			stepSize *= 1.3;
		// }

	}
	// return vec4(0.0);
	return vec4(ro, distance(start, ro)) * goodInterection;

	

}

//xyz = hit position | w = distance
vec4 raymarch(vec3 start, vec3 rd, sampler2D depthtex) {
	// if(rd.z > 0.0) {
	// 	return vec4(0.0);
	// }

	vec3 ro = start;
	float dist = 0.0;
	float dir = 1.0;
	float stepSize = rayStepSize;
	
	for(int i = 0; i < maxSteps; i++) {
		//March ray
		dist += stepSize;
		ro = start + rd*dist;

		//Project onto screen
		vec2 screenCoord = viewToScreen(ro);

		if(any(greaterThan(screenCoord, vec2(1.0))) || any(lessThan(screenCoord, vec2(0.0)))) {
			return vec4(0.0);
		}

		//Get depth & difference
		float depth = texture2D(depthtex, screenCoord).r;
		// float depth = samplePanoramic(viewToWorld(ro, 1.0)).a;
		float depthDist = length(getDepthPoint(screenCoord, depth));
		// float depthDist = linearizeDepth(depth);
		float rayCamDist = length(ro);
		float depth_diff = depthDist - rayCamDist;

		//Check if ray went behind depth
		if(depth_diff <= 0.0 && depth_diff > -1.0) {
			// dir = -1.0;
			// for(int j = 0; j < refinementSteps; j++) {
			// 	stepSize *= 0.5;
			// 	dist += stepSize*dir;
			// 	ro = start + rd*dist;
			// 	screenCoord = viewToScreen(ro);
			// 	depth = texture2D(depthtex, screenCoord).r;
			// 	depthDist = length(getDepthPoint(screenCoord, depth));
			// 	rayCamDist = length(ro);
			// 	depth_diff = depthDist - rayCamDist;

			// 	dir *= (depth_diff < 0.0) ? -1.0 : 1.0;
			// }
			return vec4(ro, rayCamDist);
		}

	}
	return vec4(0.0);

}

const float rayStepSizeLOW = 2.5;
const int maxStepsLOW = 10;

//xyz = hit position | w = distance
vec4 raymarchLOWQUALITY(vec3 start, vec3 rd, sampler2D depthtex) {
	// if(rd.z > 0.0) {
	// 	return vec4(0.0);
	// }

	vec3 ro = start;
	float dist = 0.0;
	float dir = 1.0;
	float stepSize = rayStepSizeLOW;
	
	for(int i = 0; i < maxStepsLOW; i++) {
		//March ray
		dist += stepSize;
		ro = start + rd*dist;

		//Project onto screen
		vec2 screenCoord = viewToScreen(ro);

		if(any(greaterThan(screenCoord, vec2(1.0))) || any(lessThan(screenCoord, vec2(0.0)))) {
			return vec4(0.0);
		}

		//Get depth & difference
		float depth = texture2D(depthtex, screenCoord).r;
		// float depth = samplePanoramic(viewToWorld(ro, 1.0)).a;
		float depthDist = length(getDepthPoint(screenCoord, depth));
		// float depthDist = linearizeDepth(depth);
		float rayCamDist = length(ro);
		float depth_diff = depthDist - rayCamDist;

		//Check if ray went behind depth
		if(depth_diff <= 0.0 && depth_diff > -3.0) {
			// dir = -1.0;
			// for(int j = 0; j < refinementSteps; j++) {
			// 	stepSize *= 0.5;
			// 	dist += stepSize*dir;
			// 	ro = start + rd*dist;
			// 	screenCoord = viewToScreen(ro);
			// 	depth = texture2D(depthtex, screenCoord).r;
			// 	depthDist = length(getDepthPoint(screenCoord, depth));
			// 	rayCamDist = length(ro);
			// 	depth_diff = depthDist - rayCamDist;

			// 	dir *= (depth_diff < 0.0) ? -1.0 : 1.0;
			// }
			return vec4(ro, rayCamDist);
		}

	}
	return vec4(0.0);

}