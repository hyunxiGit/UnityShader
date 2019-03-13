Shader "Custom/practice"
{
  Properties
  {
    _Albedo("albedo map" , 2D) = "white"{}
    [noscaleoffset]_Normal("normal map" , 2D) = "normal"{}
    _Detail("detail map" , 2D) = "normal"{}

    [gamma]_Metalic ("metalic" , range(0,1)) = 0.5
    [gamma]_Roughness ("roughness" , range(0,1)) = 0.5
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
        #define FORWARD_BASE_PASS
        #pragma multi_compile _ VERTEXLIGHT_ON
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
        Blend one one
        CGPROGRAM
        #pragma multi_compile_fwdadd
        #pragma target 3.0
        #pragma vertex vert
        #pragma fragment frag
        #include "tLi.cginc"
        ENDCG
    }
  }
}
