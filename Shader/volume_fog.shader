Shader "Hidden/volume_fog"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _CameraDepthTexture;
            uniform float4x4  _InverseViewMatrix;
            float3 _FrustumCorners[4];

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray : TEXCOORD1 ;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.ray = _FrustumCorners[o.uv.x+2*o.uv.y];

                return o;
            }

            float4 calculateCamPosFromCameraFrustrum(v2f IN)
            {
                float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, IN.uv));
                float3 pos_v = depth * IN.ray;

                //convert the cam pos to world pos
                float4 pos_w = mul(_InverseViewMatrix,float4(pos_v,1));

                return pos_w;
            }

            float4 rayMarch(v2f IN)
            {
                float max_stept = 32;   
                float step_scale = 1/max_stept;     

                float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, IN.uv));
                int my_max_step = floor(max_stept * depth);

                float3 step_vector = IN.ray / max_stept;

                float4 fog_col = float4(0,0,0,0) ;
                for(int i = 0 ; i< my_max_step; i++)
                {
                    fog_col += float4(1,0,0,1)*step_scale;
                }

                return pow(fog_col,1);
            }


            sampler2D _MainTex;

            fixed4 frag (v2f IN) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, IN.uv);
                float4 pos_w = calculateCamPosFromCameraFrustrum(IN);
                col = rayMarch(IN);
                // just invert the colors
                //col.rgb = 1 - col.rgb;
                return col;
            }
            ENDCG
        }
    }
}
