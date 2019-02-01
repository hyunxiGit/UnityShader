Shader "Custom/texture"
{
	properties
	{
		_MainTint("tint", Color) = (1,1,1,1)
		_MainTexture("albedo", 2D) = "white"{}
	}
	SubShader
	{
		pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			float4 _MainColor;
			sampler _MainTexture;
			float4 _MainTexture_ST;

			struct Vin
			{
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
			};
			struct Vout
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			Vout vert(Vin IN)
			{
				Vout OUT;
				OUT.pos = UnityObjectToClipPos(IN.pos);
				OUT.uv = IN.uv;
				return OUT;
			}

			float4 frag(Vout IN) : SV_TARGET
			{
				float4 col = _MainColor;
				IN.uv = TRANSFORM_TEX(IN.uv, _MainTexture);
				return tex2D(_MainTexture, IN.uv);
			}

			ENDCG
		}
	}
	
}
