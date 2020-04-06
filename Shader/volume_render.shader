Shader "Custom/volume_render"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True" }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 pos_w : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.pos_w = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            // these define works because in the loop / condition shader can only handle constance
            #define steps 64
            #define step_size 0.01

            bool inSphere(float3 pos, float3 center,float radius)
            {
                if (distance( pos , center)<radius)
                    return true;
                else
                    return false;
            }
            float r = 0.4;
            float4 rayMartch(float3 rayVec, float3 pos )
            {

                for(int i = 0; i<steps;i++)
                {
                    
                    if (inSphere(pos, float3(0,0,0), 0.5))
                    {
                        return float4(1,0,0,1);
                    } 
                    pos += rayVec*step_size;
                }

                return float4(0,0,0,0);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col;

                float3 rayVec = normalize (i.pos_w-_WorldSpaceCameraPos);
                float4 march_pos = rayMartch(rayVec, i.pos_w);

                return march_pos;
            }
            ENDCG
        }
    }
}
