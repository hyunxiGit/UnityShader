#if !defined(MYLIGHTING)
#define MYLIGHTING

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

#if defined(FOG_LINEAR)||defined(FOG_EXP)||defined(FOG_EXP2)
    #define FOG_ON
    #if !defined(FOG_DIS)
        #define FOG_DEPTh
    #endif
#endif

sampler2D _MainTex;
sampler2D _Normal;
sampler2D _MetalicMap;
sampler2D _EmissionMap;
sampler2D _OcclusionMap;
sampler2D _DetailAlbedoMap;
sampler2D _DetailMaskMap;
sampler2D _DetailNormalMap;

sampler2D _DisplacementMap;
float _displacementStrength;

half4 _Color;
float _Cutoff;
float4 _Emission;
float4 _MainTex_ST;
float4 _DetailAlbedoMap_ST;
float _Metalic;
float _Smoothness;
float _OcclusionStrength;

struct VIN
{
    float4 vertex : POSITION ;
    float3 nor : NORMAL;
    float4 tan : TANGENT;
    float2 uv : TEXCOORD0 ; 
    #if defined (LIGHTMAP_ON)
        float2 uv1 : TEXCOORD1;
    #endif
};

struct VOUT
{
    float4 pos : SV_POSITION ;
    float3 nor : NORMAL;
    float2 uv : TEXCOORD0 ;
    #if defined (FOG_DEPTh)
        float4 pos_w : TEXCOORD1;
    #else
        float3 pos_w : TEXCOORD1;
    #endif
    float3 tan : TEXCOORD2;
    float3 bi  : TEXCOORD3;
    UNITY_SHADOW_COORDS(4)
    #if defined(VERTEXLIGHT_ON)
        float3 Vc : TEXCOORD5 ;
    #endif
    #if defined (LIGHTMAP_ON)
        float2 uv1 : TEXCOORD6;
    #endif
};

struct FOUT
{
    #if defined (DEFERRED_PASS)
        float4 gbuffer0 : SV_TARGET0;
        float4 gbuffer1 : SV_TARGET1;
        float4 gbuffer2 : SV_TARGET2;
        float4 gbuffer3 : SV_TARGET3;
    
    #else
        float4 color : SV_TARGET;
    #endif 
};

void vertexLight(inout VOUT IN)
{
    #if defined(VERTEXLIGHT_ON)
        IN.Vc = Shade4PointLights (
        unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
        unity_LightColor[0].xyz, unity_LightColor[1].xyz, unity_LightColor[2].xyz, unity_LightColor[3].xyz,
        unity_4LightAtten0,
        IN.pos_w, IN.nor);
    #endif
}

VOUT vert(VIN v)
{
    VOUT OUT;
    UNITY_INITIALIZE_OUTPUT(VOUT, OUT);
    OUT.pos = UnityObjectToClipPos(v.vertex);
    OUT.nor = UnityObjectToWorldNormal(v.nor);
    OUT.uv = v.uv;
    #if defined (LIGHTMAP_ON)
        OUT.uv1 = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
    #endif
    OUT.pos_w = mul(unity_ObjectToWorld , v.vertex);
    #if defined (FOG_DEPTh)
         OUT.pos_w.w = OUT.pos.z;
    #endif
    OUT.tan = UnityObjectToWorldDir(v.tan.xyz); 
    OUT.bi = normalize(cross(OUT.nor , OUT.tan.xyz) * v.tan.w * unity_WorldTransformParams.w); 
    UNITY_TRANSFER_SHADOW(OUT, uv1);
    vertexLight (OUT);
    return OUT;
} 

float FadeShadow(VOUT IN, float lightAtt)
{
    #if HANDLE_SHADOWS_BLENDING_IN_GI
    // UNITY_LIGHT_ATTENUATION doesn't fade shadows for us.
    float viewZ = dot(_WorldSpaceCameraPos - IN.pos_w , UNITY_MATRIX_V[2].xyz);
    half shadowFadeDistance = UnityComputeShadowFadeDistance(IN.pos_w , viewZ);
    float shadowFade = UnityComputeShadowFade(shadowFadeDistance);
    lightAtt = saturate (lightAtt + shadowFade);
    #endif
    return lightAtt;
}

UnityLight dLight(VOUT IN)
{
    UnityLight l;

    #if defined (DEFERRED_PASS)
        l.dir = float3(0,1,0);
        l.color = 0;
    #else
        l.dir = _WorldSpaceLightPos0;
        #if defined(SPOT)|| defined(POINT)
            l.dir = normalize(l.dir - IN.pos_w);
        #endif
        UNITY_LIGHT_ATTENUATION(attenuation , IN , IN.pos_w.xyz);
        attenuation = FadeShadow (IN,attenuation);
        //l.ndotl = DotClamped(IN.nor , l.dir);
        l.color = _LightColor0 * attenuation;
    #endif
    return l;
}

