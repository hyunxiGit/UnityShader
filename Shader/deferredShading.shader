﻿Shader "Custom/deferredShading"
{
    Properties
    {

    }
    SubShader
    {

        Pass
        {
            Cull Off
            ZTest Always
            ZWrite Off

            CGPROGRAM
            #pragma target 3.0
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
            struct Fout
            {
                float4 col : SV_Target;
            };
     
            Vout vert (Vin IN)
            {
                Vout OUT;
                OUT.pos = UnityObjectToClipPos(IN.pos);
                OUT.uv = IN.uv;
                return OUT;
            }

            Fout frag (Vout IN)
            {
                Fout OUT;
                float4 lightBuff = tex2D(_LightBuffer , IN.uv);
                OUT.col = -log2(lightBuff );
                return OUT;
            }
            ENDCG
        }
    }
}