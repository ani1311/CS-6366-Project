
#define EPISILON.0001
#define MAX_STEPS 100
#define MAX_DEPTH 200.
const float PI=3.14159265359;

// Rotate around a circular path
mat2 rotate2d(float theta){
    float s=sin(theta),c=cos(theta);
    return mat2(c,-s,s,c);
}

// Rotation matrix around the X axis.
mat3 rotateX(float theta){
    float c=cos(theta);
    float s=sin(theta);
    return mat3(
        vec3(1,0,0),
        vec3(0,c,-s),
        vec3(0,s,c)
    );
}

// Rotation matrix around the Y axis.
mat3 rotateY(float theta){
    float c=cos(theta);
    float s=sin(theta);
    return mat3(
        vec3(c,0,s),
        vec3(0,1,0),
        vec3(-s,0,c)
    );
}

// Rotation matrix around the Z axis.
mat3 rotateZ(float theta){
    float c=cos(theta);
    float s=sin(theta);
    return mat3(
        vec3(c,-s,0),
        vec3(s,c,0),
        vec3(0,0,1)
    );
}

// Identity matrix.
mat3 identity(){
    return mat3(
        vec3(1,0,0),
        vec3(0,1,0),
        vec3(0,0,1)
    );
}

//----------------------------------------------------
// perlin noise stuff
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

// ----------------------------------------------------

vec4 sdfGround(vec3 p,float h,vec3 baseColor){
    float height=perlinNoise(7.*vec2(p.xz));
    float displacement=height*.02;
    float d=p.y-h-displacement;
    
    vec3 color=mix(vec3(.5,.25,.1),baseColor,height*.5+.5);
    return vec4(d,color);
}

// vec4 sdfGround(vec3 p,float h,vec3 color){
    
    //     return vec4(p.y-h,color);
// }

vec4 sdfSphere(vec3 p,vec3 c,float r,vec3 color){
    // color=vec3(perlinNoise(7.*vec2(p.xy)),perlinNoise(11.*vec2(p.xy)),perlinNoise(13.*vec2(p.xy)));
    
    return vec4(length(p-c)-r,color);
}

// vec4 sdfCylinder(vec3 p,vec3 center,float r,float h,vec3 color){
    //     float c=6.;
    //     p=p-center;
    //     p.xz=mod(p.xz+.5*c,c)-.5*c;
    //     vec2 d=abs(vec2(length(p.xz),p.y))-vec2(r,h*.5);
    //     return vec4(min(max(d.x,d.y),0.)+length(max(d,0.)),color);
// }

float random(vec2 st){
    return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.5453123);
}

// vec4 sdfCylinder(vec3 p,vec3 center,float r,float minHeight,float maxHeight,vec3 color){
    //     float c=7.;
    //     vec3 centered_p=p-center;
    
    //     ivec2 cellIndex=ivec2(floor((centered_p.xz+.5*c)/c));
    //     vec2 rep_p_xz=mod(centered_p.xz+.5*c,c)-.5*c;
    
    //     // Calculate the random height for the current cylinder
    //     float randomHeight=mix(minHeight,maxHeight,random(vec2(cellIndex)));
    
    //     centered_p.xz=rep_p_xz;
    //     vec2 d=abs(vec2(length(centered_p.xz),centered_p.y))-vec2(r,randomHeight*.5);
    //     return vec4(min(max(d.x,d.y),0.)+length(max(d,0.)),color);
// }

vec4 sdfCylinder(vec3 p,vec3 center,float r,float minHeight,float maxHeight,vec3 color){
    float c=7.;
    vec3 centered_p=p-center;
    
    ivec2 cellIndex=ivec2(floor((centered_p.xz+.5*c)/c));
    vec2 rep_p_xz=mod(centered_p.xz+.5*c,c)-.5*c;
    
    // Calculate the random height for the current cylinder
    float randomHeight=mix(minHeight,maxHeight,random(vec2(cellIndex)));
    
    centered_p.xz=rep_p_xz;
    
    // Flute parameters
    int numFlutes=8;
    float fluteRadius=r*.2;
    float fluteAngle=2.*3.14159265359/float(numFlutes);
    
    // Calculate fluted radius
    float angle=atan(centered_p.z,centered_p.x);
    float fluteId=floor(angle/fluteAngle);
    float localAngle=angle-fluteId*fluteAngle;
    float localRadius=r-(1.-smoothstep(0.,fluteAngle*.5,abs(localAngle-fluteAngle*.5)))*fluteRadius;
    
    vec2 d=abs(vec2(length(vec2(centered_p.x,centered_p.z)),centered_p.y))-vec2(localRadius,randomHeight*.5);
    return vec4(min(max(d.x,d.y),0.)+length(max(d,0.)),color);
}

