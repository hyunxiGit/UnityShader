Shader "Custom/useTime"
{
	Properties
	{
		_AlbedoMap("albedo" , 2D) = "white"{}
		_FlowMap("flow" , 2D) = "white"{}
		_Metalic("metalic" , range(0,1)) = 0.5
		_Roughness("roughness" , range(0,1)) = 0.5
	}
	SubShader
	{
		pass 
		{
			CGPROGRAM
			#pragma target 3.0
			#include "UnityPBSLighting.cginc"
			#pragma vertex vert
			#pragma fragment frag

			sampler2D _AlbedoMap;
			float4 _AlbedoMap_ST;
			sampler2D _FlowMap;
			float4 _FlowMap_ST;
			float oneMinusReflectivity;
			float3 specularColor;

			float _Metalic;
			float _Roughness;
			float3 viewVec;

			struct VIN
			{
				float4 pos : POSITION;
				float3 nor : NORMAL;
				float2 uv  : TEXCOORD0;
			};
			struct VOUT
			{
				float4 pos : SV_POSITION;
				float3 nor : NORMAL;
				float2 uv  : TEXCOORD0;
			};
			VOUT vert(VIN IN)
			{
				VOUT OUT;
				OUT.pos = UnityObjectToClipPos(IN.pos);
				OUT.nor = normalize(UnityObjectToWorldNormal(IN.nor));
				OUT.uv = IN.uv;

				return OUT;
			}

			float4 frag(VOUT IN) :SV_TARGET
			{
				float4 col;

				IN.uv = TRANSFORM_TEX(IN.uv, _AlbedoMap);
				float3 albedo = tex2D(_AlbedoMap, IN.uv * _Time.x).rgb;


				UnityLight dLight;
				dLight.dir = _WorldSpaceLightPos0;
				dLight.color = float4(_LightColor0.rgb, 1);
				dLight.ndotl = DotClamped(IN.nor, dLight.dir);

				UnityIndirect iLight;
				iLight.diffuse = 0;
				iLight.specular = 0;

				specularColor = lerp(albedo, 0.04f, _Metalic);

				viewVec = normalize(_WorldSpaceCameraPos - IN.pos);

				albedo = DiffuseAndSpecularFromMetallic(albedo, _Metalic, specularColor, oneMinusReflectivity);
				col = UNITY_BRDF_PBS(albedo,specularColor, oneMinusReflectivity, 1- _Roughness, IN.nor , viewVec,dLight , iLight);
				return col;
			}
			ENDCG
		}
	}
}
