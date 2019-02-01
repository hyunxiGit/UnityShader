#if !defined (MY_LIGHT) 
#define MY_LIGHT
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"
sampler2D _Albedo; 
float4 _Albedo_ST; 
float _Metalic;
float _Smoothness;

struct VIN
{
	float4 vertex : POSITION ;
	float3 nor : NORMAL;
	float3 uv : TEXCOORD0 ; 
};
struct VOUT
{
	float4 pos : SV_POSITION ;
	float3 nor : TEXCOORD1;
	float3 uv : TEXCOORD0 ;
	float4 worldPos : TEXCOORD2 ;
	SHADOW_COORDS(3)
	#if defined(VERTEXLIGHT_ON)
		float3 vetCol : TEXCOORD4;
	#endif

};
UnityLight GetDirectLight(VOUT IN)
{
	UnityLight l;
	#if defined (SPOT)||defined (POINT)
		l.dir = normalize (_WorldSpaceLightPos0 - IN.worldPos);
	#else
		l.dir = _WorldSpaceLightPos0;
	#endif
	UNITY_LIGHT_ATTENUATION(att , IN, IN.worldPos.xyz);
	l.color = _LightColor0 * att;
	l.ndotl = DotClamped(IN.nor , l.dir);
	return l;
}
UnityIndirect GetIndirectLight( VOUT IN)
{
	UnityIndirect l;
	l.diffuse = ShadeSH9(float4(IN.nor ,1));
	l.specular = 0;
	#if defined(VERTEXLIGHT_ON)
		l.diffuse += IN.vetCol;
	#endif
	return l;
}
void GetVertLight(inout VOUT IN)
{
	#if defined(VERTEXLIGHT_ON)
		IN.vetCol = Shade4PointLights(unity_4LightPosX0,unity_4LightPosY0, unity_4LightPosZ0 , 
			unity_LightColor[0].xyz , unity_LightColor[1].xyz , unity_LightColor[2].xyz ,unity_LightColor[3].xyz ,
			unity_4LightAtten0, IN.worldPos , IN.nor);
	#endif
}
VOUT vert(VIN v)
{
	VOUT OUT;
	OUT.pos = UnityObjectToClipPos(v.vertex);
	OUT.nor = UnityObjectToWorldNormal(v.nor);
	OUT.worldPos = mul(unity_ObjectToWorld , v.vertex);
	OUT.uv = v.uv;
	TRANSFER_SHADOW(OUT)
	#if defined(VERTEXLIGHT_ON)
		GetVertLight(OUT);
	#endif
	return OUT;
}
half4 frag(VOUT IN) : SV_TARGET
{

	half3 Sp;
	half Om;
	half Me = _Metalic;
	half Sm = _Smoothness;
	half3 No = IN.nor;
	float2 uv = TRANSFORM_TEX(IN.uv , _Albedo);
	half3 Di = tex2D(_Albedo, uv);
	float3 Vd = normalize(_WorldSpaceCameraPos - IN.worldPos.xyz); 
	Di = DiffuseAndSpecularFromMetallic(Di , Me,  Sp, Om);

	UnityLight Dl =  GetDirectLight(IN);
	UnityIndirect Il =  GetIndirectLight(IN);
	half3 col = UNITY_BRDF_PBS(Di, Sp , Om, Sm , No , Vd , Dl, Il);

	return half4(col,1);
}
#endif