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
                float4 ab_ray_p0 : TEXCOORD3; //camera object space pos
                float4 ab_ray_p1 : TEXCOORD4;//ray cam-pixel extend to far plane
                float3 z_step : TEXCOORD5; //z_step vector object space 
                float4 vertex : SV_POSITION;
            };

            sampler3D _Volume;

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.uv;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.ver_w = mul(unity_ObjectToWorld,v.vertex);
                o.ver_o = v.vertex;
                //ab ray
                o.ab_ray_p0 = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1.0f));
                float4 ray_b_point_w = float4(_WorldSpaceCameraPos.xyz + (o.ver_w.xyz -_WorldSpaceCameraPos.xyz) * _ProjectionParams.z / (o.ver_w.z -_WorldSpaceCameraPos.z), 1.0f);
                //wip : this is the ab ray b point 
                o. ab_ray_p1 = mul(unity_WorldToObject, ray_b_point_w);
                o.z_step = mul(unity_WorldToObject, z_step.xyz);
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

            void obb_intersect(float4 _ab_ray_p0 , float4 _ab_ray_p1 , out float3 p0_o , out float3 p1_o )
            {
                float4 obb_min = float4(-0.5f,-0.5f,-0.5f,1.0f);
                float4 obb_max = float4(0.5f,0.5f,0.5f,1.0f);

                float3 ray_full = _ab_ray_p1 -_ab_ray_p0;
                float3 min_inter , max_inter; // intersection point
                bool min_exist, max_exist;

                float3 ray_min = obb_min - _ab_ray_p0;
                float3 ray_max = obb_max - _ab_ray_p0;

                float3 xyz_sclae_min;
                float3 xyz_sclae_max;

                //full ray on x , y , z value
                float3 ray_projected = float3( ray_full.x , ray_full.y , ray_full.z);
                ray_projected.x = ray_projected.x == 0.0f?0.0000001f : ray_projected.x;
                ray_projected.y = ray_projected.y == 0.0f?0.0000001f : ray_projected.y;
                ray_projected.z = ray_projected.z == 0.0f?0.0000001f : ray_projected.z;

                float _x1 = ray_min.x / ray_projected.x;
                float _x2 = ray_max.x / ray_projected.x;

                xyz_sclae_min.x = _x1 < _x2 ? _x1 : _x2;
                xyz_sclae_max.x = _x1 > _x2 ? _x1 : _x2;

                float _y1 = ray_min.y / ray_projected.y;
                float _y2 = ray_max.y / ray_projected.y;

                xyz_sclae_min.y = _y1 < _y2 ? _y1 : _y2;
                xyz_sclae_max.y = _y1 > _y2 ? _y1 : _y2;

                float _z1 = ray_min.z / ray_projected.z;
                float _z2 = ray_max.z / ray_projected.z;

                xyz_sclae_min.z = _z1 < _z2 ? _z1 : _z2;
                xyz_sclae_max.z = _z1 > _z2 ? _z1 : _z2;

                float min_scale = max(max(xyz_sclae_min.x ,xyz_sclae_min.y),xyz_sclae_min.z);
                float max_scale = min(min(xyz_sclae_max.x ,xyz_sclae_max.y),xyz_sclae_max.z);

                //two intersect point in object space
                p0_o =_ab_ray_p0.xyz + max(max(xyz_sclae_min.x  ,xyz_sclae_min.y),xyz_sclae_min.z) *ray_full;
                p1_o =_ab_ray_p0.xyz + min(min(xyz_sclae_max.x  ,xyz_sclae_max.y),xyz_sclae_max.z) *ray_full;
                //two intersect point in object space
                float3 p0_w = mul(unity_ObjectToWorld,float4(p0_o,1)).xyz;
                float3 p1_w = mul(unity_ObjectToWorld,float4(p1_o,1)).xyz;       

                // p0_o = p0_w;  
                // p1_o = p1_w;  

                min_exist=false;
                max_exist=false;

                if ( min_scale < max_scale)
                {
                    if (min_scale > 0 && min_scale <1)
                    {
                        min_exist=true;
                    }

                    if(max_scale > 0 && max_scale <1 )
                    {
                        max_exist=true;
                    }
                }
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float n_plane = _ProjectionParams.y;
                float f_plane = _ProjectionParams.z;

                fixed4 col = float4(0,0,0,1);
                float3 _p0;
                float3 _p1;

                obb_intersect(i.ab_ray_p0 , i.ab_ray_p1,  _p0 , _p1 );
                //p0 and p1 in object space correct presented
                col = float4(_p0,1.0f) ;     
                return col;
            }
            ENDCG
        }
    }
}
