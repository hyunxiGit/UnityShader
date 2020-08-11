Shader "Custom/GeometryFramework"
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

            float4 vert (float4 vertex : POSITION): SV_POSITION
            {
                //vert 传入 geo应为object space
                return vertex;
            }

            [maxvertexcount(3)]
            //最多输出三个点
            void geom(triangle float4 IN[3] : SV_POSITION, inout TriangleStream<geometryOutput> triStream)
            {
                //geometry输出为clip space
                geometryOutput o;

                o.pos = float4(0.5, 0, 0, 1);
                triStream.Append(o);

                o.pos = float4(-0.5, 0, 0, 1);
                triStream.Append(o);

                o.pos = float4(0, 1, 0, 1);
                triStream.Append(o);
            }

            float4 frag (float4 vertex : SV_POSITION, fixed facing : VFACE) : SV_Target
            {   
                return float4(1, 0, 0, 1);
            }
            ENDCG
        }
    }
}