UnityIndirect iLight(VOUT IN , half3 Rd, float Ro , half Oc)
{
    UnityIndirect l;
    l.diffuse = 0;
    l.specular = 0;
    #if defined (VERTEXLIGHT_ON)
        l.diffuse += IN.Vc;
    #endif
    #if defined (FORWARD_BASE_PASS) || defined (DEFERRED_PASS)
        l.diffuse += ShadeSH9 (half4(IN.nor,1));
    
        #if defined (LIGHTMAP_ON)
            l.diffuse = DecodeLightmap (UNITY_SAMPLE_TEX2D (unity_Lightmap,IN.uv1));
            #if defined (DIRLIGHTMAP_COMBINED)
                float4 lightmapDirection = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd,unity_Lightmap,IN.uv1);
                l.diffuse = DecodeDirectionalLightmap(l.diffuse , lightmapDirection , IN.nor);
            #endif
        #endif

        Unity_GlossyEnvironmentData envData;
        envData.roughness = Ro;
        envData.reflUVW = BoxProjectedCubemapDirection (Rd, IN.pos_w, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
        half3 s0 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE(unity_SpecCube0) , unity_SpecCube0_HDR , envData);
       
        half interpo = unity_SpecCube0_BoxMin.w ;

        #if UNITY_SPECCUBE_BLENDING
            UNITY_BRANCH
            if (interpo <0.999)
            {
                envData.reflUVW = BoxProjectedCubemapDirection (Rd, IN.pos_w, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
                half3 s1 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1 , unity_SpecCube0) , unity_SpecCube1_HDR , envData);

                l.specular = lerp (s0 , s1 , interpo);    
            }
            else
            {
                l.specular = s0 ;
            }
        #else
            l.specular = s0 ;
        #endif

        l.diffuse *= Oc;
        l.specular *= Oc;

        #if defined(DEFERRED_PASS) && UNITY_ENABLE_REFLECTION_BUFFERS
                l.specular = 0;
        #endif
    #endif
        
    return l;
}

half getMetalic(float2 uv0)
{
    half Me;
    #if defined (_METALIC_MAP)
        Me = tex2D(_MetalicMap, uv0).r;
    #else
        Me = _Metalic;
    #endif
    return Me;
}

half getOcclusion(float2 uv)
{

    half Oc;
    #if defined (_OCCLUSIONMAP)
        Oc = tex2D(_OcclusionMap , uv).g;
        Oc = lerp (1, Oc , _OcclusionStrength);
    #else
        Oc = 1;
    #endif
    return Oc;
}

half getSmooth(float2 uv0)
{
    half Sm = _Smoothness;
    
    #if defined (_SMOOTHNESS_ALBEDO)
       Sm = tex2D(_MainTex, uv0).a;
    #elif defined (_SMOOTHNESS_METALIC)
       Sm = tex2D(_MetalicMap, uv0).a;
    #endif
    return Sm;
}

half4 getEmissive(float2 uv)
{
    half4 col = half4(0,0,0,0);
    #if defined (FORWARD_BASE_PASS) || defined (DEFERRED_PASS)
        #if defined (_EMISSION_MAP)
            col = tex2D(_EmissionMap, uv);
        #else
            col = _Emission;
        #endif
    #endif
    return col;
}

half getDetailMask(float2 uv)
{
    half mask;
    #if defined(_DETAIL_MASK)
        return tex2D(_DetailMaskMap , uv).a;
    #else
        return 1;
    #endif
}

half3 getAlbedo( float2 uv0 , float2 uv1)
{
    half3 Al = tex2D(_MainTex, uv0) * _Color.xyz;
    #if defined (_DETAIL_ALBEDO)
        half3 AlDe = Al * tex2D(_DetailAlbedoMap , uv1);
        Al = lerp(Al ,AlDe , getDetailMask(uv0));
    #endif
    return Al;
}

half3 getnormal(float2 uv0 , float2 uv1 , VOUT IN)
{
    half3 Nm = UnpackScaleNormal(tex2D(_Normal, uv0), 0.5).xzy;
    #if defined (_DETAIL_NORMAL)
        half3 NmDe = UnpackScaleNormal(tex2D(_DetailNormalMap , uv1) , 0.5).xyz;
        NmDe = lerp ( half3 (0,1,0), NmDe , getDetailMask(uv0));
        Nm = BlendNormals(Nm , NmDe);
    #endif
    
        half3 No = normalize(IN.nor * Nm.y + IN.tan * Nm.x + IN.bi * Nm.z);
    return No;
}

