// Upgrade NOTE: replaced 'defined _TRANSLUCENT_SHADOW' with 'defined (_TRANSLUCENT_SHADOW)'

#if !defined(MY_SHADOW)
#define MY_SHADOW

#include "UnityCG.cginc"

#if defined(_RENDERING_CUTOUT)||defined (_RENDERING_FADE) || defined (_RENDERING_TRANSPARENT)
	#if !defined(_SMOOTHNESS_ALBEDO)
		#define SHADOW_UV
	#endif
#endif

#if defined (_TRANSLUCENT_SHADOW)
	#if defined (_RENDERING_FADE) || defined (_RENDERING_TRANSPARENT)
		#define SHADOW_TRANSLUCENT
	#endif
#endif

float _Cutoff;
sampler2D _Albedo;
float4 _Albedo_ST;
sampler3D _DitherMaskLOD;

struct VertexData 
{
	float4 position : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
};

struct InterpolateVertex
{
	#if defined (SHADOW_UV)
		float2 uv : TEXCOORD0;
	#endif
	float4 pos : SV_POSITION;
};

struct InterpolateFrag
{
	#if defined (SHADOW_UV)
		float2 uv : TEXCOORD0;
	#endif
	#if defined (SHADOW_TRANSLUCENT)
		UNITY_VPOS_TYPE  vpos : VPOS;
	#else
		float4 pos : SV_POSITION;
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
	InterpolateVertex vert (VertexData IN)
	{
		InterpolateVertex OUT;
		#if defined (SHADOW_UV)
			OUT.uv = TRANSFORM_TEX(IN.uv, _Albedo);
		#endif
		float4 position = UnityClipSpaceShadowCasterPos(IN.position.xyz, IN.normal);
		OUT.pos = UnityApplyLinearShadowBias(position);

		return OUT;
	}

	half4 frag (InterpolateFrag IN) : SV_TARGET 
	{
		#if defined (SHADOW_UV)
			half Alpha = tex2D(_Albedo , IN.uv).a;
			#if defined(SHADOW_TRANSLUCENT)
				float Dither = tex3D(_DitherMaskLOD, float3(IN.vpos.xy*0.25, 0.9375 * Alpha)).a;
				clip(Dither-0.01);
			#else
				clip(Alpha - _Cutoff);
			#endif
			
		#endif
		return 0;
	}
#endif