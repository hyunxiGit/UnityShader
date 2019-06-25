#if !defined (INC_DEFER_LIGHT)
#define INC_DEFER_LIGHT
#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"

UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
struct Vin
{
    float4 pos : POSITION;
    float3 nor : NORMAL;
};

struct Vout
{
    float4 pos : SV_POSITION;
    float4 uv : TEXCOORD0;
    float3 ray_n : TEXCOORD1;
};
struct Fout
{
    float4 col : SV_Target;
};

Vout vert (Vin IN)
{
    Vout OUT;
    OUT.pos = UnityObjectToClipPos(IN.pos);
    OUT.uv = ComputeScreenPos(OUT.pos);
    OUT.ray_n = IN.nor;
    return OUT;
}

Fout frag (Vout IN)
{
    Fout OUT;
    float2 uv = IN.uv.xy/IN.uv.w;

    float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv.xy));
    
    float3 ray_f = IN.ray_n * _ProjectionParams.z /_ProjectionParams.y;
    
    float3 pos_v = depth * ray_f;
    float3 pos_w = mul(unity_CameraToWorld , float4(pos_v,1));

    OUT.col = half4(pos_w,1);
    return OUT;
}
#endif