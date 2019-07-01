#if !defined (INC_DEFER_LIGHT)
#define INC_DEFER_LIGHT
#include "UnityPBSLighting.cginc"
#include "UnityShaderVariables.cginc"

UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

sampler2D _CameraGBufferTexture0;
sampler2D _CameraGBufferTexture1;
sampler2D _CameraGBufferTexture2;
sampler2D _CameraGBufferTexture3;
sampler2D _ShadowMapTexture;

struct Vin
{
    float4 pos : POSITION;
    float3 nor : NORMAL;
};

struct Vout
{
    float4 pos : SV_POSITION;
    float4 uv : TEXCOORD0;
    float3 ray_n : TEXCOORD1;
};
struct Fout
{
    float4 col : SV_Target;
};

Vout vert (Vin IN)
{
    Vout OUT;
    OUT.pos = UnityObjectToClipPos(IN.pos);
    OUT.uv = ComputeScreenPos(OUT.pos);
    OUT.ray_n = IN.nor;
    return OUT;
}

UnityLight dLight (float2 uv, float3 pos_w , float viewZ)
{
	UnityLight l;
	l.dir = _WorldSpaceLightPos0;
	l.color = _LightColor0;
	float shadowAtt = 1;
	#if defined (SHADOWS_SCREEN)
		shadowAtt = tex2D(_ShadowMapTexture , uv);
		half shadowFadeDistance = UnityComputeShadowFadeDistance(pos_w , viewZ);
		float shadowFade = UnityComputeShadowFade(shadowFadeDistance);
		shadowAtt = saturate (shadowAtt + shadowFade);
		l.color = _LightColor0 * shadowFade;
	#endif
	//l.color = _LightColor0 * shadowAtt;
	return l;
}

UnityIndirect iLight()
{
	UnityIndirect l;
	l.diffuse = 0;
    l.specular = 0;
	return l;
}

Fout frag (Vout IN)
{
    Fout OUT;
    float2 uv = IN.uv.xy/IN.uv.w;

    float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv.xy));
    
    float3 ray_f = IN.ray_n * _ProjectionParams.z /_ProjectionParams.y;
    
    float3 pos_v = depth * ray_f;
    float3 pos_w = mul(unity_CameraToWorld , float4(pos_v,1));

    half3 Di = tex2D(_CameraGBufferTexture0,uv).rgb;
    half3 Sp = tex2D(_CameraGBufferTexture1,uv).rgb;
    half Sm = tex2D(_CameraGBufferTexture1,uv).a;
    float3 No = tex2D(_CameraGBufferTexture2,uv).rgb *2-1;

    float3 Vd = normalize(_WorldSpaceCameraPos - pos_w);
    UnityLight dL = dLight(uv ,pos_w , pos_v.z);
	UnityIndirect iL = iLight();

	half Omr = 1 - SpecularStrength(Sp);
    OUT.col = half4(No,1);
    OUT.col = UNITY_BRDF_PBS(Di, Sp, Omr, Sm ,No , Vd, dL, iL);
 	
	half shadowFadeDistance = UnityComputeShadowFadeDistance(pos_w , pos_v.z);

    return OUT;
}
#endif