#if ! defined(MY_SHADOW)
#define MY_SHADOW
#include "UnityCG.cginc"
struct VIN
{
	float4 pos : POSITION;
	float3 nor : NORMAL;
};

struct VOUT
{
	float4 pos : SV_POSITION;
};

VOUT vert(VIN IN)
{
	VOUT OUT;
	OUT.pos = UnityClipSpaceShadowCasterPos(IN.pos, IN.nor);
	return OUT;
}

half4 frag() : SV_TARGET
{
	return 0;
}
#endif