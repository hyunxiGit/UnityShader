#if ! defined(MY_LIGHTING)
#define MY_LIGHTING
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

sampler2D _Albedo;
float4 _Albedo_ST;
sampler2D _Normal;
float _Metalic;
float _Roughness;

sampler2D _Detail;
float4 _Detail_ST;

struct VIN
{
    float4 pos : POSITION;
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
    #if defined (SHADOWS_SCREEN)
        SHADOW_COORDS(4)
    #endif
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

VOUT vert(VIN IN)
{
    VOUT OUT;
    OUT.pos = UnityObjectToClipPos(IN.pos);
    OUT.pos_w = mul(unity_ObjectToWorld , IN.pos);
    OUT.uv = IN.uv;
    OUT.nor = UnityObjectToWorldNormal(IN.nor);
    OUT.tan = UnityObjectToWorldDir(IN.tan.xyz);
    OUT.bi = normalize(cross( OUT.nor, OUT.tan) * IN.tan.w * unity_WorldTransformParams.w);
    #if defined (SHADOWS_SCREEN)
        TRANSFER_SHADOW(OUT);
    #endif
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
UnityIndirect IndirectLight(VOUT IN)
{
    UnityIndirect l;
    l.diffuse = 0;
    l.specular = 0; 
    #if defined (VERTEXLIGHT_ON)
        l.diffuse += IN.vLightCol;
    #endif
    #if defined (FORWARD_BASE_PASS)
        l.diffuse += ShadeSH9 (half4(IN.nor,1));
    #endif
    return l;
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
    float Ro = _Roughness;
    float Sm = 1-Ro;
    half3 Sp ;
    half OMR ;
    float3 Vd = normalize(_WorldSpaceCameraPos - IN.pos_w);
    UnityLight Dl = DirectLight (IN);
    UnityIndirect Gi = IndirectLight (IN);

    Di = DiffuseAndSpecularFromMetallic(_AlbedoMap, Me, Sp, OMR);
    col = UNITY_BRDF_PBS(Di, Sp, OMR, Sm, No, Vd, Dl, Gi);

    return (col);
}
#endif