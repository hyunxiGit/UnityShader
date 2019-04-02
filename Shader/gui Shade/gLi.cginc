// Upgrade NOTE: replaced 'defined _METALIC_MAP' with 'defined (_METALIC_MAP)'

#if ! defined(MY_LIGHTING)
#define MY_LIGHTING
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

sampler2D _Albedo;
float4 _Albedo_ST;
sampler2D _MetalicMap; 
sampler2D _Normal;
float _Metalic;
float _Roughness;

sampler2D _Detail;
float4 _Detail_ST;

struct VIN
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0; 
    float3 nor : NORMAL;
    float4 tan : TANGENT;
};

struct VOUT
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0 ;
    float3 pos_w : TEXCOORD1;
    float3 tan : TEXCOORD2;
    float3 bi : TEXCOORD3;
    float3 nor : NORMAL;
    SHADOW_COORDS(4)
    #if defined (VERTEXLIGHT_ON)
        float3 vLightCol : TEXCOORD5; 
    #endif
};

void vertexLight(inout VOUT IN)
{
    #if defined (VERTEXLIGHT_ON)
        IN.vLightCol =  Shade4PointLights( unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,unity_LightColor[0].xyz, unity_LightColor[1].xyz, unity_LightColor[2].xyz, unity_LightColor[3].xyz,unity_4LightAtten0,IN.pos_w, IN.nor);
    #endif
}

VOUT vert(VIN v)
{
    VOUT OUT;
    OUT.pos = UnityObjectToClipPos(v.vertex);
    OUT.pos_w = mul(unity_ObjectToWorld , v.vertex);
    OUT.uv = v.uv;
    OUT.nor = UnityObjectToWorldNormal(v.nor);
    OUT.tan = UnityObjectToWorldDir(v.tan.xyz);
    OUT.bi = normalize(cross( OUT.nor, OUT.tan) * v.tan.w * unity_WorldTransformParams.w);
    TRANSFER_SHADOW(OUT);
    #if defined (VERTEXLIGHT_ON)
        vertexLight(OUT);
    #endif
    return OUT;
}
UnityLight DirectLight(VOUT IN )
{
    UnityLight l;
    l.dir = _WorldSpaceLightPos0;
    #if defined(POINT)|| defined (SPOT)
        l.dir = normalize(l.dir - IN.pos_w);
    #endif
    UNITY_LIGHT_ATTENUATION(attenuation , IN , IN.pos_w);
    l.color = _LightColor0 * attenuation;
    l.ndotl = DotClamped(IN.nor , l.dir);
    return l;
}
UnityIndirect IndirectLight(VOUT IN, float3 Rv , float Ro)
{
    UnityIndirect l;
    l.diffuse = 0;
    l.specular = 0; 
    #if defined (VERTEXLIGHT_ON)
        l.diffuse += IN.vLightCol;
    #endif
    #if defined (FORWARD_BASE_PASS)
        l.diffuse += ShadeSH9 (half4(IN.nor,1));

        Rv = BoxProjectedCubemapDirection (Rv, IN.pos_w, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);

        Unity_GlossyEnvironmentData glossIn;
        glossIn. roughness = Ro;
        glossIn. reflUVW = Rv;

        half3 s0= Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube0,unity_SpecCube0), unity_SpecCube0_HDR, glossIn);

        float Interpolator = unity_SpecCube0_BoxMin.w ; 

        #if UNITY_SPECCUBE_BLENDING
            UNITY_BRANCH
            if (Interpolator <0.99f)
            {
                    Rv = BoxProjectedCubemapDirection (Rv, IN.pos_w, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
                    glossIn.reflUVW = Rv;
                    half3 s1= Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0), unity_SpecCube1_HDR, glossIn);

                    l.specular = lerp(s0, s1 , unity_SpecCube0_BoxMin.w);    
            }
            else
            {
                    l.specular = s0;   
            }
        #else
           l.specular = s0;
        #endif 
        
    #endif

    return l;
}

half getMetalic(float2 uv)
{
    half m;
    #if defined (_METALIC_MAP)
        m = tex2D(_MetalicMap , uv).r;
    #else
        m = _Metalic;
    #endif
    
    return m;
}

half4 frag(VOUT IN):SV_TARGET
{
    half4 col;

    float2 uv0 = TRANSFORM_TEX(IN.uv , _Albedo);
    half3 _AlbedoMap = tex2D(_Albedo , uv0);
    half3 _NormalMap = UnpackScaleNormal(tex2D(_Normal, uv0), 0.5).xzy;

    float2 uv1 = TRANSFORM_TEX(IN.uv , _Detail);
    half3 _DetailMap = UnpackScaleNormal(tex2D(_Detail, uv1), 0.5).xzy;

    float3 NM = normalize(float3 (_NormalMap.x + _DetailMap.x , _NormalMap.y + _DetailMap.y , _NormalMap.z + _DetailMap.z ));


    float3 No = normalize(IN.tan * NM.x + IN.nor * NM.y + IN.bi *NM.z);
    half3 Di;
    half Me = _Metalic;
    Me = getMetalic(uv0);
    float Ro = _Roughness;
    float Sm = 1-Ro;
    half3 Sp ;
    half OMR ;
    float3 Vd = normalize(_WorldSpaceCameraPos - IN.pos_w);

    float3 Rv  = reflect(-Vd, No);
    UnityLight Dl = DirectLight (IN);
    UnityIndirect Gi = IndirectLight (IN , Rv , Ro);

    Di = DiffuseAndSpecularFromMetallic(_AlbedoMap, Me, Sp, OMR);
    col = UNITY_BRDF_PBS(Di, Sp, OMR, Sm, No, Vd, Dl, Gi);

    return (col);
}
#endif