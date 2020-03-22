Shader "Custom/testCamMatrix"
{
    Properties 
    {
        //_Maintexture("texture",2D) = "White"{}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4x4 _WorldToCameraMatrix;
            float4x4 _ProjectionMatrix;
            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };


            v2f vert (appdata v)
            {
                v2f o;
                /*
                This is a compare between the default Unity variable that can be access by shader and by script
                
                - UnityObjectToClipPos : convert model->view->projection
                it can be seperate as  :
                o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
                o.vertex = mul(UNITY_MATRIX_V,o.vertex); 
                o.vertex = mul(UNITY_MATRIX_P,o.vertex); 

                UNITY_MATRIX_V is thr same as camera.worldToCameraMatrix inscript
                UNITY_MATRIX_V is different from camera.projectionMatrix
                I don't know how to get the correct projection that is same as UNITY_MATRIX_P

                */
                // o.vertex = UnityObjectToClipPos(v.vertex);

                
  
                o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
                o.vertex = mul(UNITY_MATRIX_V, o.vertex);
                o.vertex = mul(_ProjectionMatrix,o.vertex); 


                 //o.vertex = mul(_WorldToCameraMatrix, o.vertex);
                 //o.vertex = mul(UNITY_MATRIX_V, o.vertex);

                 //o.vertex = mul(unity_CameraProjection, o.vertex);
                 //o.vertex = mul(_ProjectionMatrix, o.vertex);
                //o.vertex = mul(UNITY_MATRIX_P, o.vertex);


                //o.vertex = mul(UNITY_MATRIX_VP,o.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = float4(1,0,0,1);

                return col;
            }
            ENDCG
        }
    }
}
