// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#if !defined(MYSHADOW)
#define MYSHADOW
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

	OUT. pos = UnityClipSpaceShadowCasterPos(IN.pos.xyz, IN.nor);
	//OUT. pos = UnityObjectToClipPos(IN.pos);
	OUT.pos = UnityApplyLinearShadowBias(OUT. pos);
	return OUT;
}


float4 frag(VOUT IN) : SV_Target
{
	return 0;
}

#endif