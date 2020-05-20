//log
//camera position object correct
//object vertex world space correct
//ray_b_point_w correct
//ab_ray_p1 correct
//z_step obeject space correct
//obb intersect 2 points correct
//ray march correct 

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
            sampler2D _CameraDepthTexture;

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


            void obb_intersect(float4 _ab_ray_p0 , float4 _ab_ray_p1 , out float4 p0_o , out float4 p1_o , out float4 p0_w ,out float4 p1_w )
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
                ray_projected.x = ray_projected.x == 0.0f?0.00001f : ray_projected.x;
                ray_projected.y = ray_projected.y == 0.0f?0.00001f : ray_projected.y;
                ray_projected.z = ray_projected.z == 0.0f?0.00001f : ray_projected.z;

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
                p0_o =float4(_ab_ray_p0.xyz + max(max(xyz_sclae_min.x  ,xyz_sclae_min.y),xyz_sclae_min.z) *ray_full,1);
                p1_o =float4(_ab_ray_p0.xyz + min(min(xyz_sclae_max.x  ,xyz_sclae_max.y),xyz_sclae_max.z) *ray_full,1);
                //two intersect point in object space
                p0_w = float4(mul(unity_ObjectToWorld,p0_o).xyz,1);
                p1_w = float4(mul(unity_ObjectToWorld, p1_o).xyz,1);       

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
            float4 rayMarchPoint(float4 _p0, float4 _p1 , float3 z_step)
            {

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

            //ray march with no z plane alignment
            float4 rayMarch(float4 _p0, float4 _p1 , float3 z_step )
            {      

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

            float4 rayMarch2(float4 _p0, float4 _p1 , float3 z_step ,float4 cam_o)
            {
                //z-plane alignment

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

            float debugPoint(float4 p ,float s,  UNITY_VPOS_TYPE screenPos)
            {   // p : point position , s: point size in float 
                p = ComputeScreenPos (UnityObjectToClipPos(p));
                //p point in screen uv (0-1)
                float2 uv_p = p.xy / p.w;
                //screen space uv (0-1)
                float2 uv_screen = screenPos / _ScreenParams ;
                float2 circle = (uv_p - uv_screen);
                circle.y*=_ScreenParams.y/_ScreenParams.x;
                float c = step(length(circle),s);
                return c;
            }

            fixed4 frag (v2f i , UNITY_VPOS_TYPE screenPos : VPOS) : SV_Target
            {
                //camera depth calculation 
                //todo : use calculated scene depth in the ray marching to terminate ray if intersct 
                //with other object
                float4 p = ComputeScreenPos (UnityObjectToClipPos(i.ver_o));
                float cam_depth = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(p)).r;
                cam_depth = LinearEyeDepth(cam_depth);

                float n_plane = _ProjectionParams.y;
                float f_plane = _ProjectionParams.z;

                fixed4 col = float4(0,0,0,1);
                float4 _inter_p0_o;
                float4 _inter_p1_o;
                float4 _inter_p0_w;
                float4 _inter_p1_w;

                //todo : this step can be optmize
                float4 ray_b_point_w = float4(_WorldSpaceCameraPos.xyz + (i.ver_w.xyz -_WorldSpaceCameraPos.xyz) * _ProjectionParams.z / (i.ver_w.z -_WorldSpaceCameraPos.z), 1.0f);
                float4 ab_ray_p1 = mul(unity_WorldToObject, ray_b_point_w); 

                obb_intersect(i.ab_ray_p0 , ab_ray_p1 , _inter_p0_o , _inter_p1_o , _inter_p0_w ,_inter_p1_w );

                //ray march
                // col = rayMarchPoint(_inter_p0_o , _inter_p1_o , i.z_step );
                //col = rayMarch(_inter_p0_o,_inter_p1_o ,i.z_step); 
                col = rayMarch2(_inter_p0_o, _inter_p1_o, i.z_step, i.ab_ray_p0);

                //debug, scater the ray to grid instead of pixel

                int tile = 5;
                float gap = 1.0f/tile;
                float c_offset = fmod(tile,2) * gap*0.5f;
                int h_tile = tile/2;
                float d_point_size = 0.003f;
                //threshold for tolerate rasterize cause inaccurate pixel position
                float threshold = 0.005f;

                for (int _i = 0; _i <tile ; _i++)
                {
                    for (int _j = 0; _j <tile ; _j++)
                    {
                        float i_pos = gap * (_i + 0.5 - d_point_size/2)-0.5f;
                        float j_pos = gap * (_j + 0.5 - d_point_size/2)-0.5f;
                        //six faces
                        // c += debugPoint(float4(0.5,i_pos,j_pos,1), d_point_size, screenPos);
                        // c += debugPoint(float4(-0.5,i_pos,j_pos,1), d_point_size, screenPos);
                        // c += debugPoint(float4(i_pos,0.5,j_pos,1), d_point_size, screenPos);
                        // c += debugPoint(float4(i_pos,-0.5,j_pos,1), d_point_size, screenPos);
                        // c += debugPoint(float4(i_pos,j_pos,0.5,1), d_point_size, screenPos);
                        // c += debugPoint(float4(i_pos,j_pos,-0.5,1), d_point_size, screenPos);
                    }
                }
                // Inside the vertex shader.



                col = float4(cam_depth , cam_depth , cam_depth, 1);
                return col;
            }
            ENDCG
        }
    }
}
