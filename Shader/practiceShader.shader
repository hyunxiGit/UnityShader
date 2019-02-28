Shader "Custom/practice"
{
  Properties
  {
    _Albedo("albedo" , 2d) = "white" {}
    _Tint("tint" , color) = (1,1,1,1)
    [noscaleoffset]_Normal("normal" , 2d) = "normal"{}
    _Secondary("secondary map" , 2d) = "white" {}
    [gamma]_BumpScale("bump scale", float) = 0.5
    [gamma]_Metalic("metalic" , range(0,1)) = 0.5
    [gamma]_Roughness("roughness" , range(0,1)) = 0.5
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
        #include "tSh.cginc"
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

        #pragma multi_compile _ VERTEXLIGHT_ON
        #pragma multi_compile _ SHADOWS_SCREEN
        #define FORWARD_BASE_PASS
        #pragma vertex vert
        #pragma fragment frag
        #include "tLi.cginc"
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
        #pragma multi_compile_fwdadd_fullshadows
        #pragma vertex vert
        #pragma fragment frag
        #include "tLi.cginc"
        ENDCG
    }
  }
  
    CustomEditor "MyLightingShaderGUI"
}