// vec4 sdfCylinder(vec3 p,vec3 center,float r,float minHeight,float maxHeight,vec3 color1,vec3 color2){
    //     float c=7.;
    //     vec3 centered_p=p-center;
    
    //     ivec2 cellIndex=ivec2(floor((centered_p.xz+.5*c)/c));
    //     vec2 rep_p_xz=mod(centered_p.xz+.5*c,c)-.5*c;
    
    //     // Calculate the random height for the current cylinder
    //     float randomHeight=mix(minHeight,maxHeight,random(vec2(cellIndex)));
    
    //     centered_p.xz=rep_p_xz;
    
    //     vec2 d=abs(vec2(length(vec2(centered_p.x,centered_p.z)),centered_p.y))-vec2(r,randomHeight*.5);
    
    //     // Calculate noise value and use it to blend two colors and create a texture
    //     float noiseValue=perlinNoise(centered_p.xz*5.);
    //     vec3 blendedColor=mix(color1,color2,noiseValue);
    
    //     return vec4(min(max(d.x,d.y),0.)+length(max(d,0.)),blendedColor);
// }

vec4 minWithColor(vec4 a,vec4 b){
    if(a.x<b.x){
        return a;
    }else{
        return b;
    }
}

vec3 movingSpherePosition(float time){
    float x=sin(time*.5)*11.5;
    float y=cos(time*.7)*2.5+3.;
    float z=sin(time*.3)*20.5-22.;
    return vec3(x,y,z);
}

vec4 sdScene(vec3 p){
    vec4 d=vec4(1e10,0.,0.,0.);
    
    d=minWithColor(d,sdfGround(p,-1.,vec3(.58,.29,0.)));
    d=minWithColor(d,sdfCylinder(p,vec3(1.,-1.,0.),.3,6.,8.,vec3(.4,.2,.1)));
    
    vec3 spherePos=movingSpherePosition(iTime);
    // vec3 spherePos=vec3(0.,1.,-4.);
    float sphereRadius=.7;
    
    vec4 sphere=sdfSphere(p,spherePos,sphereRadius,vec3(1.,0.,0.));
    
    d=minWithColor(d,sphere);
    
    return d;
}

vec4 rayMarch(vec3 ro,vec3 rd,float start,float end){
    float t=start;
    vec4 co;
    for(int i=0;i<MAX_STEPS;i++){
        co=sdScene(ro+rd*t);
        
        t+=co.x;
        if(co.x<EPISILON||t>end){
            break;
        }
        
    }
    
    return vec4(t,co.yzw);
}

vec3 calcNormal(in vec3 p){
    vec2 e=vec2(1.,-1.)*EPISILON;// epsilon
    return normalize(
        e.xyy*sdScene(p+e.xyy).x+
        e.yyx*sdScene(p+e.yyx).x+
        e.yxy*sdScene(p+e.yxy).x+
        e.xxx*sdScene(p+e.xxx).x
    );
}

float fractalNoise(vec2 p){
    float f=0.;
    float scale=1.;
    for(int i=0;i<4;i++){
        f+=perlinNoise(p*scale)/scale;
        scale*=2.;
    }
    return f;
}

mat3 camera(vec3 cameraPos,vec3 lookAtPoint){
    vec3 cd=normalize(lookAtPoint-cameraPos);// camera direction
    vec3 cr=normalize(cross(vec3(0,1,0),cd));// camera right
    vec3 cu=normalize(cross(cd,cr));// camera up
    
    return mat3(-cr,cu,-cd);
}

void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
    // Normalized pixel coordinates (from 0 to 1)
    // vec2 uv=fragCoord/iResolution.xy;
    vec2 uv=(fragCoord-.5*iResolution.xy)/iResolution.y;
    vec2 mouseUV=iMouse.xy/iResolution.xy;// Range: <0, 1>
    mouseUV-=.5;
    mouseUV.x*=2.;
    mouseUV.y*=.4;
    mouseUV.y+=.1;
    
    vec3 lp=vec3(0,.5,-4);// lookat point (aka camera target)
    vec3 ro=vec3(0,5,0);// ray origin that represents camera position
    
    float cameraRadius=2.;
    ro.yz=ro.yz*cameraRadius*rotate2d(mix(PI/2.,0.,mouseUV.y));
    ro.xz=ro.xz*rotate2d(mix(-PI,PI,mouseUV.x))+vec2(lp.x,lp.z);
    
    vec3 rd=camera(ro,lp)*normalize(vec3(uv,-1));// ray direction
    
    // vec3 ro=vec3(0.,0.,3.);
    // vec3 rd=normalize(vec3(uv,-1.));
    
    vec4 co=rayMarch(ro,rd,0.,MAX_DEPTH);
    
    // Calculate fractal noise for the sky
    float skyNoise=fractalNoise(uv*10.);
    vec3 skyColor=mix(vec3(0.,0.,.9882),vec3(.9,.9,1.),skyNoise);
    
    vec3 bgCol=vec3(1.,1.,1.);
    vec3 col=vec3(0.);
    if(co.x>=MAX_DEPTH){
        col=skyColor;
        
    }else{
        vec3 p=ro+rd*co.x;
        vec3 n=calcNormal(p);
        vec3 lightPos=vec3(2.,2.,7.);
        vec3 lightDir=normalize(lightPos-p);
        float diff=max(0.,dot(n,lightDir));
        
        col=co.yzw*diff+.1*bgCol;
    }
    
    // Output to screen
    fragColor=vec4(col,1.);
}
