//log
//camera position object correct
//object vertex world space correct
//ray_b_point_w correct
//ab_ray_p1 correct
//z_step obeject space correct
//obb intersect 2 points correct
//ray march correct 
//scene object intersect correct
//z plan align correct

Shader "Custom/volume_render_texture"
{
    Properties
    {
        _Volume ("Volume", 3D) = "" {}
    }
    SubShader
    {
        // debug purpose
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True" }

        // Tags { "RenderType"="Opaque" }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100
        //shadow pass will be useful if need to have this object in the scenedepth
        // Pass 
        //  {
        //      Name "ShadowCaster"
        //      Tags { "LightMode" = "ShadowCaster" }
             
        //      Fog {Mode Off}
        //      ZWrite On ZTest LEqual Cull Off
        //      Offset 1, 1
 
        //      CGPROGRAM
        //      #pragma vertex vert
        //      #pragma fragment frag
        //      #pragma multi_compile_shadowcaster
        //      #include "UnityCG.cginc"
 
        //      struct v2f 
        //      { 
        //          V2F_SHADOW_CASTER;
        //      };
 
        //      v2f vert( appdata_base v )
        //      {
        //          v2f o;
        //          TRANSFER_SHADOW_CASTER(o)
        //          return o;
        //      }
 
        //      float4 frag( v2f i ) : SV_Target
        //      {
        //          SHADOW_CASTER_FRAGMENT(i)
        //      }
        //      ENDCG
 
        //  }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.0
            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"
            #include "volume_render_textures_inc.cginc"

            uniform float4 z_step;
            sampler2D _CameraDepthTexture;
            sampler3D _Volume;

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
                float4 ver_c : TEXCOORD6; // clipspace
                float4 projPos : TEXCOORD7;
                // float4 vertex : SV_POSITION;
            };
            v2f vert (appdata v ,  out float4 vertex : SV_POSITION)
            {
                v2f o;
                o.uv = v.uv;
                o.ver_c = UnityObjectToClipPos(v.vertex);
                vertex = o.ver_c;
                o.ver_w = mul(unity_ObjectToWorld,v.vertex);
                o.ver_o = v.vertex;

                o.projPos = ComputeScreenPos(vertex);
                //ab ray
                o.ab_ray_p0 = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1.0f));
                o.z_step = mul(unity_WorldToObject, z_step.xyz);
                return o;
            }

            fixed4 frag (v2f i , UNITY_VPOS_TYPE screenPos : VPOS) : SV_Target
            {
                //camera depth calculation 
                //todo : use calculated scene depth in the ray marching to terminate ray if intersct 
                //with other object

                float depth_buffer_scene = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)).r;
                // cam_depth = LinearEyeDepth(cam_depth);

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
                col = rayMarch(_inter_p0_o, _inter_p1_o, i.z_step, i.ab_ray_p0,_Volume,depth_buffer_scene);

                //debug function
                // float c = debugPoint(float4(0,0,0,1), 0.04f, screenPos);

                return col;
            }
            ENDCG
        }
    }
}
