
#define S snoise2D(p+=.04)*.3+snoise2D(p*3.)*.2+.5

float circle(vec2 uv,vec2 center,float rad,float blur){
    float d=length(uv-center);
    return smoothstep(rad,rad-blur,d);
}

float band(float t,float start,float end,float blur){
    float t1=smoothstep(t,t-blur,end);
    float t2=smoothstep(t,t+blur,start);
    return t1*t2;
}

void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
    vec2 uv=fragCoord/iResolution.xy;
    uv-=.5;
    float time=iTime;
    
    uv.x*=iResolution.x/iResolution.y;
    
    // vec2 center1=vec2(.4*sin(iTime),.2*sin(iTime*2.));
    // vec2 center2=vec2(.08*sin(iTime*.8),.07*sin(iTime*.3));
    
    // float c1=circle(uv,center1,.2,cos(iTime));
    // float c2=circle(uv,center2,.4,.01);
    
    float c1=band(uv.x,-.2,.2,.01);
    
    // fragColor=vec4(uv.x,c1,uv.y,1.);
    // vec3 P,Q;float i,d=1.,a,g;for(;i++<99.&&d>1e-4;g+=d*.5){P=vec3((FC.xy-r*.5)/r.y*g,g);P.zy=P.zy*rotate2D(1.)+vec2(t,3)+sin(t*PI2)*.07;d=min((P.y-abs(fract(P.z)-.5))*.7,1.5-abs(P.x));for(a=2.;a<6e2;a+=a)Q=P*a,Q.xz*=rotate2D(a),d+=abs(dot(sin(Q),Q-Q+1.))/a/7.;}o+=9./i;
    // float t=iTime;vec2 q=(p/iResolution.xy)*mat2(1,-1,.4,1)*mat2(cos(t),-sin(t),sin(t),cos(t));c.rgb=texture(iChannel0,q*sin(length(q*94.))).rgb*4.-abs(q.x);
    vec2 p=FC.xy/r.y+r;for(float i=2.;i<5e2;i*=1.2)p=p.yx+vec2(.1,0)*sin(p*i+t*.3)/sqrt(i);o=vec4(S,S,S,0);
    
}
