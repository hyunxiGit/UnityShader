Shader "Custom/deferredFog"
{
    Properties
    {
        _MainTex ("source", 2D) = "white" { }
    }

    SubShader
    {
        Pass
        {
            Cull Off
            ZTest Always
            ZWrite Off
            Tags
            {
                "RenderType" = "Opaque"
            }
            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog 

            //the texture will be fileed in automatically by Camera script
            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float3 _FrustumCorners[4];

            struct vIn
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct pIn
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            pIn vert(vIn IN)
            {
                pIn OUT;
                OUT.pos = UnityObjectToClipPos(IN.pos);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag(pIn IN) : SV_TARGET
            {
                float4 col = tex2D(_MainTex, IN.uv);
                float depth = tex2D(_CameraDepthTexture, IN.uv);
                depth = Linear01Depth(depth);
                float fogCoord = _ProjectionParams.z * depth;
                UNITY_CALC_FOG_FACTOR_RAW(fogCoord);
                

                col.rgb = lerp(unity_FogColor.rgb, col.rgb, unityFogFactor);
                return col;
            }
            ENDCG
        }
    }

}