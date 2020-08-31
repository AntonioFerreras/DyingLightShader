//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//  Copyright (c) 2018-2019 Michele Morrone
//  All rights reserved.
//
//  https://michelemorrone.eu - https://BrutPitt.com
//
//  me@michelemorrone.eu - brutpitt@gmail.com
//  twitter: @BrutPitt - github: BrutPitt
//  
//  https://github.com/BrutPitt/glslSmartDeNoise/
//
//  This software is distributed under the terms of the BSD 2-Clause license
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

const float sigma = 2.0;
const float threshold = 4.0;
const float kSigma = 2.0;

#define INV_SQRT_OF_2PI 0.39894228040143267793994605993439  // 1.0/SQRT_OF_2PI
#define INV_PI 0.31830988618379067153776752674503
//  smartDeNoise - parameters
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  sampler2D tex     - sampler image / texture
//  vec2 uv           - actual fragment coord
//  float sigma  >  0 - sigma Standard Deviation
//  float kSigma >= 0 - sigma coefficient 
//      kSigma * sigma  -->  radius of the circular kernel
//  float threshold   - edge sharpening threshold 

vec4 smartDeNoise(sampler2D tex, vec2 uv)
{
    float radius = round(kSigma*sigma);
    float radQ = radius * radius;

    float invSigmaQx2 = .5 / (sigma * sigma);      // 1.0 / (sigma^2 * 2.0)
    float invSigmaQx2PI = INV_PI * invSigmaQx2;    // // 1/(2 * PI * sigma^2)

    float invThresholdSqx2 = .5 / (threshold * threshold);     // 1.0 / (sigma^2 * 2.0)
    float invThresholdSqrt2PI = INV_SQRT_OF_2PI / threshold;   // 1.0 / (sqrt(2*PI) * sigma)

    vec4 centrPx = texture(tex,uv); 

    float zBuff = 0.0;
    vec4 aBuff = vec4(0.0);
    vec2 size = vec2(textureSize(tex, 0));

    vec2 d;
    for (d.x=-radius; d.x <= radius; d.x++) {
        float pt = sqrt(radQ-d.x*d.x);       // pt = yRadius: have circular trend
        for (d.y=-pt; d.y <= pt; d.y++) {
            float blurFactor = exp( -dot(d , d) * invSigmaQx2 ) * invSigmaQx2PI;

            vec4 walkPx =  texture(tex,uv+d/size);
            vec4 dC = walkPx-centrPx;
            float deltaFactor = exp( -dot(dC, dC) * invThresholdSqx2) * invThresholdSqrt2PI * blurFactor;

            zBuff += deltaFactor;
            aBuff += deltaFactor*walkPx;
        }
    }
    return aBuff/zBuff;
}

vec4 texture2D_bilinear( sampler2D sam, vec2 uv, vec2 res )
{

    vec2 st = uv*res - 0.5;

    vec2 iuv = floor( st );
    vec2 fuv = fract( st );

    vec4 a = texture( sam, (iuv+vec2(0.5,0.5))/res );
    vec4 b = texture( sam, (iuv+vec2(1.5,0.5))/res );
    vec4 c = texture( sam, (iuv+vec2(0.5,1.5))/res );
    vec4 d = texture( sam, (iuv+vec2(1.5,1.5))/res );

    return mix( mix( a, b, fuv.x),
                mix( c, d, fuv.x), fuv.y );
}

vec4 cubic(float x) {
  float x2 = x * x;
  float x3 = x2 * x;
  vec4 w;
  w.x =   -x3 + 3*x2 - 3*x + 1;
  w.y =  3*x3 - 6*x2       + 4;
  w.z = -3*x3 + 3*x2 + 3*x + 1;
  w.w =  x3;
  return w / 6.f;
}

vec4 bicubicTexture(sampler2D tex, vec2 coord) {
  vec2 resolution = vec2(viewWidth, viewHeight);

  coord *= resolution;

  float fx = fract(coord.x);
  float fy = fract(coord.y);
  coord.x -= fx;
  coord.y -= fy;

  vec4 xcubic = cubic(fx);
  vec4 ycubic = cubic(fy);

  vec4 c = vec4(coord.x - 0.5, coord.x + 1.5, coord.y - 0.5, coord.y + 1.5);
  vec4 s = vec4(xcubic.x + xcubic.y, xcubic.z + xcubic.w, ycubic.x + ycubic.y, ycubic.z + ycubic.w);
  vec4 offset = c + vec4(xcubic.y, xcubic.w, ycubic.y, ycubic.w) / s;

  vec4 sample0 = texture2D(tex, vec2(offset.x, offset.z) / resolution);
  vec4 sample1 = texture2D(tex, vec2(offset.y, offset.z) / resolution);
  vec4 sample2 = texture2D(tex, vec2(offset.x, offset.w) / resolution);
  vec4 sample3 = texture2D(tex, vec2(offset.y, offset.w) / resolution);

  float sx = s.x / (s.x + s.y);
  float sy = s.z / (s.z + s.w);

  return mix( mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}

vec4 boxBlur(sampler2D tex, vec2 coord, const float blurSize) {
  const int range = int(floor(blurSize/2.0));
    
  vec4 colors = vec4(0);
    
  for (int x = -range; x <= range; x++) {
      for (int y = -range; y <= range; y++) {
          vec4 color = texture2D(tex, coord+vec2(float(x)/viewWidth,
                                                             float(y)/viewHeight));
          colors += color;
      }
  }
  
  vec4 finalColor = colors/pow(blurSize,2.);
  return finalColor;
}