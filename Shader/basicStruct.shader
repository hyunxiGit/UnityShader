Shader "Custom/basicStruct"
{
	Properties 
	{
		//_Maintexture("texture",2D) = "White"{}
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		pass
		{
			Tags {
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			struct vIn
			{
				float4 pos : POSITION;
			};
			struct pIn
			{
				float4 pos : SV_POSITION;
			};

			pIn vert(vIn IN)
			{
				pIn OUT;
				OUT.pos = UnityObjectToClipPos(IN.pos);
				return OUT;
			}

			float4 frag(pIn IN):SV_TARGET
			{
				return float4(1, 0, 0, 1);
			}
			ENDCG
		}
	}
	
}
