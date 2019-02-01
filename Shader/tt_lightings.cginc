#if ! defined(MY_LIGHTS)
    #define MY_LIGHTS
    #pragma target 3.0
    #include "UnityPBSLighting.cginc"
    #include "AutoLight.cginc"
    sampler2D _Albedo;
    float4 _Albedo_ST;
    sampler2D _Normal;
    float _NormalScale;
    float _Metalic;
    float _Smooth;

    struct VIN
    {
        float4 vertex : POSITION ;
        float3 nor : NORMAL ;
        float4 tan : TANGENT;
        float2 uv : TEXCOORD0 ; 
    };
    struct VOUT
    {
        float4 pos : SV_POSITION;
        float3 nor : NORMAL;
        float2 uv : TEXCOORD0 ; 
        float3 pos_w : TEXCOORD1;
        float3 tan : TEXCOORD2;
        float3 bi : TEXCOORD3;
        #if defined (VERTEXLIGHT_ON)
            float3 vL : TEXCOORD4;
        #endif
    };

    void vLight (inout VOUT IN)
    {
        #if defined (VERTEXLIGHT_ON)
            IN.vL = Shade4PointLights( unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0, 
        unity_LightColor[0].xyz ,unity_LightColor[1].xyz ,unity_LightColor[2].xyz ,unity_LightColor[3].xyz ,
        unity_4LightAtten0 , IN.pos_w , IN.nor);
        #endif
    }

    VOUT vert(VIN v)
    {
        VOUT OUT;
        OUT.pos = UnityObjectToClipPos(v.vertex);
        OUT.nor = UnityObjectToWorldNormal(v.nor);
        OUT.tan = UnityObjectToWorldDir(v.tan.xyz);
        OUT.bi = normalize(cross(OUT.nor , OUT.tan) * v.tan.w * unity_WorldTransformParams.w);
        OUT.uv = v.uv;
        OUT.pos_w = mul (unity_ObjectToWorld , v.vertex);
        #if defined (VERTEXLIGHT_ON)
            vLight(OUT); 
        #endif
        return OUT;
    }
    UnityLight dLight(VOUT IN)
    {
        UnityLight l;
        l.dir = _WorldSpaceLightPos0;
        #if defined (SPOT) || defined (POINT) 
            l.dir = normalize(l.dir - IN.pos_w);
        #endif
        UNITY_LIGHT_ATTENUATION(att , IN , IN.pos_w);
        l.color = _LightColor0 * att;
        l.ndotl = DotClamped(IN.nor , l.dir);
        return l;
    }
    UnityIndirect iLight (VOUT IN)
    {
        UnityIndirect l;
        l.diffuse = 0;
        #if defined (VERTEXLIGHT_ON)
            l.diffuse = l.diffuse + IN.vL; 
        #endif
        l.specular = 0;
        return l;
    }
    half4 frag(VOUT IN) : SV_TARGET
    {
        float2 uv0 = TRANSFORM_TEX(IN.uv , _Albedo);
        
        half3 Al = tex2D(_Albedo , uv0);
        half3 No = UnpackScaleNormal(tex2D(_Normal , uv0) , 0.01).xzy ;
        No = normalize(No.x * IN.tan * _NormalScale + No.y * IN.nor + No.z * IN.bi * _NormalScale);
        IN.nor = No;
        half Me = _Metalic;
        half Sm = _Smooth;
        half3 Sp ;
        half OMR;
        half3 Vd;
        
        Al = DiffuseAndSpecularFromMetallic(Al,Me, Sp ,OMR);

        Vd = normalize(_WorldSpaceCameraPos - IN.pos_w);
        UnityLight Dl = dLight (IN);
        UnityIndirect Il = iLight (IN);
        half4 col = UNITY_BRDF_PBS(Al,Sp,OMR,Sm,No,Vd,Dl,Il);

        return col;
    }
#endif