
Shader "Custom/reflect"
{
    Properties
    {
        _Albedo("albedo", 2D) = "white"{}
        [noscaleoffset]_Normal("normal" , 2D) = "normal"{}
        [gamma]_Metalic("metalic" , range(0,1)) = 0.5
        [gamma]_Smooth("smoothness" , range(0,1)) = 0.5

    }
    SubShader 
    {
        Pass 
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag 
            #include "UnityPBSLighting.cginc"
            
            sampler2D _Albedo;
            float4 _Albedo_ST;
            sampler2D _Normal;
            float _Metalic;
            float _Smooth;

            struct VIN
            {
                float4 vertex : POSITION ;
                float3 nor : NORMAL ;
                float2 uv : TEXCOORD0 ; 
            };
            struct VOUT
            {
                float4 pos : SV_POSITION;
                float3 nor : NORMAL;
                float2 uv : TEXCOORD0 ; 
                float3 pos_w : TEXCOORD1;
            };
            VOUT vert(VIN v)
            {
                VOUT OUT;
                OUT.pos = UnityObjectToClipPos(v.vertex);
                OUT.nor = UnityObjectToWorldNormal(v.nor);
                OUT.uv = v.uv;
                OUT.pos_w = mul (unity_ObjectToWorld , v.vertex);
                return OUT;
            }
            UnityLight dLight(VOUT IN)
            {
                UnityLight l;
                l.dir = _WorldSpaceLightPos0;
                l.color = _LightColor0;
                l.ndotl = DotClamped(IN.nor , l.dir);
                return l;
            }
            UnityIndirect iLight (VOUT IN , half Sm ,half3 Rd)
            {
                UnityIndirect l;
                l.diffuse = 0;
                
                float Ro = 1- Sm;
                Unity_GlossyEnvironmentData envData;
                envData.roughness = 1- Sm;
                envData.reflUVW = BoxProjectedCubemapDirection(Rd, IN.pos_w, unity_SpecCube0_ProbePosition,unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
                float3 specular1 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0),unity_SpecCube0_HDR,envData);


                float interpolator = unity_SpecCube0_BoxMin.w;
                #if UNITY_SPECCUBE_BLENDING
                    if (interpolator <0.9999)
                    UNITY_BRANCH
                    {
                        envData.reflUVW = BoxProjectedCubemapDirection(Rd, IN.pos_w, unity_SpecCube1_ProbePosition,unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
                        float3 specular2 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0),unity_SpecCube1_HDR,envData);

                        l.specular = lerp(specular2,specular1,interpolator);
                    }
                    else
                    {
                        l.specular = specular1;
                    }
                #else
                    l.specular = specular1;

                #endif
                return l;
            }
            half4 frag(VOUT IN) : SV_TARGET
            {
                float2 uv0 = TRANSFORM_TEX(IN.uv , _Albedo);
                
                half3 Al = tex2D(_Albedo , uv0);
                half Me = _Metalic;
                half Sm = _Smooth;
                half3 Sp ;
                half OMR;
                half3 Vd;
                half3 No = IN.nor;
                Al = DiffuseAndSpecularFromMetallic(Al,Me, Sp ,OMR);

                Vd = normalize(_WorldSpaceCameraPos - IN.pos_w);
                half3 Rd = reflect(-Vd , No);
                UnityLight Dl = dLight (IN);
                UnityIndirect Il = iLight (IN , Sm ,Rd);
                half4 col = UNITY_BRDF_PBS(Al,Sp,OMR,Sm,No,Vd,Dl,Il);
                return col;
            }
            ENDCG
        }
    }
}
