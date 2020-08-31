
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

// vec4 boxBlur(sampler2D tex, vec2 coord, const float blurSize) {
//   const int range = int(floor(blurSize/2.0));
    
//   vec4 colors = vec4(0);
    
//   for (int x = -range; x <= range; x++) {
//       for (int y = -range; y <= range; y++) {
//           vec4 color = texture2D(tex, coord+vec2(float(x)/viewWidth,
//                                                              float(y)/viewHeight));
//           colors += color;
//       }
//   }
  
//   vec4 finalColor = colors/pow(blurSize,2.);
//   return finalColor;
// }