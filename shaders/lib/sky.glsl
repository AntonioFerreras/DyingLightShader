

vec2 rsi(vec3 r0, vec3 rd, float sr) {
    // ray-sphere intersection that assumes
    // the sphere is centered at the origin.
    // No intersection when result.x > result.y
    float a = dot(rd, rd);
    float b = 2.0 * dot(rd, r0);
    float c = dot(r0, r0) - (sr * sr);
    float d = (b*b) - 4.0*a*c;
    if (d < 0.0) return vec2(1e5,-1e5);
    return vec2(
        (-b - sqrt(d))/(2.0*a),
        (-b + sqrt(d))/(2.0*a)
    );
}

vec3 atmos(vec3 r, vec3 r0, vec3 pSun, float iSteps, float jSteps, float Intensity) {
    vec3 kRlh = vec3(RAYLEIGH_COEFF_R, RAYLEIGH_COEFF_G, RAYLEIGH_COEFF_B);

    // Normalize the sun and view directions.
    pSun = normalize(pSun);
    r = normalize(r);

    // Calculate the step size of the primary ray.
    vec2 p = rsi(r0, r, ATMOSPHERE_RADIUS);
    // if (p.x > p.y) return vec3(0,0,0);
    p.y = min(p.y, rsi(r0, r, PLANET_RADIUS).x);
    float iStepSize = (p.y - p.x) / float(iSteps);

    // Initialize the primary ray time.
    float iTime = 0.0;

    // Initialize accumulators for Rayleigh and Mie scattering.
    vec3 totalRlh = vec3(0,0,0);
    vec3 totalMie = vec3(0,0,0);

    // Initialize optical depth accumulators for the primary ray.
    float iOdRlh = 0.0;
    float iOdMie = 0.0;

    // Calculate the Rayleigh and Mie phases.
    float mu = dot(r, pSun);
    float mumu = mu * mu;
    float gg = MIE_PREFERRED_DIR * MIE_PREFERRED_DIR;
    float pRlh = 3.0 / (16.0 * PI) * (1.0 + mumu);
    float pMie = 3.0 / (8.0 * PI) * ((1.0 - gg) * (mumu + 1.0)) / (pow(1.0 + gg - 2.0 * mu * MIE_PREFERRED_DIR, 1.5) * (2.0 + gg));

    // Sample the primary ray.
    for (int i = 0; i < iSteps; i++) {

        // Calculate the primary ray sample position.
        vec3 iPos = r0 + r * (iTime + iStepSize * 0.5);

        // Calculate the height of the sample.
        float iHeight = length(iPos) - PLANET_RADIUS;

        // Calculate the optical depth of the Rayleigh and Mie scattering for this step.
        float odStepRlh = exp(-iHeight / RAYLEIGH_SCALE) * iStepSize;
        float odStepMie = exp(-iHeight / MIE_SCALE) * iStepSize;

        // Accumulate optical depth.
        iOdRlh += odStepRlh;
        iOdMie += odStepMie;

        // Calculate the step size of the secondary ray.
        float jStepSize = rsi(iPos, pSun, ATMOSPHERE_RADIUS).y / float(jSteps);

        // Initialize the secondary ray time.
        float jTime = 0.0;

        // Initialize optical depth accumulators for the secondary ray.
        float jOdRlh = 0.0;
        float jOdMie = 0.0;

        // Sample the secondary ray.
        for (int j = 0; j < jSteps; j++) {

            // Calculate the secondary ray sample position.
            vec3 jPos = iPos + pSun * (jTime + jStepSize * 0.5);

            // Calculate the height of the sample.
            float jHeight = length(jPos) - PLANET_RADIUS;

            // Accumulate the optical depth.
            jOdRlh += exp(-jHeight / RAYLEIGH_SCALE) * jStepSize;
            jOdMie += exp(-jHeight / MIE_SCALE) * jStepSize;

            // Increment the secondary ray time.
            jTime += jStepSize;
        }

        // Calculate attenuation.
        vec3 attn = exp(-(MIE_COEFF * (iOdMie + jOdMie) + kRlh * (iOdRlh + jOdRlh)));

        // Accumulate scattering.
        totalRlh += odStepRlh * attn;
        totalMie += odStepMie * attn;

        // Increment the primary ray time.
        iTime += iStepSize;

    }

    // Calculate and return the final color.
    return Intensity * (pRlh * kRlh * totalRlh + pMie * MIE_COEFF * totalMie);
}

vec3 sampleSky(vec3 r, vec3 r0, vec3 pSun, vec3 pMoon, bool isLowQuality) {
    if(!isLowQuality) {
        vec3 color;
        if(night < 0.0001) {
            color = atmos(r, r0, pSun, PRIMARY_STEPS, SECONDARY_STEPS, ATMOSPHERE_INTENSITY);
        } else if(night > 0.999) {
            color = atmos(r, r0, pMoon, PRIMARY_STEPS, SECONDARY_STEPS, ATMOSPHERE_INTENSITY*0.006);
        } else {
            vec3 daySky =  atmos(r, r0, pSun, PRIMARY_STEPS, SECONDARY_STEPS, ATMOSPHERE_INTENSITY);
            vec3 nightSky =  atmos(r, r0, pMoon, PRIMARY_STEPS, SECONDARY_STEPS, ATMOSPHERE_INTENSITY*0.006);
            color = mix(daySky, nightSky, night);
        }
        vec3 sunAngle = vec3(pSun.x, -0.4, pSun.z);
        color += pow(vec3(253, 212, 125)/255.0, vec3(5.2))*clamp(pow64(min(1.0 + r.y, 1.0))*pow(1.0-night, 3)*sunset*pow(dot(r, sunAngle), 3.0), 0.0, 0.99);
        // color = mix(color, pow(vec3(253, 212, 125)/255.0, vec3(5.2)), clamp(pow64(min(1.0 + r.y, 1.0))*pow(1.0-night, 3)*sunset*pow(dot(r, sunAngle), 3.0), 0.0, 0.99));
        return color;
    } else {
        return atmos(r, r0, pSun, PRIMARY_STEPS_LOD, SECONDARY_STEPS_LOD, ATMOSPHERE_INTENSITY);
    }
}
