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
            uniform float4 z_step;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 ver_w : TEXCOORD1;
                float4 ver_o : TEXCOORD2;
                float4 cam_o : TEXCOORD3;
                float3 z_step_o : TEXCOORD4;
                float4 ray_b_point_o : TEXCOORD5;
                float4 vertex : SV_POSITION;
            };

            sampler3D _Volume;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.ver_w = mul(unity_ObjectToWorld,v.vertex);
                o.ver_o = v.vertex;
                o.cam_o = mul(unity_WorldToObject, _WorldSpaceCameraPos);
                o.z_step_o = mul(unity_WorldToObject, z_step.xyz);
                float4 ray_b_point_w = float4(_WorldSpaceCameraPos.xyz + (o.ver_w.xyz -_WorldSpaceCameraPos.xyz) * _ProjectionParams.z / (o.ver_w.z -_WorldSpaceCameraPos.z), 1.0f);
                //wip : this is the ab ray b point 
                o. ray_b_point_o = mul(unity_WorldToObject, ray_b_point_w);
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
                float n_plane = _ProjectionParams.y;
                float f_plane = _ProjectionParams.z;

                fixed4 col;
                //should get from script
                // col = i.ver_o + float4(0.5,0.5,0.5,0);
                
                float3 dir = normalize(i.ver_o - i.cam_o);
                
                col = float4(i. ray_b_point_o.xyz,1);
                
                return col;
            }
            ENDCG
        }
    }
}
