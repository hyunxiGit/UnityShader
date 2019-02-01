Shader "Custom/template"
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
            UnityIndirect iLight (VOUT IN)
            {
                UnityIndirect l;
                l.diffuse = 0;
                l.specular = 0;
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
                UnityLight Dl = dLight (IN);
                UnityIndirect Il = iLight (IN);
                half4 col = UNITY_BRDF_PBS(Al,Sp,OMR,Sm,No,Vd,Dl,Il);
                return col;
            }
            ENDCG
        }
    }
}
