Shader "Custom/tt_multi"
{
     Properties
    {
        _Albedo("albedo", 2D) = "white"{}
        [noscaleoffset]_Normal("normal" , 2D) = "normal"{}
        [gamma] _NormalScale ("normal scale",float) = 0.1
        [gamma]_Metalic("metalic" , range(0,1)) = 0.5
        [gamma]_Smooth("smoothness" , range(0,1)) = 0.5

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
            #pragma multi_compile _ VERTEXLIGHT_ON
            #pragma vertex vert
            #pragma fragment frag 
            #include "tt_lightings.cginc"

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
            #pragma target 3.0
            #pragma multi_compile_fwdadd
            #pragma vertex vert
            #pragma fragment frag 
            #include "tt_lightings.cginc"

            ENDCG
        }
    }  
}
