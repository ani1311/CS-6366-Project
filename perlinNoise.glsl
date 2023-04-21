// Function for generating pseudo-random values
float hash(float n){
    return fract(sin(n)*43758.5453);
}

// Function for interpolating between two values using a smooth curve
float smoothFn(float t){
    return t*t*t*(t*(t*6.-15.)+10.);
}

// Function for generating 2D gradients
vec2 grad2(float n){
    return vec2(cos(n*2.*3.14159265359),sin(n*2.*3.14159265359));
}

// Function for generating 2D Perlin noise
float perlinNoise(vec2 p){
    vec2 pi=floor(p);
    vec2 pf=fract(p);
    float h00=hash(pi.x+hash(pi.y));
    float h01=hash(pi.x+hash(pi.y+1.));
    float h10=hash(pi.x+1.+hash(pi.y));
    float h11=hash(pi.x+1.+hash(pi.y+1.));
    
    vec2 g00=grad2(h00);
    vec2 g01=grad2(h01);
    vec2 g10=grad2(h10);
    vec2 g11=grad2(h11);
    
    vec2 d00=pf;
    vec2 d01=pf-vec2(0.,1.);
    vec2 d10=pf-vec2(1.,0.);
    vec2 d11=pf-vec2(1.,1.);
    
    float s00=dot(g00,d00);
    float s01=dot(g01,d01);
    float s10=dot(g10,d10);
    float s11=dot(g11,d11);
    
    vec2 fade=vec2(smoothFn(pf.x),smoothFn(pf.y));
    float mix1=mix(s00,s10,fade.x);
    float mix2=mix(s01,s11,fade.x);
    
    return mix(mix1,mix2,fade.y)*.5+.5;
}
