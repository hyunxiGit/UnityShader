//capture screen depth and save as a texture : shader
//render target example
//post process backbon , pass cam frustrum to shader and build 3d pos
Shader "Hidden/CamDepthFrustrum"
 {
     Properties
     {
         _MainTex ("Base (RGB)", 2D) = "white" {}
         _DepthLevel ("Depth Level", Range(1, 3)) = 1
     }
     SubShader
     {
         Pass
         {
             CGPROGRAM
 
             #pragma vertex vert
             #pragma fragment frag
             #include "UnityCG.cginc"
             
             uniform sampler2D _MainTex;
             uniform sampler2D _CameraDepthTexture;
             uniform fixed _DepthLevel;
             uniform half4 _MainTex_TexelSize;
             float4x4 _InverseProjectionMatrix;
             float4x4 _InverseViewMatrix;
             float3 _FrustumCorners[4];
 
             struct input
             {
                 float4 pos : POSITION;
                 half2 uv : TEXCOORD0;
             };
 
             struct output
             {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
                float3 Ray : TEXCOORD1;
             };
 
 
             output vert(input i)
             {
                output o;
                o.pos = UnityObjectToClipPos(i.pos);
                o.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, i.uv);
                // why do we need this? cause sometimes the image I get is flipped. see: http://docs.unity3d.com/Manual/SL-PlatformDifferences.html
                #if UNITY_UV_STARTS_AT_TOP
                if (_MainTex_TexelSize.y < 0)
                        o.uv.y = 1 - o.uv.y;
                #endif
                o.Ray = _FrustumCorners[o.uv.x+ 2*o.uv.y];
 
                return o;
             }

             //this part doesn't work yet
            float4 GetViewSpacePosition(float2 uv)
            {
                //depth depth, non linear,camera depth
                float depth = tex2Dlod(_CameraDepthTexture, float4( uv, 0, 0));
                //view space depth
                depth = LinearEyeDepth(depth);
                depth = pow(depth, _DepthLevel);
                //result
                float4 result = mul(_InverseProjectionMatrix, float4(2.0 * uv - 1.0, depth, 1.0));
                result = result / result.w;
                //world pos
                //result = mul(_InverseViewMatrix, result);      

                //for debug depth
                //depth = pow(LinearEyeDepth(depth), _DepthLevel);
                //return float4(depth,depth,depth,1);

                return float4(normalize(result.xyz),1);
            }

            float getDepth(float2 uv)
            {
                float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
                depth = pow(depth, _DepthLevel);
                return (depth);
            }

            float4 calculateWorldPosFromCameraFrustrum(output IN)
            {
                float depth = getDepth(IN.uv);
                float3 pos_v = depth * IN.Ray;

                return float4(pos_v,1);
            }


             fixed4 frag(output IN) : SV_TARGET
             {

                float4 c = calculateWorldPosFromCameraFrustrum(IN);
                float depth = getDepth(IN.uv);
                return float4(depth,depth,depth,1);
             }
             
             ENDCG
         }
     } 
 }