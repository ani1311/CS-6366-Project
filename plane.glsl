
#define EPISILON.0001
const float PI=3.14159265359;
const int MAX_MARCHING_STEPS=255;
const float MIN_DIST=0.;
const float MAX_DIST=100.;
const float PRECISION=.001;

struct Material{
    vec3 ambientColor;// k_a * i_a
    vec3 diffuseColor;// k_d * i_d
    vec3 specularColor;// k_s * i_s
    float alpha;// shininess
};

struct Surface{
    int id;// id of object
    float sd;// signed distance
    Material mat;
};

Material materialWithColor(vec3 color){
    return Material(color*.1,color*.6,color*.9,.1);
}
Material gold(){
    vec3 aCol=.5*vec3(.7,.5,0);
    vec3 dCol=.6*vec3(.7,.7,0);
    vec3 sCol=.6*vec3(1,1,1);
    float a=5.;
    
    return Material(aCol,dCol,sCol,a);
}

Material silver(){
    vec3 aCol=.4*vec3(.8);
    vec3 dCol=.5*vec3(.7);
    vec3 sCol=.6*vec3(1,1,1);
    float a=5.;
    
    return Material(aCol,dCol,sCol,a);
}

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

Surface sdfGround(vec3 p,float h,vec3 baseColor){
    float height=perlinNoise(2.*vec2(p.xz*2.));
    float displacement=height*.08;
    float d=p.y-h-displacement;
    
    vec3 color=mix(vec3(1.,.8745,.3725),baseColor,height*.5+.5);
    Material m=Material(color*.2,color*.01,color*.1,.1);
    return Surface(0,d,m);
}

Surface sdfSphere(vec3 p,vec3 c,float r,vec3 color){
    // color=vec3(perlinNoise(7.*vec2(p.xy)),perlinNoise(11.*vec2(p.xy)),perlinNoise(13.*vec2(p.xy)));
    // Material m=materialWithColor(color);
    Material m=gold();
    
    return Surface(1,length(p-c)-r,m);
}

float random(vec2 st){
    return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.5453123);
}

