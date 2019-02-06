Shader "Custom/Multi" {
	Properties
	{
		_AlbedoMap("albedo",2D) = "white"{}
		[noScaleOffset]_Normal("normal",2D) = "normal"{}
		[gamma]_Metalic("metalic", range(0,1)) = 0.5
		[gamma]_Smoothness("smoothness", range(0,1)) = 0.5
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

			#define FORWARD_BASE_PASS
			#include "Lighting.cginc"
			ENDCG
		}
		Pass 
		{
			Tags 
			{
				"LightMode" = "ForwardAdd"
			}
			Blend One One
			CGPROGRAM		
			#pragma target 3.0
			#pragma multi_compile_fwdadd_fullshadows
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
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
			#pragma vertex vert
			#pragma fragment frag
			#include "Shadow.cginc"
			ENDCG
		}
	}
}
