#if !defined(MY_SHADOW)
	#define MY_SHADOW

#include "UnityCG.cginc"


struct VertexData {
	float4 position : POSITION;
	float3 normal : NORMAL;
};

#if defined(SHADOWS_CUBE)
struct VOUT
{
	float4 pos : SV_POSITION;
	float3 lightVec : TEXCOORD0;
};

VOUT vert (VertexData v)  {
	VOUT OUT;
	OUT.pos = UnityObjectToClipPos(v.position);
	OUT.lightVec = mul(unity_ObjectToWorld , v.position).xyz -  _LightPositionRange.xyz;
	return OUT;
	}

	half4 frag (VOUT IN) : SV_TARGET 
	{
		float depth = length(IN.lightVec) + unity_LightShadowBias.x;
		depth *=_LightPositionRange.w;
		return UnityEncodeCubeShadowDepth(depth);
	}

#else
	float4 vert (VertexData v) : SV_POSITION {
		float4 position =
			UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
		return UnityApplyLinearShadowBias(position);
	}

	half4 frag () : SV_TARGET {
		return 0;
	}
#endif

#endif