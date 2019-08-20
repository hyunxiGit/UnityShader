Shader "Custom/Multi" {
  Properties
  {
    [HideInInspector]_ScrBlend("screen blend" , float) = 1
    [HideInInspector]_DstBlend("desty blend" , float) = 0
    [HideInInspector]_ZWri("ZWrite control" , float) = 0
    _MainTex("albedo" , 2d) = "white" {}
    _Color("tint" , color) = (1,1,1,1)
    _Cutoff("clip range", range(0,1)) = 1.0

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
        #pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT 
        #pragma shader_feature _TRANSLUCENT_SHADOW
        #pragma shader_feature _ _SMOOTHNESS_ALBEDO
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
            "LightMode" = "Deferred"
        }
        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers nomrt
        #pragma multi_compile _ UNITY_HDR_ON
        #pragma shader_feature _ _RENDERING_CUTOUT
        #pragma shader_feature _ _EMISSION_MAP
        #pragma shader_feature _ _METALIC_MAP
        #pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALIC
        #pragma shader_feature _ _OCCLUSIONMAP
        #pragma shader_feature _ _DETAIL_MASK
        #pragma shader_feature _ _DETAIL_ALBEDO
        #pragma shader_feature _ _DETAIL_NORMAL
        // #pragma multi_compile _ VERTEXLIGHT_ON LIGHTMAP_ON
        #pragma multi_compile_prepassfinal

        #define DEFERRED_PASS
        #pragma vertex vert
        #pragma fragment frag
        #include "Lighting.cginc"
        ENDCG 

    }

    Pass 
    {
        Tags
        {
            "LightMode" = "ForwardBase"
        }
        ZWrite [_ZWri]
        Blend [_ScrBlend] [_DstBlend]
        
        CGPROGRAM
        #pragma target 3.0
        #pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
        #pragma shader_feature _ _EMISSION_MAP
        #pragma shader_feature _ _METALIC_MAP
        #pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALIC
        #pragma shader_feature _ _OCCLUSIONMAP
        #pragma shader_feature _ _DETAIL_MASK
        #pragma shader_feature _ _DETAIL_ALBEDO
        #pragma shader_feature _ _DETAIL_NORMAL
        // #pragma multi_compile _ VERTEXLIGHT_ON LIGHTMAP_ON
        // #pragma multi_compile _ SHADOWS_SCREEN
        #pragma multi_compile_fwdbase
        #pragma multi_compile_fog
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
        ZWrite [_ZWri]
        Blend [_ScrBlend] One
        CGPROGRAM
        #pragma target 3.0
        #pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
        #pragma multi_compile _METALIC_MAP
        #pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALIC
        #pragma multi_compile_fwdadd_fullshadows
        #pragma shader_feature _ _OCCLUSIONMAP
        #pragma shader_feature _ _DETAIL_MASK
        #pragma shader_feature _ _DETAIL_ALBEDO
        #pragma shader_feature _ _DETAIL_NORMAL
        //#pragma multi_compile_fog
        #pragma vertex vert
        #pragma fragment frag
        #include "Lighting.cginc"
        ENDCG
    }

    Pass {
            Tags {
                "LightMode" = "Meta"
            }

            Cull Off

            CGPROGRAM

            #pragma vertex MyLightmappingVertexProgram
            #pragma fragment MyLightmappingFragmentProgram

            #pragma shader_feature _METALLIC_MAP
            #pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
            #pragma shader_feature _EMISSION_MAP
            #pragma shader_feature _DETAIL_MASK
            #pragma shader_feature _DETAIL_ALBEDO_MAP

            #include "Meta.cginc"

            ENDCG
        }
  }
  
  CustomEditor "MyLightingShaderGUI"
}
