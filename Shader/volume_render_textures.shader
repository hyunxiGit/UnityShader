Shader "Custom/volume_render_texture"
{
    Properties
    {
        _Volume ("Volume", 3D) = "" {}
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
            #include "UnityPBSLighting.cginc"

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

            sampler3D _Volume;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos_w = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            // these define works because in the loop / condition shader can only handle constance
            #define steps 128
            #define step_size 0.01

            bool inSphere(float3 pos, float3 center,float radius)
            {
                if (distance( pos , center)<radius)
                    return true;
                else
                    return false;
            }

            float3 rayMartch(float3 rayVec, float3 pos, float3 center)
            {
                for(int i = 0; i<steps;i++)
                {
                    
                    if (inSphere(pos, center, 0.5))
                    {
                        return pos;
                    } 
                    pos += rayVec*step_size; 
                    //accumulate the v_texture according to pos
                    //need to convert the pos into local cube pos
                }

                return float3(0,0,0);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col;
                //should get from script
                float3 center = float3(0,0,0);

                float3 rayVec = normalize (i.pos_w-_WorldSpaceCameraPos);
                float3 pos_ray = rayMartch(rayVec, i.pos_w,center);
                float depth = length(pos_ray);
                if (depth == 0)
                    {col = float4(0,0,0,0);                }
                else
                {
                    //col = float4(pos_ray,1);
                    float3 normal = normalize(pos_ray-center);
                    float3 l_dir = _WorldSpaceLightPos0;
                    float c = DotClamped(l_dir,normal);
                    col = float4(c,c,c,1);
                }
                //lighting 

                return col;
            }
            ENDCG
        }
    }
}
