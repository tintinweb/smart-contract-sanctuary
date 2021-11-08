// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './Base64.sol';

contract HTML is ERC721, ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;

  constructor() ERC721('HTML', 'HTML') {}

  function safeMint() public onlyOwner {
    _safeMint(msg.sender, _tokenIdCounter.current());
    _tokenIdCounter.increment();
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    string
      memory html = "<!doctype html><head><meta charset=utf-8></head><body id=b><canvas id=a></canvas><style>*{margin:0;padding:0;box-sizing:border-box;}#a{transform:translate(50%,15%);}</style><script>let shader=()=>{let z=`precision mediump float;uniform QiTime,iDate,iTimeDelta;uniform int iFrame;out lowp vec4 fragColor;uniform NiResolution;uniform vec4 iMouse,iLastClick;in NfragCoord;QEL(in Jp,in Jr){Qk0=length(p/r);Qk1=length(p/(r*r));return k0*(k0-1.0)/k1;}QsdSphere(Jp,Qs){return length(p)-s;}QsdCapsule(Jp,Ja,Jb,Qr){Jpa=p - a,ba=b - a;Qh=clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);return length(pa - ba*h)- r;}QsdVerticalCapsule(Jp,Qh,Qr){p.z -=clamp(p.z,-h,h);return length(p)- r;}QsdRoundBox(Jp,Jb,Qr){Jq=abs(p)-b;return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.)-r;}QsdPlane(Jp,vec4 n){return dot(p,n.xyz)+n.w;}Qdot2(in Nv){return dot(v,v);}QBE(Npos,NA,NB,NC){Na=B-A,b=A-2.*B+C,c=a*2.,d=A-pos;Qkk=1./dot(b,b),kx=kk*dot(a,b),ky=kk*(2.*dot(a,a)+dot(d,b))/3.,kz=kk*dot(d,a),res=0.,p=ky-kx*kx,p3=p*p*p,q=kx*(2.*kx*kx-3.0*ky)+kz,h=q*q+4.*p3;if(h>=0.){h=sqrt(h);Nx=(Hh,-h)-q)/2.0,uv=sign(x)*pow(abs(x),H1.0/3.0));Qt=clamp(uv.x+uv.y-kx,0.,1.);res=dot2(d+(c+b*t)*t);}else{Qz=sqrt(-p),v=acos(q/(p*z*2.0))/3.,m=cos(v),n=sin(v)*1.732050808;Jt=clamp(Km+m,-n-m,n-m)*z-kx,0.,1.);res=min(dot2(d+(c+b*t.x)*t.x),dot2(d+(c+b*t.y)*t.y));}return sqrt(res);}QEX(in Jp,in Qsdf,in Qh){Nw=Hsdf,abs(p.z)- h);return min(max(w.x,w.y),0.0)+length(max(w,0.0));}NopIntersect(Na,Nb){return a.x>b.x ? a : b;}Nun(Na,Nb){return a.x<b.x? a : b;}NopSubtract(Nb,Na){return a.x>-b.x? a : H-b.x,b.y);}Nsu(Na,Nb){Qk=5.;Qh=max(k - abs(a.x - b.x),0.0);return Hmin(a.x,b.x)- h*h*0.25/k,a.y);}Nss(Na,Nb){Qk=2.5;Qh=max(k-abs(-a.x-b.x),0.0);return Hmax(-a.x,b.x)+h*h*0.25/k,a.y);}JopSymX(Jp){return Kabs(p.x),p.yz);}vec4 opElongate(Jp,Jh){Jq=abs(p)-h;return vec4(max(q,0.0),min(max(q.x,max(q.y,q.z)),0.0));}QsdCircle(Np,Qr){return length(p)- r;}QsdBox(in Np,in Nb){Nd=abs(p)-b;return length(max(d,0.0))+min(max(d.x,d.y),0.0);}QsdEquilateralTriangle(in Np,Qs){p/=s;p.y+=0.5;const Qk=sqrt(3.0);p.x=abs(p.x)- 1.0;p.y=p.y+1.0/k;if(p.x+k*p.y>0.0)p=Hp.x-k*p.y,-k*p.x-p.y)/2.0;p.x -=clamp(p.x,-2.0,0.0);return(-length(p)*sign(p.y))*s;}NsdTex(Jp,mat3 irot){p.y+=.5;Nd2=Habs(sdCircle((p - K-.06,0.,-.1)).xy,.02))- Y5,1.);Nd3=Habs(sdEquilateralTriangle((p - K.0,Y75,-.1)).xy,.025))- Y5,1.);Nd4=Habs(sdBox((p - K.06,0.,-.1)).xy,H.02)))- Y5,1.);return un(d2,un(d3,d4));}JWI(Jpos,Qdelay,Qdampen){Qdt=iTime - iLastClick.z+delay/5.;Qspeed=10.;return pos+Ksin(dt*speed),cos(dt*speed*1.5),sin(dt*speed/2.))*10.*1./exp(dt/3.)*dampen;}Qblink(Qx){Qt=iTime*2.;Qf1=min(1.,mod(t,12.1));Qf2=smoothstep(0.,.1,f1)-smoothstep(.18,.4,f1);Qf3=min(1.,mod(t,16.4));Qf4=smoothstep(0.,.1,f3)-smoothstep(.18,.4,f3);Qa=max(f2,f4);return(1.-a*.9)*x;}NsdPart1(Jp){Jpx=opSymX(p),d105a=mat3(0.995,-0.097,0.012,-0Y8,0.035,1,-0.097,-0.995,0.034)*(px-WI(K-1.06239,-16.5484,243.493),.3,.8)),d106a=mat3(0.303,0.097,-0.948,0.196,0.967,0.162,0.933,-0.235,0.274)*(px-WI(K26.1815,7.68167,252.861),.3,.8));Nd100=HEL(px-WI(K0.586504,5.25225,264.014),.3,.8),K25.9236,30.7426,31.6057)),100.),d101=HEL(px-WI(K-1.82281,-0.916404,247.748),.3,.8),K25.7758,22.2866,23.238)),101.),d102=HEL(mat3(1,0,0,0,0.934,0.358,0,-0.358,0.934)*(px-WI(K0.612406,-25.6178,252.531),.3,.8)),K4.39584,3.81757,3.081)),102.),d103=HEL(px-WI(K-1.82281,-6.5077,247.748),.3,.8),K22.6827,19.6122,20.4494)),103.),d104=HEL(px-WI(K-1.82281,-12.5913,244.413),.3,.8),K15.4576,13.3652,13.9357)),104.),d105=HEX(d105a,BE(d105a.xy,H-9.56904,-2),H0,2),H9.56904,-2)),12.175)-2.500,105.),d106=HEX(d106a,abs(BE(d106a.xy,H-4.43881,-2),H0,2),H4.43881,-2))-8Y0),0Y0)-2.951,106.),d107=HEL(mat3(0.934,-0.358,0,0.358,0.934,0,0,0,1)*(px-WI(K17.9763,-20.1652,262Y5),.3,.8)),K11.9257,6.7263,9.82366)),107.);return ss(un(d107,d105),su(d106,su(d104,su(d103,su(d102,su(d101,d100))))));}NsdPart2(Jp){Jpx=opSymX(p);Jd200a=mat3(-1,0,-0Y2,0,-1,0.017,-0Y2,0.017,1)*(px-WI(K0.786355,-19.4975,245.33),.3,.8));Nd200=HEX(d200a,abs(BE(d200a.xy,H-7.47535,-5.62342),H0,5.62342),H7.47535,-5.62342))-0Y0),1.907)-3.407,200.);Jd201a=mat3(-1,0,-0Y2,0,-1,0.017,-0Y2,0.017,1)*(px-WI(K-1.01456,-17.3058,240.066),.3,.8));Nd201=HEX(d201a,abs(BE(d201a.xy,H-7.47535,-5.62342),H0,5.62342),H7.47535,-5.62342))-0Y0),0.521)-2.021,201.);return un(d201,d200);}NsdPart3(Jp){Jpx=opSymX(p);Nd300=HEL(mat3(0.908,-0.417,-0.027,0.418,0.909,-0Y1,0.025,-0.011,1)*(px-WI(K13.1017,-15.9358,260.215),.3,.8)),K9.90747,3.95756,blink(8.07248))),300.);return d300;}NsdPart4(Jp){Jpx=opSymX(p);Nd400=HEL(mat3(0.934,-0.354,-0.059,0.353,0.935,-0.012,0.059,-0Y9,0.998)*(px-WI(K13.9803,-19.4975,262.425),.3,.8)),K3.14833,1,blink(4.58567))),400.);return d400;}NsdPart5(Jp){Jpx=opSymX(p),d500a=mat3(0.952,-0.246,-0.181,-0.275,-0.432,-0.859,0.134,0.868,-0.479)*(p-WI(K9.49024,-11.4004,285.236),.3,.8)),d501a=mat3(0.990,-0.101,0.094,0.033,-0.487,-0.873,0.134,0.868,-0.479)*(p-WI(K10.4242,-4.41808,288.979),.3,.8)),d502a=mat3(0.877,-0.246,0.414,0.283,-0.432,-0.856,0.390,0.868,-0.309)*(p-WI(K9.37015,4.34014,292.163),.3,.8)),d503a=mat3(0.481,-0.454,-0.750,-0.876,-0.279,-0.393,-0.030,0.846,-0.532)*(p-WI(K3.95289,-11.0148,285.627),.3,.8)),d504a=mat3(-0.986,0.099,0.136,0.095,-0.342,0.935,0.139,0.934,0.328)*(p-WI(K-15.3942,3.48719,290.256),.3,.8)),d505a=mat3(-0.928,0Y3,-0.371,-0.362,-0.234,0.902,-0.085,0.972,0.218)*(p-WI(K-14.0341,-4.09192,288.172),.3,.8)),d506a=mat3(-0.732,0.158,-0.663,-0.679,-0.235,0.695,-0.046,0.959,0.280)*(p-WI(K-10.2886,-12Y87,284.818),.3,.8)),d507a=mat3(-0.882,-0.135,0.451,0.464,-0.087,0.881,-0.080,0.987,0.139)*(p-WI(K-12.1507,12.3248,290.837),.3,.8)),d508a=mat3(0.761,-0.030,0.648,0.644,0.158,-0.749,-0.080,0.987,0.139)*(p-WI(K7.99985,13.2103,294.419),.3,.8)),d509a=mat3(0.268,-0.030,0.963,0.952,0.158,-0.261,-0.144,0.987,0.071)*(p-WI(K1.29354,18.8074,293.324),.3,.8)),d510a=mat3(-0.411,0.013,0.911,0.896,0.187,0.402,-0.165,0.982,-0.089)*(p-WI(K-5.55681,16.6529,293.503),.3,.8));Nd500=HEX(d500a,BE(d500G00.),d501=HEX(d501a,BE(d501G01.),d502=HEX(d502a,BE(d502G02.),d503=HEX(d503a,BE(d503G03.),d504=HEX(d504a,BE(d504G04.),d505=HEX(d505a,BE(d505G05.),d506=HEX(d506a,BE(d506a.xy,H-13.6787,-9Y152),H0,9Y152),H13.6787,-9Y152)),0.)-6.500,506.),d507=HEX(d507a,BE(d507G07.),d508=HEX(d508a,BE(d508G08.),d509=HEX(d509a,BE(d509G09.),d510=HEX(d510a,BE(d510G10.);return un(d510,un(d509,un(d508,un(d507,un(d506,un(d505,un(d504,un(d503,un(d502,un(d501,d500))))))))));}NsdPart6(Jp){Jpx=opSymX(p);Nd600=HEL(mat3(1,-0.026,-0.014,0.019,0.914,-0.406,0.023,0.405,0.914)*(px-WI(K0.145914,4.48893,228.659),.3,.8)),K10.7028,10.7028,8.07248)),600.);Nd601=HEL(mat3(1,0,0,0,0.940,-0.342,0,0.342,0.940)*(px-WI(K0.196227,11.8302,200.901),.3,.8)),K18.8163,18.8833,23.0296)),601.);Nd602=HEL(mat3(1,0,0,0,0.990,0.139,0,-0.139,0.990)*(px-WI(K-2.616,14.0814,182.726),.3,.8)),K26.2635,26.2232,27.8729)),602.);Nd603=HEL(px-WI(K-2.616,13.7042,164.416),.3,.8),K29.6316,26.9791,21.4635)),603.);Nd604=HEL(mat3(0.990,-0.135,-0.033,0.135,0.991,-0Y5,0.034,-0Y2,1)*(px-WI(K22.1066,4.65802,83.9539),.3,.8)),K15.4641,18.0864,7.46634)),604.);Nd605=HEL(px-WI(K21.4898,-5.71476,83.103),.3,.8),K15.4641,18.563,7.7815)),605.);Jd606a=mat3(0.146,0.150,-0.978,-0.082,-0.983,-0.163,-0.986,0.104,-0.131)*(px-WI(K17.4695,9.42202,126.346),.3,.8));Nd606=HEX(d606a,BE(d606a.xy,H-35.5146,-2.18302),H0,2.18302),H35.5146,-2.18302)),0.)-15.500,606.);Jd607a=mat3(-0.615,0.379,-0.692,0.415,0.901,0.125,0.671,-0.210,-0.711)*(px-WI(K33.2998,0.247313,190.715),.3,.8));Nd607=HEX(d607a,BE(d607a.xy,H-26.8865,-2.18302),H0,2.18302),H26.8865,-2.18302)),0.)-9Y0,607.);Jd608a=mat3(0.333,0.832,-0.443,-0.552,-0.209,-0.807,-0.764,0.514,0.390)*(px-WI(K53.0561,-22.103,169.521),.3,.8));Nd608=HEX(d608a,BE(d608a.xy,H-5.56666,-2),H0,2),H5.56666,-2)),0.)-3Y0,608.);Jd609a=mat3(0.397,0.830,-0.391,-0.454,-0.193,-0.870,-0.798,0.523,0.301)*(px-WI(K57.9487,-16.8941,168.172),.3,.8));Nd609=HEX(d609a,BE(d609a.xy,H-5.56666,-2),H0,2),H5.56666,-2)),0.)-3Y0,609.);Jd610a=mat3(0.443,0.820,-0.364,-0.381,-0.195,-0.904,-0.812,0.539,0.226)*(px-WI(K57.2462,-10.0562,167.632),.3,.8));Nd610=HEX(d610a,BE(d610a.xy,H-5.56666,-2),H0,2),H5.56666,-2)),0.)-3Y0,610.);Jd611a=mat3(-0.048,-0.607,-0.794,-0.867,-0.369,0.334,-0.495,0.704,-0.508)*(px-WI(K45.2879,-17.2162,169.281),.3,.8));Nd611=HEX(d611a,BE(d611a.xy,H-5.56666,-2),H0,2),H5.56666,-2)),0.)-3Y0,611.);Nd612=HEL(px-WI(K-2.28031,-12.9668,175.703),.3,.8),K4.89311,3.39267,2.50321)),612.);return ss(d612,su(d611,su(d610,su(d609,su(d608,su(d607,su(d606,su(d605,su(d604,su(d603,su(d602,su(d601,d600))))))))))));}NsdPart7(Jp){Jpx=opSymX(p);Jd700a=mat3(0.860,-0.079,0.504,0.502,-0.036,-0.864,0.087,0.996,0Y9)*(px-WI(K13.5447,-16.2522,272.557),.3,.8));Nd700=HEX(d700a,abs(BE(d700a.xy,H-6.99786,-2),H0,2),H6.99786,-2))-0Y0),2.091)-3.091,700.);Jd701a=mat3(0.860,-0.079,0.504,0.502,-0.036,-0.864,0.087,0.996,0Y9)*(px-WI(K13.5447,-16.2522,272.557),.3,.8));Nd701=HEX(d701a,abs(BE(d701a.xy,H-6.99786,-2),H0,2),H6.99786,-2))-0Y0),2.091)-3.091,701.);return un(d701,d700);}NevalDistance(Jp){p/=1./100.;p=mat3(1,0,0,0,0,1,0,-1,0)*p;p+=K0,0,256-4);Nd=un(sdPart7(p),un(sdPart6(p),un(sdPart5(p),un(sdPart4(p),un(sdPart3(p),un(sdPart2(p),sdPart1(p)))))));d.x*=1./100.;return d;}void evalMaterial(Nd,Jp,out Jcol,out vec4 mat){switch(int(round(d.y/100.))){case 1:case 6:{Nd2=sdTex(p,mat3(1,0,0,0,0,1,0,-1,0));Nd3=un(d2,H0.,2.));col=int(round(d3.y))==1 ? K204,164,61)/255. :(K155,107,207)/255.);}mat=vec4(5Y0,0.,0.,0.250);break;case 2:case 3:col=K236,236,236)/255.;mat=vec4(100Y0,0.,0.,1.250);break;case 4:case 5:case 7:col=K57,7,75)/255.;mat=vec4(5Y0,0.,0.,0.250);break;default: col=K0,0,0);mat=vec4(0,0,0,0);}}Ngetdist(Jp){return evalDistance(p);}NRayMarch(Jro,Jrd){Qobj=0.;QdO=0.;for(int i=0;i<_max_steps;i++){if(dO>_max_dist)break;Jp=ro+rd*dO;Nds=getdist(p);if(ds.x<_surf_dist){obj=ds.y;break;}dO+=ds.x;}return HdO,obj);}Jgetnormal(Jp){Jn=K0.0);for(int i=zero;i<4;i++){Je=0.5773*(2.0*K(((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);n+=e*getdist(p+e*0Y1).x;}return normalize(n);   }Jgetlight(Jp,Jcolor,Jview,vec4 mat){color.r=pow(color.r,2.2);color.g=pow(color.g,2.2);color.b=pow(color.b,2.2);Qangle=1.;JlightPos=K5.*sin(angle),5.,6.+5.*cos(angle));Jl=normalize(lightPos - p);Jn=getnormal(p);JhalfVec=normalize(l - view);Qdif=max(dot(n,l),0.);Qsha=0.0;sha=1.0;Qmate2x=mat.x;Qmatew=mat.w;Qspe=max(pow(clamp(dot(n,halfVec),0.,1.),mate2x*4.),0.);Jspec=4.0*spe*K2.0)*matew*dif*sha*(0.04+0.96*pow(clamp(1.0+dot(halfVec,view),0.0,1.0),5.0));Jo=color*dif+spec;return Kpow(o.r,1./2.2),pow(o.g,1./2.2),pow(o.b,1./2.2));}void main(){Np=fragCoord*iResolution.xy/iResolution.y;Qangle=sin(iTime);Jro=K1.*sin(angle),0.,1.*cos(angle));Jta=K0,0,0);Jww=normalize(ta - ro);Juu=normalize(cross(ww,K0,1,0)));Jvv=normalize(cross(uu,ww));Jrd=normalize(p.x*uu+p.y*vv+1.5*ww);Nd=RayMarch(ro,rd);Jcolor=K0.5+0.5*cos(iTime+p.xyx+K0,2,4)));if(d.x<_max_dist && d.y>0.){Jdiffuse=K1,1,1);vec4 mat;Jpp=ro+rd*d.x;evalMaterial(d,pp,diffuse,mat);color=getlight(pp,diffuse,rd,mat);}fragColor=vec4(color*K1.11,0.89,0.79),1.);}`;[['G','a.xy,vec2(-13.9973,-9.00152),vec2(0,9.00152),vec2(13.9973,-9.00152)),0.)-6.500,5'],['N','vec2 '],['H','vec2('],['J','vec3 '],['K','vec3('],['Q','float '],['U',');\n'],['Y','.00'],['Z','\nreturn ']].forEach(x=>z=z.replaceAll(...x));return `#version 300 es\n#define _max_steps 50\n#define _max_dist 10.\n#define _surf_dist .001\n#define zero (min(iFrame,0))\n`+z};a.height=a.width=Math.min(innerWidth/2,400);g=a.getContext('webgl2');d=document;onload=()=>{for(i in g){g[i[0]+i[6]]=g[i];};iMouse=[0,0,0,0];lastClick=[0,0,-99];with(g){(oninput=()=>{p=cP();sS(s=cS(35633),'#version 300 es\nin vec2 p;out vec2 fragCoord;void main(){gl_Position=vec4(p,0,1);fragCoord=p;}');compileShader(s);aS(p,s);sS(s=cS(FRAGMENT_SHADER),shader());compileShader(s);aS(p,s);lo(p);ug(p);bf(G=ARRAY_BUFFER,cB());eV(0);vertexAttribPointer(0,2,5120,0,0,0);bD(G,new Int8Array([-3,1,1,-3,1,1]),35044);iFrame=0;o=0;f=new Date()/1e3;d=0;co(0,0,0,1);clear(COLOR_BUFFER_BIT);})();(L=()=>{d=(new Date()/1e3-f);f=new Date()/1e3;uniform1f(gf(p,'iTimeDelta'),d);uniform1f(gf(p,'iTime'),o+=d);uniform1i(gf(p,'iFrame'),iFrame++);uniform1f(gf(p,'iDate'),~~f);uniform4f(gf(p,'iMouse'),iMouse[0],iMouse[1],iMouse[2],iMouse[3]);uniform2f(gf(p,'iResolution'),a.width,a.height);uniform4f(gf(p,'iLastClick'),lastClick[0],lastClick[1],lastClick[2],0);dr(6,0,3);requestAnimationFrame(L);})();};y=0;z=1;onmousedown=onmouseup=(e)=>{y^=1;};let getMousePos=(canvas,evt)=>{let rect=canvas.getBoundingClientRect();return {x:evt.clientX-rect.left,y:evt.clientY-rect.top};};a.onmousemove=(e)=>{if(y){let pos=getMousePos(a,e);iMouse[0]=pos.x,iMouse[1]=pos.y;}};a.onclick=(e)=>{let pos=getMousePos(a,e);iMouse[2]=pos.x,iMouse[3]=pos.y;lastClick[0]=pos.x;lastClick[1]=pos.y;lastClick[2]=o;}}</script></body>";

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "html nft #',
            toString(tokenId),
            '", "description": "testing code.", "image": "data:text/html;base64,',
            Base64.encode(bytes(html)),
            '"}'
          )
        )
      )
    );

    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

pragma solidity ^0.8.4;

library Base64 {
  bytes internal constant TABLE =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return '';

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}