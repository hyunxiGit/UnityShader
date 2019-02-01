Shader "Custom/normal"
{
    Properties
    {
        _Albedo ("albedo", 2D) = "white" { }
        [NoScaleOffset] _Normal ("normal",2D)="normal" { }
        [gamma] _NormalScale ("normal scale",float) = 0.1
        [gamma] _Metalic ("metalic",Range(0, 1)) = 0
        [gamma] _Smoothness ("smoothness",Range(0, 1)) = 0.5
        _DA("detail albedo" , 2d)="white"{}
        [NoScaleOffset]_DN("detail normal" , 2d)="normal"{}
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityPBSLighting.cginc"
            sampler2D _Albedo;
            float4 _Albedo_ST;
            sampler2D _Normal;
            float _Metalic;
            float _Smoothness;
            float _NormalScale;
            sampler2D _DA;
            float4 _DA_ST;
            sampler2D _DN;

            struct VIN
            {
                float4 pos : POSITION;
                float3 nor : NORMAL;
                float4 tan : TANGENT;
                float2 uv : TEXCOORD0;
            };
            struct VOUT
            {
                float4 pos : SV_POSITION;
                float4 pos_w : TEXCOORD1;
                float3 nor : NORMAL;
                float2 uv : TEXCOORD0;
                float3 tan : TEXCOORD2;
                float3 bi : TEXCOORD3;
            };

            VOUT vert(VIN IN)
            {
                VOUT OUT;
                OUT.pos = UnityObjectToClipPos(IN.pos);
                OUT.nor = UnityObjectToWorldNormal(IN.nor);
                OUT.tan = UnityObjectToWorldDir(IN.tan.xyz);
                OUT.bi = normalize (cross(OUT.nor , OUT.tan.xyz) * IN.tan.w*unity_WorldTransformParams.w);
                OUT.pos_w = mul(unity_ObjectToWorld, IN.pos);
                OUT.uv = IN.uv;
                return OUT;
            }

            UnityLight dLight(VOUT IN)
            {
                UnityLight light;
                light.dir = _WorldSpaceLightPos0;
                light.color = _LightColor0;
                light.ndotl = DotClamped(IN.nor, light.dir );
                return light;
            }

            UnityIndirect iLight(VOUT IN)
            {
                UnityIndirect light;
                light.diffuse = 0;
                light.specular = 0;
                return light; 
            }

            half4 frag(VOUT IN) : SV_TARGET
            {
                float4 uv;
                uv.xy = TRANSFORM_TEX(IN.uv, _Albedo);
                uv.zw = TRANSFORM_TEX(IN.uv, _DA);

                half3 Al = tex2D(_Albedo, uv.xy);
                half3 No = UnpackScaleNormal (tex2D(_Normal, uv.xy),0.01);
                half3 Da = tex2D(_DA , uv.zw);
                half3 Dn = UnpackScaleNormal(tex2D(_DN , uv.zw),0.01);

                Al =Al * Da * unity_ColorSpaceDouble;
                
                No.xyz = No.xzy;
                Dn.xyz = Dn.xzy;

                No = BlendNormals(No , Dn);    
                No = normalize (IN.tan * No.x * _NormalScale + IN.nor * No.y + IN.bi * No.z*_NormalScale);

                half3 Sp;
                half OneMinusRe;
                Al = DiffuseAndSpecularFromMetallic(Al, _Metalic, Sp , OneMinusRe);

                UnityLight Dl = dLight(IN);
                UnityIndirect Il = iLight(IN);

                half3 Vd = normalize(_WorldSpaceCameraPos - IN.pos_w.xyz);

                half4 col;
                col = UNITY_BRDF_PBS(Al, Sp , OneMinusRe , _Smoothness , No, Vd, Dl , Il );
                return col;
            }
            ENDCG
        }
    }
}