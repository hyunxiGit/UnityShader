//sample 3d texture is done.
//todo : make it a volume use tracing
Shader "Custom/sudou3dTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        //_MainTex_Resolution ("Texture Resolution", Int) = 2048
        _MainTex_Row ("Texture Row", float) = 12.0
        _MainTex_Collumn ("Texture Collumn", float) = 12
        _zIndex("z index", range(0,1)) = 1.0
        _3dTextureDepth("3d texture depth", range(0,5)) = 3.0

    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True" }

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _MainTex_Row;
            float _MainTex_Collumn;
            float mainIndex;
            float _zIndex;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 nor : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 nor : NORMAL;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            float4 sample3DTextureByIndex(sampler2D tex , float3 xyz ,float row, float column , float i)
            {
                float2 uv;    

                int x_index = i - floor(i/column) *column;
                int y_index = floor(i/column);

                //float uv_x_gap : 1 / column; xyz.x /column : turn input uv to local uv scala
                // uv_y_gap : 1 / row;
                uv.x = x_index / column + xyz.x /column; 
                uv.y = y_index / row + xyz.y/row; 
                

                //need scale the uv to half size, center and make padding

                float4 c = float4(1,0,0,1);
                c.a = tex2D(tex, uv).x;


                

                return c;
            }

            float4 sample3DTexture(sampler2D tex , float3 xyz , float row, float column)
            {
                float index = xyz.z * row * column;

                float i = floor(index);
                float j = ceil(index);
                
                float4 c1 = sample3DTextureByIndex(tex ,xyz, row, column, i);
                float4 c2 = sample3DTextureByIndex(tex ,xyz, row, column, j);
                float4 c = lerp(c1,c2,frac(index));

                return c1;
            }




            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.nor = UnityObjectToWorldNormal(v.nor);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // use float3(uvw) to sample the texture , all range from 0 to 1
                fixed4 col = sample3DTexture(_MainTex, float3(i.uv,_zIndex), _MainTex_Row, _MainTex_Collumn);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
