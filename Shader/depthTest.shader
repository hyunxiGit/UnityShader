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
                //和 i.depth.x 有10倍的關係，是 i.depth.x 的 0-1的remap？
                float zbuffer_depth = LinearEyeDepth (tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)).r);  
                //和zbuffer 最爲接近
                float screenDepth = DecodeFloatRG(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)).r);
                //似乎是1-zbuffer
                float partZ = i.projPos.z;      
                return float4(zbuffer_depth, partZ, screenDepth, i.depth.x);
            }
            ENDCG
        }
    }
}
