Shader "Custom/flataFaced"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2g
            {
            	float4 pos : SV_POSITION;
            	float2 uv : TEXCOORD0; 
            	float4 pos_w :TEXCOORD1;
            };

            struct g2f
            {
            	float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 pos_w :TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2g vert (appdata v)
            {
                v2g o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.pos_w = v.vertex;
                return o;
            }

            [maxvertexcount(3)]
            //最多输出三个点
            void geom(triangle v2g i[3], inout TriangleStream<g2f> triStream)
            {
            	g2f o;
            	o.pos = i[0].pos;
            	o.uv = i[0].uv;
            	o.pos_w = i[0].pos_w;
				triStream.Append(o);
            	o.pos = i[1].pos;
            	o.uv = i[1].uv;
            	o.pos_w= i[1].pos_w;
				triStream.Append(o);
            	o.pos = i[2].pos;
            	o.uv = i[2].uv;
            	o.pos_w = i[2].pos_w;

            	triStream.Append(o);

            }

   //          float3 GetAlbedoWithWireframe (Interpolators i) {
			// 	float3 albedo = float3(1,1,1);
			// 	float3 barys;
			// 	barys.xy = i.barycentricCoordinates;
			// 	barys.z = 1 - barys.x - barys.y;
			// 	float3 deltas = fwidth(barys);
			// 	float3 smoothing = deltas * _WireframeSmoothing;
			// 	float3 thickness = deltas * _WireframeThickness;
			// 	barys = smoothstep(thickness, thickness + smoothing, barys);
			// 	float minBary = min(barys.x, min(barys.y, barys.z));
			// //	return albedo * minBary;
			// 	return lerp(_WireframeColor, albedo, minBary);
			// }

            fixed4 frag (g2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float3 dpdx = ddx(i.pos_w);
				float3 dpdy = ddy(i.pos_w);
				float3 normal = normalize(cross(dpdy, dpdx));
                return col*dot(normal,_WorldSpaceLightPos0.xyz);
            }
            ENDCG
        }
    }
}
