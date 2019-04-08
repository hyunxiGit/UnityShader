Shader "Custom/Multi" {
  Properties
  {
    _Albedo("albedo" , 2d) = "white" {}
    _Tint("tint" , color) = (1,1,1,1)
    [noscaleoffset]_Normal("normal" , 2d) = "normal"{}
    [noscaleoffset]_MetalicMap("metalic map" , 2d) = "white" {}
    [noscaleoffset]_EmissionMap("emission map" , 2d) = "white"{}
    [noscaleoffset]_OcclusionMap("occlusion map" , 2d) = "white"{}
    
    _DetailAlbedoMap("detail abedo" , 2d) = "white" {}
    [noscaleoffset]_DetailNormalMap("detail normal" , 2d) = "normal" {}
    [noscaleoffset]_DetailMaskMap("detail mask" , 2d) = "white" {}
    _Emission("emission" , color) = (0,0,0,0)
    [gamma]_BumpScale("bump scale", float) = 0.5
    [gamma]_Metalic("metalic" , range(0,1)) = 0.5
    [gamma]_Smoothness("smoothness" , range(0,1)) = 0.5
    [gamma]_OcclusionStrength("occlusion strength" , range(0,1)) = 0
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
        #include "Shadow.cginc"
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
        #pragma shader_feature _ _EMISSION_MAP
        #pragma shader_feature _ _METALIC_MAP
        #pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALIC
        #pragma shader_feature _ _OCCLUSIONMAP
        #pragma shader_feature _ _DETAIL_MASK
        #pragma shader_feature _ _DETAIL_ALBEDO
        #pragma shader_feature _ _DETAIL_NORMAL
        #pragma multi_compile _ VERTEXLIGHT_ON
        #pragma multi_compile _ SHADOWS_SCREEN
        #define FORWARD_BASE_PASS
        #pragma vertex vert
        #pragma fragment frag
        #include "Lighting.cginc"
        ENDCG
    }
    Pass 
    {
        Tags
        {
            "LightMode" = "ForwardAdd"
        }
        Blend ONE ONE
        CGPROGRAM
        #pragma target 3.0
        #pragma multi_compile _METALIC_MAP
        #pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALIC
        #pragma multi_compile_fwdadd_fullshadows
        #pragma shader_feature _ _OCCLUSIONMAP
        #pragma shader_feature _ _DETAIL_MASK
        #pragma shader_feature _ _DETAIL_ALBEDO
        #pragma shader_feature _ _DETAIL_NORMAL
        #pragma vertex vert
        #pragma fragment frag
        #include "Lighting.cginc"
        ENDCG
    }
  }
  
    CustomEditor "MyLightingShaderGUI"
}
