#if !defined(MYLIGHTING)
#define MYLIGHTING
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"
sampler2D  _AlbedoMap;
float4 _AlbedoMap_ST;
float _Metalic;
float _Smoothness;


struct VIN
{
	float4 pos : POSITION ;
	float3 nor : NORMAL;
	float2 uv : TEXCOORD0 ;
}; 
struct VOUT
{
	float4 pos : SV_POSITION ;
	float3 nor : NORMAL;
	float2 uv : TEXCOORD0 ;
	float3 pos_w : TEXCOORD1;
	SHADOW_COORDS(2)

	#if defined (VERTEXLIGHT_ON)
		float3 vertextLightCol : TEXCOORD3;
	#endif
};

void vertextLight(inout VOUT IN)
{
	#if defined (VERTEXLIGHT_ON)
	IN.vertextLightCol = Shade4PointLights( unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0, 
		unity_LightColor[0].xyz ,unity_LightColor[1].xyz ,unity_LightColor[2].xyz ,unity_LightColor[3].xyz ,
		unity_4LightAtten0 , IN.pos_w , IN.nor);
	#endif
}

VOUT vert(VIN IN)
{
	VOUT OUT;
	OUT.pos = UnityObjectToClipPos(IN.pos);
	OUT.nor = UnityObjectToWorldNormal(IN.nor);
	OUT.uv = IN.uv;
	OUT.pos_w = mul(unity_ObjectToWorld,IN.pos);
	TRANSFER_SHADOW(OUT);
	#if defined (VERTEXLIGHT_ON)
		vertextLight(OUT);
	#endif
	return OUT;
} 

UnityLight createDeLight(VOUT IN)
{
	UnityLight dLight;
	#if defined(POINT) || defined(SPOT)
		dLight.dir = normalize(_WorldSpaceLightPos0 - IN.pos_w) ;
	#else
		dLight.dir = _WorldSpaceLightPos0;
	#endif

	UNITY_LIGHT_ATTENUATION(attenuation , IN , IN.pos_w);

	dLight.color = _LightColor0 * attenuation;
	dLight.ndotl = DotClamped(IN.nor , dLight.dir);
	return dLight;
}

UnityIndirect creatInLight(VOUT IN)
{
	UnityIndirect light;
	light .diffuse = 0;	
	#if defined (VERTEXLIGHT_ON)
		light .diffuse = light .diffuse + IN.vertextLightCol;
	#endif
	#if defined (FORWARD_BASE_PASS)
		light .diffuse = light.diffuse + ShadeSH9(float4(IN.nor , 1));
	#endif

	light .specular = 0;	
	return light;
}

float4 frag(VOUT IN) : SV_TARGET
{
	float2 uv0 = TRANSFORM_TEX(IN.uv , _AlbedoMap);
	float3 albedo = tex2D(_AlbedoMap , uv0);
	float3 ViewVec = normalize(_WorldSpaceCameraPos - IN.pos_w);
	float3 specular;
	float OneMinusReflectivity;
	albedo = DiffuseAndSpecularFromMetallic(albedo,_Metalic,specular,OneMinusReflectivity);
	UnityLight dLight = createDeLight(IN);
	UnityIndirect iLight = creatInLight(IN);
	float4 col = UNITY_BRDF_PBS(albedo , specular , OneMinusReflectivity , _Smoothness ,IN.nor , ViewVec , dLight , iLight);

	//col = float4(ViewVec,1);
	return col;
}
#endif