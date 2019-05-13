#if !defined(MY_SHADOW)
#define MY_SHADOW

#include "UnityCG.cginc"

	#if defined(_RENDERING_CUTOUT) && !defined(_SMOOTHNESS_ALBEDO)
		#define SHADOW_UV
	#endif

sampler2D _Albedo;
float4 _Albedo_ST;

struct VertexData 
{
	float4 position : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
};

struct FragmentData
{
	float4 pos : SV_POSITION;
	#if defined (SHADOW_UV)
		float2 uv : TEXCOORD0;
	#endif
};

// #if defined(SHADOWS_CUBE)
// struct VOUT
// {
// 	float4 pos : SV_POSITION;
// 	float3 lightVec : TEXCOORD0;
// };

// VOUT vert (VertexData v)  {
// 	VOUT OUT;
// 	OUT.pos = UnityObjectToClipPos(v.position);
// 	OUT.lightVec = mul(unity_ObjectToWorld , v.position).xyz -  _LightPositionRange.xyz;
// 	return OUT;
// 	}

// 	half4 frag (VOUT IN) : SV_TARGET 
// 	{
// 		float depth = length(IN.lightVec) + unity_LightShadowBias.x;
// 		depth *=_LightPositionRange.w;
// 		return UnityEncodeCubeShadowDepth(depth);
// 	}

// #else
	FragmentData vert (VertexData IN)
	{
		FragmentData OUT;
		float4 position = UnityClipSpaceShadowCasterPos(IN.position.xyz, IN.normal);
		OUT.pos = UnityApplyLinearShadowBias(position);
		#if defined (SHADOW_UV)
			OUT.uv = IN.uv;
		#endif
		return OUT;
	}

	half4 frag (FragmentData IN) : SV_TARGET 
	{
		#if defined (SHADOW_UV)
			float2 uv = TRANSFORM_TEX(IN.uv, _Albedo);
			half Alpha = tex2D(_Albedo , uv).a;
			clip(Alpha - 0.5);
		#endif

		return 0;
	}
#endif