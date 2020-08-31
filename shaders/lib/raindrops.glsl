// Author: Élie Michel
// License: CC BY 3.0
// July 2017

vec2 rand(vec2 c){
    mat2 m = mat2(12.9898,.16180,78.233,.31415);
	return fract(sin(m * c) * vec2(43758.5453, 14142.1));
}

vec2 noise(vec2 p){
	vec2 co = floor(p);
	vec2 mu = fract(p);
	mu = 3.*mu*mu-2.*mu*mu*mu;
	vec2 a = rand((co+vec2(0.,0.)));
	vec2 b = rand((co+vec2(1.,0.)));
	vec2 c = rand((co+vec2(0.,1.)));
	vec2 d = rand((co+vec2(1.,1.)));
	vec2 n = mix(mix(a, b, mu.x), mix(c, d, mu.x), mu.y);
    return n;
}

vec3 doRainDrops(in vec2 c, float time, sampler2D bg )
{
	vec2 u = c / resolution,
         v = (c*.1)/ resolution,
         n = noise(v*200.); // Displacement
    
    vec4 f = texture(bg, u);
    
    // Loop through the different inverse sizes of drops
    for (float r = 2. ; r > 0. ; r--) {
        vec2 x = vec2(1920., 1080.) * r * .010;  // Number of potential drops (in a grid)
        vec2 p = 6.28 * u * x + (n - .5) * 2.0;
        vec2 s = sin(p);
        
        // Current drop properties. Coordinates are rounded to ensure a
        // consistent value among the fragment of a given drop.
        vec2 v = round(u * x - 0.25) / x;
        vec4 d = vec4(noise(v*200.), noise(v));
        
        // Drop shape and fading
        float t = (s.x+s.y) * max(0., 1. - fract(time * 0.25 * (d.b + .1) + d.g) * 2.);
        
        // d.r -> only x% of drops are kept on, with x depending on the size of drops
        if (d.r < (5.-r)*.08 && t > .5) {
            // Drop normal
            vec3 v = normalize(-vec3(cos(p), mix(.2, 2., t-.5)));
            // fragColor = vec4(v * 0.5 + 0.5, 1.0);  // show normals
            
            // Poor man's refraction (no visual need to do more)
            f = texture(bg, u - v.xy * .3);
        }
    }
    return f.rgb;
}

// #define HASHSCALE3 vec3(.1031,.1030,.0973)
// #define HASHSCALE1 .1031
// //hashes from https://www.shadertoy.com/view/4djSRW
// vec3 hash33(vec3 p3){p3=fract(p3*HASHSCALE3);
//  p3+=dot(p3,p3.yxz+19.19);
//  return fract((p3.xxy + p3.yxx)*p3.zyx);}
// #define vorRainSpeed  .8
// #define vorRainScale 1.0
// //worley rain subroutine
// float bias(float s,float b){return s/((((1./b)-2.)*(1.-s))+1.);}
// //worley rain
// vec3 vorRain(vec3 p,float r){
//  vec3 vw,xy,xz,s1,s2,xx;
//  vec3 yz=vec3(0),bz=vec3(0),az=vec3(0),xw=vec3(0);
//  p=p.xzy;p/=vorRainScale;
//  vec3 uv2=p,p2=p;
//  p=vec3(floor(p)); 
//  float t=iTime*vorRainSpeed;
//  //vec2 rand = vw/vec2(iterations);
//  vec2 yx=vec2(0);
//  for(int j=-1;j<=1;j++)
//  for(int k=-1;k<=1;k++){
//   vec3 offset=vec3(float(j),float(k),0.);
//   //hashed for grid
//   s1.xz=hash33(p+offset.xyz+127.43+r).xz;
//   //hashed for timer for switching positions of raindrop
//   s2.xz=floor(s1.xx + t);
//   //add timer to random value so that everytime a ripple fades, a new drop appears
//   xz.xz=hash33(p+offset.xyz+(s2)+r).xz;
//   xx=hash33(p+offset.xyz+(s2-1.));
//   s1=mod(s1+t,1.);
//   //p2=(p2-p2)+vec3(s1.x,0.0,s1.y);
//   p2=mod(p2,1.0);
//   float op=1.-s1.x;//opacity
//   op=bias(op,.21);//optional smooth blending
//   //change the profile of the timer
//   s1.x=bias(s1.x,.62);//optional harder fadeout
//   float size=mix(4.,1.,s1.x);//ripple.expansion over time
//   //move ripple formation from the center as it grows
//   float size2=mix(.005,2.0,s1.x);
//   // make the voronoi 'balls'
//   xy.xz=vec2(length((p.xy+xz.xz)-(uv2.xy-offset.xy))*size);
//   //xy.xz *= (1.0/9.0);
//   xx=vec3(length((p2)+xz)-(uv2-offset)*1.30);
//   //xx=1.-xx;//optional?
//   xy.x=1.-xy.x;//mandatory!
//   xy.x*=size2;//almost optional viscosity
//   #define ripp if(xy.x>.5)xy.x=mix(1.,0.,xy.x);xy.x=mix(0.,2.,xy.x) 
//   ripp;ripp;
//   xy.x=smoothstep(.0,1.,xy.x);
//   xy*=op;// fade ripple over time
//   yz =1.-((1.-yz)*(1.-xy));
//  }return vec3(yz*.1);}

// //less ripples is really prettier than more ripples.
// #define iterRippleCount 2.
// //only problem is that many drops hit at the very same time, so 2 is reasonable minimum.
// //returns height  of water ripples at [p]
// float dfRipples(vec3 p){
//  float pl=(p.y+1.);
//  vec3 r=vec3(0);
//  for(float i=0.;i<iterRippleCount;i++){
//   r+=vorRain(p,i+1.);
//  }return pl-r.x;
// }