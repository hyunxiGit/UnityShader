#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

sampler2D _Albedo;
sampler2D _Normal;
float4 _Albedo_ST;
float _Metalic;
float _Roughness;

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

UnityIndirect iLight(VOUT IN)
{
    UnityIndirect l;
    l.diffuse = 0;
    #if defined (VERTEXLIGHT_ON)
        l.diffuse += IN.Vc;
    #endif
    #if defined (FORWARD_BASE_PASS)
        l.diffuse += ShadeSH9 (half4(IN.nor,1));
    #endif

    l.specular = 0;
    return l;
}

half4 frag(VOUT IN) : SV_TARGET
{
    float2 uv0 = TRANSFORM_TEX(IN.uv, _Albedo);
    half3 Al = tex2D(_Albedo, uv0);
    half3 Nm = UnpackScaleNormal(tex2D(_Normal, uv0), 0.5).xzy;
    half3 No = normalize(IN.nor * Nm.y + IN.tan * Nm.x + IN.bi * Nm.z);
    IN.nor = No;

    float Me = _Metalic;
    float Ro = _Roughness;
    half3 Sp;
    half Omr;
    half Sm = 1- Ro;
    
    half3 Vd = normalize(_WorldSpaceCameraPos - IN.pos_w);
    half3 Di = DiffuseAndSpecularFromMetallic(Al, Me, Sp, Omr);
    UnityLight dL = dLight(IN);
    UnityIndirect iL = iLight(IN);
    
    return UNITY_BRDF_PBS(Di, Sp, Omr, Sm ,No , Vd, dL, iL);
}