Surface minWithColor(Surface a,Surface b){
    if(a.sd<b.sd){
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

// SDF cylinder for the tree trunk
Surface sdfTreeTrunk(vec3 p,vec3 center,float r,float h,vec3 color){
    vec3 centered_p=p-center;
    vec2 d=abs(vec2(length(centered_p.xz),centered_p.y))-vec2(r,h*.5);
    Material m=materialWithColor(color);
    return Surface(1,min(max(d.x,d.y),0.)+length(max(d,0.)),m);
}

// SDF sphere for the tree foliage
Surface sdfTreeFoliage(vec3 p,vec3 center,float r,vec3 color){
    // return vec4(length(p-center)-r,color);
    Material m=materialWithColor(color);
    return Surface(2,length(p-center)-r,m);
}

// SDF for a torus
Surface sdfTorus(vec3 p,vec3 center,float r1,float r2,vec3 color){
    vec2 q=vec2(length(p.xz-center.xz)-r1,p.y-center.y);
    Material m=materialWithColor(color);
    return Surface(3,length(q)-r2,m);
}

vec3 orbitingTorusPosition(float time){
    float angle=time*.5;
    float radius=1.;
    vec3 center=vec3(0.,2.,0.);
    vec3 pos=center+radius*vec3(cos(angle),0.,sin(angle));
    return pos;
}

float smoothMin(float a,float b,float k){
    float h=clamp(.5+.5*(b-a)/k,0.,1.);
    return mix(b,a,h)-k*h*(1.-h);
}

Surface blendSDFs(Surface a,Surface b,float k){
    float blendedSDF=smoothMin(a.sd,b.sd,k);
    return Surface(4,blendedSDF,a.mat);
}

Surface sdfTree(vec3 p){
    float c=11.;
    p.xz=mod(p.xz+.5*c,c)-.5*c;
    
    ivec2 cellIndex=ivec2(floor((p.xz+.5*c)/c));
    
    // Generate random values for height, trunk radius, and torus radius
    float randomHeight=mix(2.,4.,random(vec2(cellIndex)));
    float randomTrunkRadius=mix(.1,3.3,random(vec2(cellIndex+ivec2(1337,4242))));
    float randomTorusRadius=mix(.1,.9,random(vec2(cellIndex+ivec2(2141,6879))));
    
    Surface tree=minWithColor(
        sdfTreeTrunk(p,vec3(0.,0.,0.),randomTrunkRadius,randomHeight,vec3(.4,.2,.1)),
        sdfTreeFoliage(p,vec3(0.,randomHeight,0.),1.5,vec3(0.,.8,0.))
    );
    
    vec3 torusCenter=orbitingTorusPosition(iTime);
    Surface torus=sdfTorus(p,torusCenter,1.,randomTorusRadius,vec3(.3,.6,1.));
    
    float blendSmoothness=.5;
    
    Surface res=blendSDFs(tree,torus,blendSmoothness);
    
    return res;
}

Surface sdScene(vec3 p){
    Surface d=sdfGround(p,0.,vec3(.58,.29,0.));
    
    d=minWithColor(d,sdfGround(p,-1.,vec3(.58,.29,0.)));
    // d=minWithColor(d,sdfCylinder(p,vec3(1.,-1.,0.),.3,6.,8.,vec3(.4,.2,.1)));
    
    d=minWithColor(d,sdfTree(p));
    
    vec3 spherePos=movingSpherePosition(iTime);
    // vec3 spherePos=vec3(0.,1.,-4.);
    float sphereRadius=.7;
    
    Surface sphere=sdfSphere(p,spherePos,sphereRadius,vec3(1.,0.,0.));
    
    d=minWithColor(d,sphere);
    
    return d;
}

Surface rayMarch(vec3 ro,vec3 rd){
    float depth=MIN_DIST;
    Surface co;
    
    for(int i=0;i<MAX_MARCHING_STEPS;i++){
        vec3 p=ro+depth*rd;
        co=sdScene(p);
        depth+=co.sd;
        if(co.sd<PRECISION||depth>MAX_DIST)break;
    }
    
    co.sd=depth;
    
    return co;
}
vec3 calcNormal(vec3 p){
    vec2 e=vec2(1.,-1.)*.0005;
    return normalize(
        e.xyy*sdScene(p+e.xyy).sd+
        e.yyx*sdScene(p+e.yyx).sd+
        e.yxy*sdScene(p+e.yxy).sd+
        e.xxx*sdScene(p+e.xxx).sd
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

vec3 phong(vec3 lightDir,vec3 normal,vec3 rd,Material mat){
    // ambient
    vec3 ambient=mat.ambientColor;
    
    // diffuse
    float dotLN=clamp(dot(lightDir,normal),0.,1.);
    vec3 diffuse=mat.diffuseColor*dotLN;
    
    // specular
    float dotRV=clamp(dot(reflect(lightDir,normal),-rd),0.,1.);
    vec3 specular=mat.specularColor*pow(dotRV,mat.alpha);
    
    return ambient+diffuse+specular;
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
    mouseUV.y+=.3;
    
    vec3 lp=vec3(0,.5,-4);// lookat point (aka camera target)
    // vec3 ro=vec3(0,5,0);// ray origin that represents camera position
    
    // Calculate time-dependent camera offset in x direction
    float x_offset=4.*sin(iTime*.5)+2.;
    
    vec3 ro=vec3(
        x_offset,
        5.,
        0.
    );
    
    float cameraRadius=2.;
    ro.yz=ro.yz*cameraRadius*rotate2d(mix(PI/2.,0.,mouseUV.y));
    ro.xz=ro.xz*rotate2d(mix(-PI,PI,mouseUV.x))+vec2(lp.x,lp.z);
    
    vec3 rd=camera(ro,lp)*normalize(vec3(uv,-1.));// ray direction
    
    // vec3 ro=vec3(0.,0.,3.);
    // vec3 rd=normalize(vec3(uv,-1.));
    
    Surface co=rayMarch(ro,rd);
    
    // Calculate fractal noise for the sky
    float skyNoise=fractalNoise(uv*10.);
    vec3 skyColor=mix(vec3(0.,0.,.9882),vec3(.9,.9,1.),skyNoise);
    
    vec3 bgCol=vec3(1.,1.,1.);
    vec3 col=vec3(0.);
    if(co.sd>=MAX_DIST){
        col=skyColor;
        
    }else{
        vec3 p=ro+rd*co.sd;
        vec3 n=calcNormal(p);
        
        // light #1
        vec3 lightPosition1=vec3(-8,-6,-5);
        vec3 lightDirection1=normalize(lightPosition1-p);
        float lightIntensity1=.9;
        
        // light #2
        vec3 lightPosition2=vec3(1,1,1);
        vec3 lightDirection2=normalize(lightPosition2-p);
        float lightIntensity2=.5;
        
        // final color of object
        col=lightIntensity1*phong(lightDirection1,n,rd,co.mat);
        col+=lightIntensity2*phong(lightDirection2,n,rd,co.mat);
        
        // float diff=max(0.,dot(n,lightDir));
        
        // col=co.yzw*diff+.1*bgCol;
    }
    
    // Output to screen
    fragColor=vec4(col,1.);
}
