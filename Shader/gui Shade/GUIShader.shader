Shader "Custom/GUIShader"
{
  Properties
  {
    _Albedo("albedo map" , 2D) = "white"{}
    [noscaleoffset]_Normal("normal map" , 2D) = "normal"{}
    [noscaleoffset]_MetalicMap("metalic map" , 2D) = "white"{}
    [noscaleoffset]_EmissionMap("emission map" , 2D) = "black"{}
    _Emission("emission" , color) = (0,0,0,1)
    _Detail("detail map" , 2D) = "normal"{}
    _Tint("tint color" , color) = (1,1,1,1)

    [gamma]_NormalScale ("normal scale" , range(0,1)) = 0.5
    [gamma]_Metalic ("metalic" , range(0,1)) = 0.5
    [gamma]_Roughness ("roughness" , range(0,1)) = 0.5
  }

  SubShader 
  {
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
        #include "gSh.cginc"
        ENDCG
    }
    Pass
    {
        Tags
        {
            "LightMode" = "ForwardBase"
        }
        CGPROGRAM
        #pragma target 3.0
        #define FORWARD_BASE_PASS
        #pragma shader_feature _ _METALIC_MAP
        #pragma shader_feature _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
        #pragma multi_compile _ SHADOWS_SCREEN
        #pragma multi_compile _ VERTEXLIGHT_ON
        #pragma vertex vert
        #pragma fragment frag
        #include "gLi.cginc"
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
        #pragma shader_feature _ _METALIC_MAP
        #pragma shader_feature _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
        #pragma multi_compile_fwdadd_fullshadows
        #pragma vertex vert
        #pragma fragment frag
        #include "gLi.cginc"
        ENDCG
    }
  }
  CustomEditor "TemlateGUI"
}
