Shader "Custom/T_Flow_Houdini"
{
    Properties
    {
        _AlbedoMap ("albedo", 2D) = "white" { }
        [gamma] _Metalic ("metalic",Range(0, 1))=0.5
        [gamma] _Roughness ("roughness",Range(0, 1))=0.5

        _UseFlow("flow0" , int) = 0
        _FlowMap ("flow", 2D) = "white" { }
        _FlowSpeed ("speed", Range(0.01, 2)) = 0.5
        _UseNoise ("use noise", Range(0, 1)) = 1
        _p0UV ("p0 uv", Vector) = (0, 0, 0, 0)
        _p1UV ("p1 uv", Vector) = (0.2, 0.2, 0, 0)
        _uvJump ("uv jump [p0x, p0y, p1x, p1y]", Vector) = (0.3, 0.6, 0.46, 0.73)

    }

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityPBSLighting.cginc"
            #pragma target 3.0

            sampler2D _AlbedoMap;
            float4 _AlbedoMap_ST;
            float _Metalic;
            float _Roughness;

			int _UseFlow;
            sampler2D _FlowMap;
            float4 _FlowMap_ST;
            float _FlowSpeed;
            float _UseNoise;
            float4 _p0UV;
            float4 _p1UV;
            float4 _uvJump;
            float OneMinusReflectivity;

            float3 COLOR_BLACK = float3(0, 0, 0);

            struct VIN
            {
                float4 pos : POSITION;
                float3 nor : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct VOUT
            {
                float4 pos : SV_POSITION;
                float3 nor : NORMAL;
                float2 uv : TEXCOORD0;
            };

            VOUT vert(VIN IN)
            {
                VOUT OUT;
                OUT.pos = UnityObjectToClipPos(IN.pos);
                OUT.nor = UnityObjectToWorldNormal(IN.nor);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 getFlow(float2 uv, int p0, float4 F, float speed, int useNoise, float2 jump)
            {
                float t = (_Time.y +  useNoise * F.a) * speed + p0 * 0.5f;
                float N = F.a;
                float4 OUT;

                float tLoop = frac(t );
                float a = 2 * (0.5 - abs(tLoop - 0.5));
                OUT.xy = uv + tLoop * F.xy + jump;
                OUT.w = a;
                return OUT;
            }

            float4 frag(VOUT IN) : SV_TARGET
            {
                float2 uv1 = TRANSFORM_TEX(IN.uv, _AlbedoMap);
                float2 uv_f0 = IN.uv * _p0UV.xy + _p0UV.zw;
                float2 uv_f1 = IN.uv * _p1UV.xy + _p1UV.zw;
                float4 flow0 = -(tex2D(_FlowMap, uv_f0) *2 -1);
                float4 flow1 = -(tex2D(_FlowMap, uv_f1) *2 -1);
                float4 uv_p0 = getFlow(uv1, 0, flow0, _FlowSpeed, _UseNoise, _uvJump.xy);
                float4 uv_p1 = getFlow(uv1, 1, flow1, _FlowSpeed, _UseNoise, _uvJump.zw);
                float3 A_p0 = tex2D(_AlbedoMap, uv_p0.xy);
                float3 A_p1 = tex2D(_AlbedoMap, uv_p1.xy);
                float3 A;
                if (_UseFlow == 0)
                {
                	A = tex2D(_AlbedoMap,uv1);
                }
                else
                {
                	A = lerp(A_p0, A_p1, uv_p1.w);	
                }
                

                float3 S;
                float smothness = 1 - _Roughness;
                float3 V = normalize(_WorldSpaceCameraPos - IN.pos);

                UnityLight dLight;
                dLight.dir = _WorldSpaceLightPos0;
                dLight.color = _LightColor0;
                dLight.ndotl = DotClamped(IN.nor, dLight.dir);
                UnityIndirect iLight;
                iLight.diffuse = 0;
                iLight.specular = 0;
                A = DiffuseAndSpecularFromMetallic(A, _Metalic, S, OneMinusReflectivity);
                float3 C = UNITY_BRDF_PBS(A, S, OneMinusReflectivity, smothness, IN.nor, V, dLight, iLight);

                float4 col = float4(A, 1);
                return col;
            }
            ENDCG

        }
    }
}
