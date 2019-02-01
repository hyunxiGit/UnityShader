Shader "Custom/GreyNormal"
{
	Properties
	{
		_AlbedoMap("albedo" , 2d) = "white"{}
		[NoScaleOffset]_NormalMap("normal" , 2d) = "normal"{}
		_Specular("specular" , color) = (1,1,1,1)
		[gamma]_Metalic("metalic" , range(0,1)) = 0.5
		[gamma]_roughness("roughness" , range(0,1)) = 0.5
	}
	SubShader
	{
		Tags
		{
			"RenderType" = "Opaque"
			"LightMode" = "ForwardBase"
		}
		pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityPBSLighting.cginc"

			sampler2D _AlbedoMap;
			float4 _AlbedoMap_ST;
			sampler2D _NormalMap;
			float2 _NormalMap_TexelSize;

			float4 _Specular;
			float  _Metalic;
			float _roughness;

			float OneMinusReflectivity;

			struct VIN
			{
				float4 pos : POSITION;
				float3 nor : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct VOUT
			{
				float4 pos : SV_POSITION;
				float3 nor : NORMAL;
				float2 uv : TEXCOORD0;
				float4 p_w : TEXCOORD1;
			};

			UnityLight dLight(VOUT IN)
			{
				UnityLight L;
				L.dir = _WorldSpaceLightPos0;
				L.color = _LightColor0;
				L.ndotl =  DotClamped(L.dir , IN.nor);
				return L;	
			}

			UnityIndirect iLight()
			{
				UnityIndirect L;
				L.diffuse = 0;
				L.specular = 0;
				return L;
			}

			VOUT vert(VIN IN)
			{
				VOUT OUT;
				OUT.pos = UnityObjectToClipPos(IN.pos);
				OUT.nor = normalize(UnityObjectToWorldNormal(IN.nor));
				OUT.p_w = mul (unity_ObjectToWorld , IN.pos);
				OUT.uv = IN.uv;
				return OUT;
			}


			float4 frag(VOUT IN) : SV_Target
			{
				float3 Al;
				float3 No = IN.nor;
				float2 uv0 = TRANSFORM_TEX(IN.uv, _AlbedoMap);
				Al = tex2D(_AlbedoMap, uv0);


				float  U = tex2D(_NormalMap, uv0.xy - float2(_NormalMap_TexelSize.x*0.5,0)) - tex2D(_NormalMap, uv0.xy + float2(_NormalMap_TexelSize.x*0.5,0));
				//float3 NU = normalize(float3(U , 1 , 0));
				
				float  V = tex2D(_NormalMap, uv0.xy - float2(0 , _NormalMap_TexelSize.x*0.5)) - tex2D(_NormalMap, uv0.xy + float2(0 , _NormalMap_TexelSize.x*0.5));
				//float3 NV = normalize(float3(0 , 1 , V));

				No =normalize(float3(U , 1 , V)) ;
				//No = IN.nor;

				float3 Sp;
				float Me = _Metalic;
				float On;
				float Sm =  1 - _roughness;

				UnityLight dL = dLight(IN);
				UnityIndirect iL = iLight ();


				float3 ViewVect = normalize(_WorldSpaceCameraPos.xyz - IN.p_w);
				Al = DiffuseAndSpecularFromMetallic(Al, Me, Sp, On);
				return UNITY_BRDF_PBS(Al, Sp, OneMinusReflectivity, Sm, No, ViewVect, dL, iL);
			}
			ENDCG
		}
	}
	
}
