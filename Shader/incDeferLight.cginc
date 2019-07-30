#if !defined (INC_DEFER_LIGHT)
#define INC_DEFER_LIGHT
#include "UnityPBSLighting.cginc"
#include "incDeferLight.cginc"

UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

sampler2D _CameraGBufferTexture0;
sampler2D _CameraGBufferTexture1;
sampler2D _CameraGBufferTexture2;
sampler2D _CameraGBufferTexture3;
#if defined (SHADOWS_SCREEN)
	sampler2D _ShadowMapTexture;
#endif

#if defined (POINT_COOKIE)
	samplerCUBE _LightTexture0;
#else
	sampler2D _LightTexture0;
#endif

sampler2D _LightTextureB0;
float4x4 unity_WorldToLight;
float _LightAsQuad;

float4 _LightColor, _LightDir, _LightPos;

struct Vin
{
    float4 pos : POSITION;
    float3 nor : NORMAL;
};

struct Vout
{
    float4 pos : SV_POSITION;
    float4 uv : TEXCOORD0;
    float3 ray : TEXCOORD1;
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
    
    //reconstruct the far plane ray 1
    //the OUT.ray here:
    //IN.nor : the ray to fullscreen quad vertex, the ray is written in normal
    //UnityObjectToViewPos(IN.pos) : the ray to light volume vertex.

    //?????I don't quite understand the float3(-1,-1,1) where x y got inverted however the z is the same, why the ray is inverted , I think viewspace coord should be (pos_w - pos_camera)
    OUT.ray = lerp(UnityObjectToViewPos(IN.pos) * float3(-1,-1,1) , IN.nor ,_LightAsQuad);
    return OUT;
}



UnityLight dLight (float2 uv, float3 pos_w , float viewZ)
{
	UnityLight l;
	l.dir = -_LightDir;
	l.color = _LightColor;
	float3 lightVec ;
	float shadowAtt = 1;
	float cookieAtt = 1;
	float lightAtt = 1;
	//directional light
    #if defined(DIRECTIONAL) || defined (DIRECTIONAL_COOKIE)
        l.dir = -_LightDir;
        lightVec = -_LightDir;
    #endif
	#if defined (DIRECTIONAL_COOKIE)
		float4 pos_l = mul(unity_WorldToLight, float4(pos_w, 1));
		cookieAtt = tex2Dbias(_LightTexture0 , float4(pos_l.xy , 0,-8));
	#endif

	//spot and point light vector
	#if defined (SPOT) || defined (POINT) ||(POINT_COOKIE)
		lightVec = _LightPos - pos_w;
        l.dir = normalize(lightVec);
	#endif
	#if defined (SPOT)
		//spot cookie attenuation
		float4 uvCookie = mul(unity_WorldToLight, float4(pos_w, 1));
		uvCookie.xy /= uvCookie.w;
		cookieAtt *= tex2Dbias(_LightTexture0, float4(uvCookie.xy, 0, -8)).w;
		cookieAtt *= uvCookie.w<0;
		//the distance attenuation
		cookieAtt *= tex2D(_LightTextureB0 , (dot(lightVec,lightVec)*_LightPos.w).xx).UNITY_ATTEN_CHANNEL;
	#endif

	//POINT and POINT_COOKIE are seperate branches
	#if defined(POINT) || defined (POINT_COOKIE)
		cookieAtt *= tex2D(_LightTextureB0 , (dot(lightVec,lightVec)*_LightPos.w).xx).UNITY_ATTEN_CHANNEL;
		#if defined (POINT_COOKIE)
			//use light direction as sample
			float3 uvCookie = mul(unity_WorldToLight, float4(pos_w, 1)).xyz;
			cookieAtt *= texCUBEbias(_LightTexture0,float4(uvCookie , -8)).w;
		#endif
	#endif

	//shadows
	//direct lightshadow
	#if defined (SHADOWS_SCREEN)
		shadowAtt = tex2D(_ShadowMapTexture , uv);
		
	#endif
	// spot light shadow
	#if defined (SHADOWS_DEPTH)
		//UnitySampleShadowmap can not be found in the doc, it takes care of sampling the shadow for a deferred spotlight , the parameter passed in is pos in shadow coordinate
		shadowAtt = UnitySampleShadowmap(mul(unity_WorldToShadow[0] , float4(pos_w,1)));

	#endif
	//point light shadow
	#if defined (SHADOWS_CUBE)
		shadowAtt = UnitySampleShadowmap (-lightVec);
	#endif
	
	//shadow fade
	half shadowFadeDistance = UnityComputeShadowFadeDistance(pos_w , viewZ);
	float shadowFade = UnityComputeShadowFade(shadowFadeDistance);
	shadowAtt = saturate (shadowAtt + shadowFade);
	#if defined(UNITY_FAST_COHERENT_DYNAMIC_BRANCHING) && defined(SHADOWS_SOFT)
		UNITY_BRANCH
		if (shadowFade > 0.99) {
		shadowAtt = 1;
		}
	#endif
		
	

	l.color = _LightColor * shadowAtt * cookieAtt ;

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
    //reconstruct the far plane ray 2
    //scale up the ray until it reach far plane._ProjectionParams.z = camera far plane
    float3 ray_f = IN.ray * _ProjectionParams.z /IN.ray.z;
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
	#if !defined(UNITY_HDR_ON)
		OUT.col.rgb = exp2(-OUT.col.rgb);
	#endif
    return OUT;
}
#endif