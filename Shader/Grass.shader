Shader "Custom/Grass"
{
    Properties
    {
        _Scale("blade scale", Range(0.5,10)) = 5.0
    }
    SubShader
    {

        Cull Off // cull off 在前期调试很重要，因为三角形朝向不定
        Tags 
        {              
            "RenderType" = "Opaque"
            "LightMode" = "ForwardBase"
        }
        LOD 100
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #include "UnityCG.cginc"

            float _Scale;

            struct appData
            {
                float4 vertex : POSITION;
                float3 nor : NORMAL;
                float4 tan : TANGENT;
                float2 uv : TEXCOORD0; 
            };

            struct v2g
            {
                float4 pos : SV_POSITION;
                float3 nor : NORMAL;
                float4 tan : TANGENT;
                float2 uv : TEXCOORD0; 
            };
            struct g2f
            {
                float4 pos : SV_POSITION;
                float3 nor : NORMAL;
                float4 tan : TANGENT;
                float2 uv : TEXCOORD0;
            };

            v2g vert (appData i)
            {
                v2g o;
                o.pos = i.vertex;
                o.nor = i.nor;
                o.tan = i.tan;
                o.uv = i.uv;
                //vert 传入 geo应为object space
                return o;
            }

            [maxvertexcount(3)]
            //最多输出三个点
            void geom(triangle v2g i[3], inout TriangleStream<g2f> triStream)
            {
                //geometry输出为clip space
                g2f o;
                float scale = 1;

                float4 T = i[0].tan;
                float3 N = i[0].nor;
                float3 B = cross (N, T)*T.w;

                float3x3 O2T= float3x3( T.x, T.y, T.z,
                                        B.x,B.y,B.z,
                                        N.x,N.y,N.z
                                        );
                float3x3 blade_tri = _Scale*float3x3(0.5,0,0,
                                             -0.5,0,0,
                                              0,0,1);

                for (int j=0 ; j<3 ; j++)
                {
                    
                    float3  vertOffset = j==0?blade_tri[0]:(j==1?blade_tri[1]:blade_tri[2]);
                    vertOffset = float4(mul(vertOffset , O2T),1);
                    o.uv = i[0].uv;
                    o.pos = UnityObjectToClipPos(i[0].pos + vertOffset); 
                    o.nor = i[0].nor;
                    o.tan = i[0].tan;
                    triStream.Append(o);                    
                }

            }

            float4 frag (g2f i) : SV_Target
            {   
                return float4(i.uv, 0, 1);
            }
            ENDCG
        }
    }
}
