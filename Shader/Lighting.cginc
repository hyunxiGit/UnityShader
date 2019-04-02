#if !defined(MYLIGHTING)
#define MYLIGHTING

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

sampler2D _Albedo;
sampler2D _Normal;
sampler2D _MetalicMap;
sampler2D _EmissionMap;
sampler2D _OcclusionMap;
float4 _Emission;
float4 _Albedo_ST;
float _Metalic;
float _Smoothness;
float _OcclusionStrength;


struct VIN
{
    float4 vertex : POSITION ;
    float3 nor : NORMAL;
    float4 tan : TANGENT;
    float2 uv : TEXCOORD0 ; 
};

struct VOUT
{
    float4 pos : SV_POSITION ;
    float3 nor : NORMAL;
    float2 uv : TEXCOORD0 ;
    float3 pos_w : TEXCOORD1;
    float3 tan : TEXCOORD2;
    float3 bi  : TEXCOORD3;
    SHADOW_COORDS(4)
    #if defined(VERTEXLIGHT_ON)
        float3 Vc : TEXCOORD5 ;
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
    OUT.pos = UnityObjectToClipPos(v.vertex);
    OUT.nor = UnityObjectToWorldNormal(v.nor);
    OUT.uv = v.uv;
    OUT.pos_w = mul(unity_ObjectToWorld , v.vertex);
    OUT.tan = UnityObjectToWorldDir(v.tan.xyz); 
    OUT.bi = normalize(cross(OUT.nor , OUT.tan.xyz) * v.tan.w * unity_WorldTransformParams.w); 
    TRANSFER_SHADOW(OUT);
    vertexLight (OUT);
    return OUT;
} 
UnityLight dLight(VOUT IN)
{
    UnityLight l;
    
    l.dir = _WorldSpaceLightPos0;
    #if defined(SPOT)|| defined(POINT)
        l.dir = normalize(l.dir - IN.pos_w);
    #endif
    UNITY_LIGHT_ATTENUATION(attenuation , IN , IN.pos_w);
    l.ndotl = DotClamped(IN.nor , l.dir);
    l.color = _LightColor0 * attenuation;
    return l;
}

UnityIndirect iLight(VOUT IN , half3 Rd, float Ro , half Oc)
{
    UnityIndirect l;
    l.diffuse = 0;
    #if defined (VERTEXLIGHT_ON)
        l.diffuse += IN.Vc;
    #endif
    #if defined (FORWARD_BASE_PASS)
        l.diffuse += ShadeSH9 (half4(IN.nor,1));
    #endif
    //l.specular = 0;
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

    l.specular *= Oc;
    l.specular *= Oc;
        
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
       Sm = tex2D(_Albedo, uv0).a;
    #elif defined (_SMOOTHNESS_METALIC)
       Sm = tex2D(_MetalicMap, uv0).a;
    #endif
    return Sm;
}

half4 getEmissive(float2 uv)
{
    half4 col = half4(0,0,0,0);
    #if defined (FORWARD_BASE_PASS)
        #if defined (_EMISSION_MAP)
            col = tex2D(_EmissionMap, uv);
        #else
            col = _Emission;
        #endif
    #endif
    return col;
}

half4 frag(VOUT IN) : SV_TARGET
{
    half4 col;

    float2 uv0 = TRANSFORM_TEX(IN.uv, _Albedo);
    half4 Em = getEmissive(uv0);
    half3 Al = tex2D(_Albedo, uv0);
    half3 Nm = UnpackScaleNormal(tex2D(_Normal, uv0), 0.5).xzy;
    half3 No = normalize(IN.nor * Nm.y + IN.tan * Nm.x + IN.bi * Nm.z);
    IN.nor = No;

    float Me;
    half Oc;
    half3 Sp;
    half Omr;
    half Sm = getSmooth(uv0);
    half Ro = 1-Sm;   

    Me = getMetalic(uv0);
    half3 Vd = normalize(_WorldSpaceCameraPos - IN.pos_w);
    half3 Rd = reflect(-Vd , No);

    Oc = getOcclusion(uv0);

    half3 Di = DiffuseAndSpecularFromMetallic(Al, Me, Sp, Omr);
    UnityLight dL = dLight(IN);
    UnityIndirect iL = iLight(IN , Rd , Ro , Oc);

    col = UNITY_BRDF_PBS(Di, Sp, Omr, Sm ,No , Vd, dL, iL) +Em ;
    return col;
}
#endif