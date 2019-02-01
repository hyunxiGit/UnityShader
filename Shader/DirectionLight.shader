Shader "Custom/DirectionLight"
{
	Properties
	{
		_Albedo("Albedo",2d) = "white"{}
		_Tint("Albedo Tint", color) = (1,1,1,1)
	}

	SubShader
	{
		Pass 
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityPBSLighting.cginc"

			sampler2D _Albedo;
			float4 _Albedo_ST;
			float4 _Tint;

			struct Vin
			{
				float4 pos : POSITION;
				float3 nor : NORMAL;
				float2 uv  : TEXCOORD0;
			};
			struct Vout
			{
				float4 pos : SV_POSITION;
				float3 nor : NORMAL;
				float2 uv  : TEXCOORD0;
			};
			Vout vert(Vin IN)
			{
				Vout OUT;
				OUT.pos = UnityObjectToClipPos(IN.pos);
				OUT.nor = normalize(UnityObjectToWorldNormal(IN.nor));
				OUT.uv = IN.uv;
				return OUT;
			}
			float4 frag(Vout IN):SV_target
			{
				float4 col = float4(1,0,0,1);
				IN.uv = TRANSFORM_TEX(IN.uv, _Albedo);
				col = tex2D(_Albedo, IN.uv) * _Tint;

				UnityLight iLight;
				iLight.dir = _WorldSpaceLightPos0.xyz ;
				iLight.color = float4(_LightColor0.rgb, 1);
				iLight.ndotl = DotClamped(iLight.dir, IN.nor);
				
				return float4 (col.rgb * iLight.ndotl * iLight.color.rgb , 1);
			}
			ENDCG
		}
		
	}
}
