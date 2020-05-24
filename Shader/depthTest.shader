Shader "Custom/depthTest"
{
    Properties
    {
        _Volume ("Volume", 3D) = "" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        // ZWrite On
        // Tags { "Queue"="Transparent" "RenderType"="Transparent"}
        LOD 100
        //simple shadow Pass to use _CameraDepthTexture for this object
        Pass 
         {
             Name "ShadowCaster"
             Tags { "LightMode" = "ShadowCaster" }
             
             Fog {Mode Off}
             ZWrite On ZTest LEqual Cull Off
             Offset 1, 1
 
             CGPROGRAM
             #pragma vertex vert
             #pragma fragment frag
             #pragma multi_compile_shadowcaster
             #include "UnityCG.cginc"
 
             struct v2f 
             { 
                 V2F_SHADOW_CASTER;
             };
 
             v2f vert( appdata_base v )
             {
                 v2f o;
                 TRANSFER_SHADOW_CASTER(o)
                 return o;
             }
 
             float4 frag( v2f i ) : SV_Target
             {
                 SHADOW_CASTER_FRAGMENT(i)
             }
             ENDCG
 
         }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.0
            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"
            sampler2D _CameraDepthTexture;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 projPos : TEXCOORD1;
                float4 depth : TEXCOORD2;
                float4 vertex_o : TEXCOORD3;
            };


            v2f vert (appdata v )
            {
                v2f o;
                o.uv = v.uv;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.projPos = ComputeScreenPos(o.vertex);
                //eye space depth
                o.depth = float4(-mul(UNITY_MATRIX_MV, v.vertex).z *_ProjectionParams.w,0,0,0);
                o.vertex_o = v.vertex;
                return o;
            }

            fixed4 frag (v2f i ) : SV_Target
            {
                //get depth from depth texture, cam_d has same value as dpeth buffer
                float4 cam_d = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)).r;
                
                //解析方法 ------------------------
                float zbuffer_depth = LinearEyeDepth (cam_d.r);  
                //和zbuffer 最爲接近
                float screenDepth = DecodeFloatRG(cam_d.r);

                float cam_linear_depth = Linear01Depth(cam_d.r);
                //似乎是1-zbuffer
                float partZ = i.projPos.z;   

                //以下都为zbuffer值 : 
                float frag_calculate_vertex_clip_value = UnityObjectToClipPos(i.vertex_o).z/UnityObjectToClipPos(i.vertex_o).w;
                float vertex_zbuffer = i.vertex.z;
                float cam_texture_z = cam_d ;
                return float4(i.vertex.z, frag_calculate_vertex_clip_value, screenDepth, i.depth.x);
            }
            ENDCG
        }
    }
}
