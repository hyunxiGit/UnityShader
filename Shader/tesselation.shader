Shader "Custom/tesselation"
{
    Properties
    {
        _Color("Base Color", Color) = (1,1,1,1)
        _tAmount("Tesselation amount" , Range(1,64)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma target 4.6 // 4.6支持tesselation
            #pragma vertex myVert
            #pragma hull myHull
            #pragma domain myDomain
            #pragma geometry myGeom
            #pragma fragment myFrag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            float4 _Color;
            float _tAmount;
            struct appdata
            {
                float4 vertex : POSITION;
                float3 nor : NORMAL;
                float4 tan : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct TessellationControlPoint {
                //tesselation vert shader must output position using [INTERNALTESSPOS] semantic
                float4 pos : INTERNALTESSPOS;
                float3 nor : NORMAL;
                float4 tan : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct TessellationFactors {
                //2 factors required , outside esdge and inside edge
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            struct v2g
            {
            	float4 pos : SV_POSITION;
            	float2 uv : TEXCOORD0; 
                float3 nor : NORMAL;
                float4 tan : TANGENT;
            };

            struct g2f
            {
            	float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 nor : NORMAL;
                float4 tan : TANGENT;
            };

            TessellationControlPoint myVert (appdata v)
            {
                TessellationControlPoint o;
                o.pos = v.vertex;
                o.nor = v.nor;
                o.uv = v.uv;
                o.tan = v.tan;
                return o;
            }

            TessellationFactors myPatchConstant (InputPatch<TessellationControlPoint, 3> patch) {
                TessellationFactors f;
                f.edge[0] = _tAmount;
                f.edge[1] = _tAmount;
                f.edge[2] = _tAmount;
                f.inside = _tAmount;
                return f;
            }

            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_outputtopology("triangle_cw")]
            // [UNITY_partitioning("integer")]
            [UNITY_partitioning("fractional_odd")]
            [UNITY_patchconstantfunc("myPatchConstant")]
            TessellationControlPoint myHull ( InputPatch<TessellationControlPoint, 3> patch,uint id : SV_OutputControlPointID) 
            {
                return patch[id];
            }

            [UNITY_domain("tri")]
            v2g myDomain ( TessellationFactors factors, OutputPatch<TessellationControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) 
            {
                //SV_DomainLocation semantic : the relative vertex location to the control point
                //it is calculated by tessolator
                v2g data;
                #define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) data.fieldName = \
                    patch[0].fieldName * barycentricCoordinates.x + \
                    patch[1].fieldName * barycentricCoordinates.y + \
                    patch[2].fieldName * barycentricCoordinates.z;

                MY_DOMAIN_PROGRAM_INTERPOLATE(pos)
                MY_DOMAIN_PROGRAM_INTERPOLATE(nor)
                MY_DOMAIN_PROGRAM_INTERPOLATE(tan)
                MY_DOMAIN_PROGRAM_INTERPOLATE(uv)

                return data;
            }

            [maxvertexcount(3)]
            //最多输出三个点
            void myGeom(triangle v2g i[3], inout TriangleStream<g2f> triStream)
            {
            	g2f o;
                for (int j = 0 ; j<3 ;j++)
                {
                    o.pos = UnityObjectToClipPos(i[j].pos);
                    o.uv = i[j].uv;
                    o.nor = i[j].nor;
                    o.tan = i[j].tan;
                    triStream.Append(o);
                }
            }

            fixed4 myFrag (g2f i) : SV_Target
            {
                return _Color*dot(i.nor,_WorldSpaceLightPos0.xyz);
            }
            ENDCG
        }
    }
}
