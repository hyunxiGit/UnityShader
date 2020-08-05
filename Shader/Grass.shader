Shader "Custom/Grass"
{
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
            struct geometryOutput
            {
                float4 pos : SV_POSITION;
            };

            struct appData
            {
                float4 vertex : POSITION;
                float3 nor : NORMAL;
                float4 tan : TANGENT;
            };

            struct v2g
            {
                float4 pos : SV_POSITION;
                float3 nor : NORMAL;
                float4 tan : TANGENT;
            };
            struct g2f
            {
                float4 pos : SV_POSITION;
                float3 nor : NORMAL;
                float4 tan : TANGENT;
            };

            v2g vert (appData i)
            {
                v2g o;
                o.pos = i.vertex;
                o.nor = i.nor;
                o.tan = i.tan;
                //vert 传入 geo应为object space
                return o;
            }

            [maxvertexcount(3)]
            //最多输出三个点
            void geom(triangle v2g i[3], inout TriangleStream<g2f> triStream)
            {
                //geometry输出为clip space
                g2f o;
                float scale = 0.11;

                float4 T = i[0].tan;
                float3 N = i[0].nor;
                float3 B = cross (N, T)*T.w;
                float3x3 tangentToLocal = float3x3(
                                            T.x, B.x, N.x,
                                            T.y, B.y, N.y,
                                            T.z, B.z, N.z
                                            );
                float3x3 O2T= float3x3( T.x, T.y, T.z,
                                        N.x,N.y,N.z,
                                        B.x,B.y,B.z 
                                        );
                
                for (int j=0 ; j<3 ; j++)
                {
                    int j1 = j-1;
                    //三个顶点 ： (-0.5,0,0,1),(0,1,0,1),(0.5,0,0,1)
                    float4  vertOff= scale*float4(0.5*float(j-1), 1-abs(j-1), 0, 1);
                    vertOff = float4(mul( vertOff.xyz, O2T),1);
                    //2 way convert object space to tangent space
                    //vertOff = float4(mul( tangentToLocal,vertOff.xyz, O2T),1);
                    o.pos = UnityObjectToClipPos(i[0].pos + vertOff); 
                    o.nor = i[0].nor;
                    o.tan = i[0].tan;
                    //convert local to tangent

                    triStream.Append(o);                    
                }

            }

            float4 frag (float4 vertex : SV_POSITION, fixed facing : VFACE) : SV_Target
            {   
                return float4(1, 0, 0, 1);
            }
            ENDCG
        }
    }
}
