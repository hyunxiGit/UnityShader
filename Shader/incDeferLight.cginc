#if !defined (INC_DEFER_LIGHT)
#define INC_DEFER_LIGHT
struct Vin
{
    float4 pos : POSITION;
};

struct Vout
{
    float4 pos : SV_POSITION;
};
struct Fout
{
    float4 col : SV_Target;
};

Vout vert (Vin IN)
{
    Vout OUT;
    OUT.pos = UnityObjectToClipPos(IN.pos);
    return OUT;
}

Fout frag (Vout IN)
{
    Fout OUT;
    OUT.col = half4(0,0,0,0);
    return OUT;
}
#endif