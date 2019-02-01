Shader "Custom/t_Multi" {
	Properties
	{
		_Albedo("albedo" , 2D) = "white"{}
		[gamma]_Metalic("metalic" , range(0,1)) =0.5
		[gamma]_Smoothness("smoothness" , range(0,1)) =0.5
	}
	SubShader 
	{
		Pass
		{
			Tags
			{
				"LightMode" = "ForwardBase"
			}
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile _ SHADOWS_SCREEN
			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma vertex vert
			#pragma fragment frag
			#include "t_lighting.cginc"
			ENDCG
		}
		Pass
		{
			Tags
			{
				"LightMode" = "ForwardAdd"
			}
			Blend one one
			ZWrite Off
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdadd_fullshadows
			
			#pragma vertex vert
			#pragma fragment frag
			#include "t_lighting.cginc"
			ENDCG
		}
		Pass
		{
			Tags
			{
				"LightMode" = "ShadowCaster"
			}
			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile_shadowcaster

			#pragma vertex vert
			#pragma fragment frag
			#include "t_shadow.cginc"
			ENDCG

		}
	}
}
