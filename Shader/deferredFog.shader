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

            //multi compile for all fog case
            #pragma multi_compile_fog 
            #define FOG_DISTANCE
            #define FOGSKYBOX

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
                #if defined(FOG_DISTANCE)
                    float3 Ray : TEXCOORD1;
                #endif
            };

            pIn vert(vIn IN)
            {
                pIn OUT;
                OUT.pos = UnityObjectToClipPos(IN.pos);
                OUT.uv = IN.uv;
                #if defined(FOG_DISTANCE)
                    OUT.Ray = _FrustumCorners[OUT.uv.x+2*OUT.uv.y];
                #endif
                return OUT;
            }

            float4 frag(pIn IN) : SV_TARGET
            {
                float4 col = tex2D(_MainTex, IN.uv);
                float depth = tex2D(_CameraDepthTexture, IN.uv);

                depth = Linear01Depth(depth);


                
                float fogCoord = _ProjectionParams.z * depth;
                #if defined(FOG_DISTANCE)
                    fogCoord = length (IN.Ray) * depth;
                #endif

                UNITY_CALC_FOG_FACTOR_RAW(fogCoord);

                #if !defined(FOGSKYBOX)
                    if(depth >0.99)
                    {
                        unityFogFactor = 1;
                    }
                #endif

                col.rgb = lerp(unity_FogColor.rgb, col.rgb, unityFogFactor);
                return col;
            }
            ENDCG
        }
    }

}