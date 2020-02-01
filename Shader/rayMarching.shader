Shader "Custom/rayMarching"
{
    Properties 
    {
        _MainTex("texture",2D) = "White"{}
        [noscaleoffset]_DisplacementMap("displacement map" , 2d) = "white"{}
        _displacementStrength("displacement strength", range(0,1)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        pass
        {
            Tags {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "UnityPBSLighting.cginc"

            sampler2D _DisplacementMap;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _displacementStrength;

            struct VIN
            {
                float4 pos : POSITION;
                float3 nor : NORMAL;
                float2 uv : TEXCOORD0 ; 
            };
            struct VOUT
            {
                float4 pos : SV_POSITION;
                float3 nor : NORMAL;
                float2 uv : TEXCOORD0 ; 
                float3 pos_w : TEXCOORD1 ;
            };

            VOUT vert(VIN IN)
            {
                VOUT OUT;
                OUT.pos = UnityObjectToClipPos(IN.pos);
                OUT.nor = UnityObjectToWorldNormal(IN.nor);
                OUT.pos_w = mul(unity_ObjectToWorld , IN.pos);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag(VOUT IN):SV_TARGET
            {
                float3 Vd = _WorldSpaceCameraPos - IN.pos_w ;
                float2 uv = TRANSFORM_TEX(IN.uv, _MainTex);
                float2 deltaUV = float2(Vd.x,Vd.z)  ;
                uv -= deltaUV*_displacementStrength*0.05;
                //albedo
                float4 albedo = tex2D(_MainTex, uv);
                float3 l_dir = _WorldSpaceLightPos0;

                //float lighting = DotClamped(IN.nor,l_dir) ;

                float4 col;
                col = albedo;
                
                return col;
            }
            ENDCG
        }
    }
    
}