half getAlpha(float2 uv)
{
    half a = 1;
    #if !defined(_SMOOTHNESS_ALBEDO)
        a = tex2D(_MainTex, uv).a * _Color.a;
    #endif
    return a;
}

void applyDisplace(inout float2 uv0 , inout float2 uv1 , inout half3 Vd, VOUT IN)
{   
    
    half maxScale = 0.5f;
    half scale = tex2D(_DisplacementMap, uv0).r * _displacementStrength * maxScale;
    //C cam pos
    //A original spot
    //M scale to spot
    half3 CA = normalize(Vd);
    half3 MA = CA*scale;
    //(M is real place we need to sacmple)
    half3 CM = CA - MA;
    //update view vector
    Vd = normalize(CM);
    //create matrix convert world to tangent
    float3x3 WtT= transpose(float3x3(IN.tan ,  IN.bi ,IN.nor));
    MA = mul(MA,WtT);
    //or we can use colume major mul(M,v) instead, then we don't need to transpose
    //because the colume major will transpose the matrix for us
    //float3x3 WtT= float3x3(IN.tan ,  IN.bi ,IN.nor);
    //MA = mul(WtT,MA);
    uv0 += MA;
    //uv1 += MA;
}

void addFog(inout half4 col , VOUT IN)
{
    half fogScale;
    float fogCoord;
    half3 collor = unity_FogColor;
    #if defined (FOG_ON)
        #if defined (FOG_DEPTh)
            fogCoord = UNITY_Z_0_FAR_FROM_CLIPSPACE(IN.pos_w.w);
            //fogCoord = IN.pos.w;
            //collor = half3(1,1,1);
        #else
            fogCoord = length( _WorldSpaceCameraPos - IN.pos_w);
        #endif
        UNITY_CALC_FOG_FACTOR_RAW(fogCoord);
        col.rgb = lerp (collor, col.rgb, saturate(unityFogFactor));
    #endif
}

FOUT frag(VOUT IN)
{
    FOUT buff;
    half4 col;

    float2 uv0 = TRANSFORM_TEX(IN.uv, _MainTex);
    float2 uv1 = TRANSFORM_TEX(IN.uv, _DetailAlbedoMap);
    //half3 Vd = normalize(_WorldSpaceCameraPos - IN.pos_w);
    half3 Vd = _WorldSpaceCameraPos - IN.pos_w;

    applyDisplace(uv0,uv1 , Vd, IN);

    half4 Em = getEmissive(uv0);
    half3 Al = getAlbedo(uv0,uv1);
    half Alpha = getAlpha(uv0);


    #if defined(_RENDERING_CUTOUT)
        clip(Alpha - _Cutoff);
    #endif
    _Cutoff = 1;
    half3 No = getnormal(uv0 , uv1 , IN);
    float3 Ntemp = No;
    IN.nor = No*4;

    float Me;
    half Oc;
    half3 Sp;
    half Omr;
    half Sm = getSmooth(uv0);
    half Ro = 1-Sm;   

    Me = getMetalic(uv0);
    
    half3 Rd = reflect(-Vd , No);

    Oc = getOcclusion(uv0);

    #if defined(_RENDERING_TRANSPARENT)
        Al *=Alpha;
        Omr = OneMinusReflectivityFromMetallic(Me);
        Alpha = 1-Omr + Alpha*Omr;
    #endif

    half3 Di = DiffuseAndSpecularFromMetallic(Al, Me, Sp, Omr);
    UnityLight dL = dLight(IN);
    UnityIndirect iL = iLight(IN , Rd , Ro , Oc);

    col = UNITY_BRDF_PBS(Di, Sp, Omr, Sm ,No , Vd, dL, iL) +Em ;
   
    #if defined (_RENDERING_FADE) ||defined (_RENDERING_TRANSPARENT)
        col.a = Alpha;
    #endif
   
    #if defined (DEFERRED_PASS)
        buff.gbuffer0.rgb = Di;
        buff.gbuffer0.a = Oc;

        buff.gbuffer1.rgb = Sp;
        buff.gbuffer1.a = Sm;
        buff.gbuffer2 = float4(No *0.5+0.5 ,1);
        #if !defined(UNITY_HDR_ON)
            col.rgb = exp2(-col.rgb);
        #endif 
        buff.gbuffer3 = col;
    #else
        buff.color = col;
        addFog(buff.color , IN);
    #endif

    return buff;
}
#endif