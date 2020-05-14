// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

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
            #pragma target 3.0
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
                float4 ver_clip : TEXCOORD6;
                // float4 vertex : SV_POSITION;
            };

            sampler3D _Volume;

            v2f vert (appdata v ,  out float4 vertex : SV_POSITION)
            {
                v2f o;
                o.uv = v.uv;
                vertex = UnityObjectToClipPos(v.vertex);
                o.ver_w = mul(unity_ObjectToWorld,v.vertex);
                o.ver_o = v.vertex;
                o.ver_clip = vertex;
                //ab ray
                o.ab_ray_p0 = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1.0f));
                float4 ray_b_point_w = float4(_WorldSpaceCameraPos.xyz + (o.ver_w.xyz -_WorldSpaceCameraPos.xyz) * _ProjectionParams.z / (o.ver_w.z -_WorldSpaceCameraPos.z), 1.0f);
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


            void obb_intersect(float4 _ab_ray_p0 , float4 _ab_ray_p1 , out float3 p0_o , out float3 p1_o , out float3 p0_w ,out float3 p1_w )
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
                p0_w = mul(unity_ObjectToWorld,float4(p0_o,1)).xyz;
                p1_w = mul(unity_ObjectToWorld,float4(p1_o,1)).xyz;       

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

            //current bug not related to cam orthographa, not related to z plane alignment
            //todo : is it related to object space ?
            float4 rayMarchPoint(float4 _p0, float4 _p1 , float max_distance , int _max_steps ,float4 cam_o)
            {
                float3 z_step = float3(0,0, max_distance / _max_steps);  
                z_step = mul(unity_WorldToObject, z_step);

                float3 ray_full = _p1 - _p0;
                float scale = length(z_step) / length(ray_full) ;

                float4 dst = float4(0, 0, 0, 0);
                // float _Threshold = 0.8;
                int ITERATION = 100;
                for (int i = 0 ; i <ITERATION ; i++)
                {
                    float3 pos = _p0 + i *scale *ray_full;
                    // build a sphere on the point
                    float v = tex3D(_Volume, pos + float3(0.5,0.5,0.5)).r ;

                    float4 src = float4(v, v, v, v);
                    src.a = src.r;
                    src.a *= 0.5;
                    src.rgb *= src.a;

                    // blend
                    // if (i > full_step) break;
                    if (i *scale > 1.0f) break;
                }
                return saturate(dst);
                // return float4(p0_new,1);
            }

            float4 rayMarch(float4 _p0, float4 _p1 , float max_distance , int _max_steps ,float4 cam_o)
            {
                float3 z_step = float3(0,0, max_distance / _max_steps);  
                z_step = mul(unity_WorldToObject, z_step);

                float3 ray_full = _p1 - _p0;
                float scale = length(z_step) / length(ray_full) ;

                float4 dst = float4(0, 0, 0, 0);
                // float _Threshold = 0.8;
                int ITERATION = 100;
                for (int i = 0 ; i <ITERATION ; i++)
                {
                    float3 pos = _p0 + i *scale *ray_full;
                    // build a sphere on the point
                    float v = tex3D(_Volume, pos + float3(0.5,0.5,0.5)).r ;

                    float4 src = float4(v, v, v, v);
                    src.a = src.r;
                    src.a *= 0.5;
                    src.rgb *= src.a;

                    // blend
                    dst = (1.0 - dst.a) * src + dst;
                    // if (i > full_step) break;
                    if (i *scale > 1.0f) break;
                }
                return saturate(dst);
                // return float4(p0_new,1);
            }

            float4 rayMarch2(float4 _p0, float4 _p1 , float max_distance , int _max_steps ,float4 cam_o)
            {
                //z-plane alignment
                float3 z_step = float3(0,0, max_distance / _max_steps);                
                z_step = mul(unity_WorldToObject, z_step);


                //the plane alignment should be calculated on cam pos as origin
                float3 p0_c = _p0 -cam_o;
                float3 z_dir = normalize(z_step);
                //step on p0-p1 align z plane
                float3 p_step = p0_c * dot(z_step , z_dir) / dot(p0_c,z_dir);
                float3 p0_z_pro = dot(p0_c, z_dir)*z_dir;
                float scale_p0 = dot(p0_z_pro , z_dir);
                float scale_z_step = dot(z_step , z_dir);
                int scale_p0_z_step = ceil(scale_p0 / scale_z_step);
                float3 z_plane = scale_p0_z_step * z_step;
                //position
                float3 p0_new = scale_p0_z_step * scale_z_step /scale_p0 * p0_c + cam_o;   

                int full_step = floor(length(_p1 -_p0) / length(p_step));

                //todo : camera sample point is nowowrking like slice, figure out why
                float4 dst = float4(0, 0, 0, 0);
                float _Threshold = 0.8;
                int ITERATION = 100;
                for (int i = 0 ; i <ITERATION ; i++)
                {
                    float3 pos = p0_new + i *p_step;
                    float v = tex3D(_Volume, pos + float3(0.5,0.5,0.5)).r ;

                    // float4 src = float4(v, v, v, v);
                    // src.a = src.r;
                    // src.a *= 0.5;
                    // src.rgb *= src.a;

                    float4 src = float4(1, 1, 1, v*0.05);

                    // blend
                    dst = (1.0 - dst.a) * src + dst;
                    if (i > full_step) break;
                }
                return saturate(dst);
                // return float4(p0_new,1);
            }

            float debugPoint(float4 p , UNITY_VPOS_TYPE screenPos)
            {
                p = ComputeScreenPos (UnityObjectToClipPos(p));
                //p point in screen uv (0-1)
                float2 uv_p = p.xy / p.w;
                //screen space uv (0-1)
                float2 uv_screen = screenPos / _ScreenParams;
                float c = step(length(uv_p - uv_screen),0.01);
                return c;
            }

            fixed4 frag (v2f i , UNITY_VPOS_TYPE screenPos : VPOS) : SV_Target
            {
                // screenPos.xy = floor(screenPos.xy * 0.25) * 0.5;
                // float checker = frac(screenPos.r + screenPos.g);

                float n_plane = _ProjectionParams.y;
                float f_plane = _ProjectionParams.z;

                fixed4 col = float4(0,0,0,1);
                float3 _inter_p0_o;
                float3 _inter_p1_o;
                float3 _inter_p0_w;
                float3 _inter_p1_w;



                obb_intersect(i.ab_ray_p0 , i.ab_ray_p1,  _inter_p0_o , _inter_p1_o ,_inter_p0_w , _inter_p1_w);
                //p0 and p1 in object space correct presented

                col = rayMarch(float4 (_inter_p0_o ,1), float4 (_inter_p1_o,1) , f_plane-n_plane ,  500, i.ab_ray_p0); 
                col = rayMarchPoint(float4 (_inter_p0_o ,1), float4 (_inter_p1_o,1) , f_plane-n_plane ,  500, i.ab_ray_p0);   
                //col = rayMarch2(float4 (_inter_p0_o ,1), float4 (_inter_p1_o,1) , f_plane-n_plane ,  500, i.ab_ray_p0);   

                float c = debugPoint(float4(0.5,0.5,0.5,1) , screenPos);
                return float4(c,c,c,1);
            }
            ENDCG
        }
    }
}
