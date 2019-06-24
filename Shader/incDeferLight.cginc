#if !defined (INC_DEFER_LIGHT)
#define INC_DEFER_LIGHT
#include "UnityCG.cginc"
struct Vin
{
    float4 pos : POSITION;
};

struct Vout
{
    float4 pos : SV_POSITION;
    float4 uv : TEXCOORD0;
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
    return OUT;
}

Fout frag (Vout IN)
{
    Fout OUT;
    float2 uv = IN.uv.xy/IN.uv.w;
    OUT.col = half4(uv.xy,0,0.1);
    return OUT;
}
#endif