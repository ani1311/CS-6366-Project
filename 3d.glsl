const int MAX_MARCHING_STEPS=255;
const float MIN_DIST=0.;
const float MAX_DIST=100.;
const float PRECISION=.001;

float sdSphere(vec3 p,vec3 offset,float r){
    return length(p-offset)-r;
}

mat2 Rot(float a){
    float s=sin(a);
    float c=cos(a);
    return mat2(c,-s,s,c);
}

vec3 R(vec2 uv,vec3 p,vec3 l,float z){
    vec3 f=normalize(l-p),
    r=normalize(cross(vec3(0,1,0),f)),
    u=cross(f,r),
    c=p+f*z,
    i=c+uv.x*r+uv.y*u,
    d=normalize(i-p);
    return d;
}

float sdBox(vec3 p,vec3 offset,float s){
    vec3 d=abs(p-offset)-s;
    return min(max(d.x,max(d.y,d.z)),0.)+length(max(d,0.));
}

float sdCuboid(vec3 p,vec3 b){
    vec3 d=abs(p)-b;
    return min(max(d.x,max(d.y,d.z)),0.)+length(max(d,0.));
}

float sdPlane(vec3 p,float h){
    return p.y-h;
}

float infiniteSpheres(vec3 p,vec3 offset,float s,vec3 spacing){
    // Wrap the space using the mod function and adjust the origin
    vec3 wrappedPos=mod(p,spacing)-.5*spacing;
    
    // Calculate the distance using the SdSphere function
    float distance=sdSphere(wrappedPos,offset,s);
    
    return distance;
}

float infiniteCuboids(vec3 p,vec3 offset,float s,vec3 spacing){
    // Wrap the space using the mod function and adjust the origin
    vec3 wrappedPos=mod(p,spacing)-.5*spacing;
    
    // Calculate the distance using the SdSphere function
    float distance=sdCuboid(wrappedPos,offset);
    
    return distance;
}

float random(vec3 st){
    return fract(sin(dot(st.xyz,vec3(12.9898,78.233,37.719)))*43758.5453);
}

float sdf(vec3 p){
    float t=iTime;
    vec3 spacing=vec3(1.6,.0,1.6);
    vec3 offset=vec3(0,-1.,0);
    float d=infiniteSpheres(p,offset,.2,spacing);
    d=min(d,sdPlane(p,-1.2));
    return d;
}

float rayMarch(vec3 ro,vec3 rd,float start,float end){
    float depth=start;
    
    for(int i=0;i<MAX_MARCHING_STEPS;i++){
        vec3 p=ro+depth*rd;
        float d=sdf(p);
        depth+=d;
        if(d<PRECISION||depth>end)break;
    }
    
    return depth;
}

vec3 calcNormal(vec3 p){
    vec2 e=vec2(1.,-1.)*.0005;// epsilon
    return normalize(
        e.xyy*sdf(p+e.xyy)+
        e.yyx*sdf(p+e.yyx)+
        e.yxy*sdf(p+e.yxy)+
        e.xxx*sdf(p+e.xxx)
    );
}

void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
    vec2 uv=(fragCoord-.5*iResolution.xy)/iResolution.y;
    vec3 backgroundColor=vec3(.835,1,1);
    vec2 m=iMouse.xy/iResolution.xy;
    
    vec3 col=vec3(0);
    
    vec3 ro=vec3(0,4,-5);
    ro.yz*=Rot(-m.y+.4);
    // ro.xz*=Rot(iTime*.2-m.x*6.2831);
    
    vec3 rd=R(uv,ro,vec3(0,0,0),.7);
    
    float d=rayMarch(ro,rd,MIN_DIST,MAX_DIST);// distance to sphere
    
    if(d>MAX_DIST){
        col=backgroundColor;// ray didn't hit anything
    }else{
        vec3 p=ro+rd*d;// point on sphere we discovered from ray marching
        vec3 normal=calcNormal(p);
        vec3 lightPosition=vec3(2,2,7);
        vec3 lightDirection=normalize(lightPosition-p);
        
        // Calculate diffuse reflection by taking the dot product of
        // the normal and the light direction.
        float dif=clamp(dot(normal,lightDirection),.3,1.);
        
        // Multiply the diffuse reflection value by an orange color and add a bit
        // of the background color to the sphere to blend it more with the background.
        col=dif*vec3(1,.58,.29)+backgroundColor*.2;
    }
    
    // Output to screen
    fragColor=vec4(col,1.);
}
