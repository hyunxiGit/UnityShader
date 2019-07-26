Shader "Custom/deferredShading"
{
    Properties
    {

    }
    SubShader
    {

        Pass
        {
            Blend [_SrcBlend] [_DstBlend]
            //Blend One One
            //Cull Off
            //ZTest Always
            ZWrite Off

            CGPROGRAM
            #pragma target 3.0
            #pragma multi_compile_lightpass
            #pragma multi_compile _ UNITY_HDR_ON
            #pragma vertex vert
            #pragma fragment frag
            #include "incDeferLight.cginc"
            ENDCG
        }

        Pass
        {

            Cull Off
            ZTest Always
            ZWrite Off
            
            Stencil{
                Ref [_StencilNonBackground]
                ReadMask [_StencilNonBackground]
                CompBack Equal
                CompFront Equal
            }

            CGPROGRAM
            #pragma target 3.0
            #pragma multi_compile _ UNITY_HDR_ON
            #pragma vertex vert
            #pragma fragment frag


            sampler2D _LightBuffer;
            struct Vin
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0 ; 
            };

            struct Vout
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
     
            Vout vert (Vin IN)
            {
                Vout OUT;
                OUT.pos = UnityObjectToClipPos(IN.pos);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag (Vout IN): SV_Target
            {
                return -log2(tex2D(_LightBuffer, IN.uv));
            }
            ENDCG
        }
    }
}
