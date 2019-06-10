Shader "Custom/deferredFog"
{
    Properties
    {
        //the texture will be fileed in automatically by Camera script
        _MainTex("main texture" , 2d) = "white"{}
    }
    SubShader
    {
        Pass {
            Cull Off
            ZTest Always
            ZWrite Off
            Tags { "RenderType"="Opaque" }
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            sampler2D _MainTex;

            struct vIn
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0; 
            };
            struct pIn
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0; 
            };

            pIn vert(vIn IN)
            {
                pIn OUT;
                OUT.pos = UnityObjectToClipPos(IN.pos);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag(pIn IN):SV_TARGET
            {
                float4 col = tex2D(_MainTex , IN.uv);
                return col ;
            }
            ENDCG
        }
    }

}
