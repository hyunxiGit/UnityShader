Shader "Custom/rayMarching"
{
    Properties 
    {

        [HideInInspector]_ScrBlend("screen blend" , float) = 1
        [HideInInspector]_DstBlend("desty blend" , float) = 0
        [HideInInspector]_ZWri("ZWrite control" , float) = 0
        _MainTex("Albedo texture",2D) = "White"{}
        [noscaleoffset]_GridTex("grid texture",2D) = "White"{}
        [noscaleoffset]_DisplacementMap("displacement map" , 2d) = "white"{}
        _displacementStrength("displacement strength", range(0,1)) = 1.0
    }
    SubShader
    {
        Tags {  "Queue"="Transparent" "RenderType"="Transparent" }
        pass
        {
            Tags {
                "LightMode" = "ForwardBase"
            }
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "UnityPBSLighting.cginc"

            sampler2D _DisplacementMap;
            sampler2D _GridTex;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _displacementStrength;

            struct VIN
            {
                float4 pos : POSITION;
                float3 nor : NORMAL;
                float4 tan : TANGENT;
                float2 uv : TEXCOORD0 ; 
            };
            struct VOUT
            {
                float4 pos : SV_POSITION;
                float3 nor : NORMAL;
                float2 uv : TEXCOORD0 ; 
                float3 pos_w : TEXCOORD1 ;
                float3 tan : TEXCOORD2;
                float3 bi  : TEXCOORD3;
            };

            VOUT vert(VIN IN)
            {
                VOUT OUT;
                OUT.pos = UnityObjectToClipPos(IN.pos);
                OUT.nor = UnityObjectToWorldNormal(IN.nor);
                OUT.tan = UnityObjectToWorldDir(IN.tan.xyz); 
                OUT.bi = normalize(cross(OUT.nor , OUT.tan.xyz) * IN.tan.w * unity_WorldTransformParams.w); 
                OUT.pos_w = mul(unity_ObjectToWorld , IN.pos);
                OUT.uv = IN.uv;
                return OUT;
            }

            float raymarch( float height_map_value, float3 march_vector , int steps )
            {
                //retuurn the scale of result point / full height
                int cur_step = 0;
                int last_step = 0;

                float max_height = march_vector.z;

                float increment = 1/float(steps);
                float ac_value = 0;

                while((ac_value <1)&&(ac_value<height_map_value) )
                {
                        ac_value+=increment;
                }

                return ac_value;
            }

            float reverseHeightMapTrace( inout float2 uv , float3 march_vector , int steps ,int max_length)
            {
                float incr = 1.0/float(steps);
                float accu = 0.0;
                int cur_step = 0
                int last_step = 0
                float3 full_march_vector = march_vector ;
                float trace_height = -1;
                float reverse_map_height = 0;
                float2 uv_shift = float2(0,0);
                while ((accu<1)&&(cur_height<reverse_map_height))
                {
                    last_step = cur_step;
                    accu += incr;
                    cur_step +=1;
                    uv_shift = uv+ full_march_vector.xz * accu;
                    trace_height =  abs(full_march_vector.y * accu);
                    reverse_map_height = 1 - tex2D(_DisplacementMap, uv_shift).x ;
                }
                uv = uv_shift;      
            }


            float raymarch_shadow( float3 march_vector , int steps ,float uv0, float3x3 WtT)
            {
                //retuurn the scale of result point / full height
                float shadow_att = 1;
                int cur_step = 0;
                int last_step = 0;

                float start_height = tex2D(_DisplacementMap, uv0).x;
                float max_height_map_gap = 1- start_height;

                float increment = 0.01;
                float ac_value = 0;

                while(ac_value <1)
                {
                        ac_value +=increment;
                        float3 ac_vector = march_vector * ac_value;
                        float2 uv1 = uv0 + mul(ac_vector, WtT).xy *_displacementStrength *0.1;
                        //uv1 = uv0 - float2(0.01,0.01)*ac_value;
                        float height_map_value_gap = (tex2D(_DisplacementMap, uv1).x - start_height)/max_height_map_gap;
                        float trace_height_map_gap = ac_value;
                        if(trace_height_map_gap < height_map_value_gap)
                        {
                            ac_value = 1;
                            shadow_att = 0;
                        }
                }
                return 1;
                // return shadow_att;
            }

            float4 getAlbedo(float2 uv)
            {
                float4 col = tex2D(_MainTex, uv) * tex2D(_GridTex, uv);
                return col;
            }


            float4 frag(VOUT IN):SV_TARGET
            {
                float3 Vd = _WorldSpaceCameraPos - IN.pos_w ;
                float2 uv0 = TRANSFORM_TEX(IN.uv, _MainTex);

                //world to tangent
                float3x3 WtT= transpose(float3x3(IN.tan ,  IN.bi ,IN.nor));

                //trace from eye to world position in tangent space, x and z will be u and v, y is normal
                float3 trace_vector_t = normalize( mul(N.pos_w -_WorldSpaceCameraPos, WtT));

                float3 ori_pos = IN.pos_w;
                reverseHeightMapTrace( IN.uv , trace_vector_t , 10 ,1);


                //ray march
                // float scale2 = raymarch(height_map_value, trace_vector , 5);  

                //conver the trace_vector to world space to uv space
                // trace_vector *= scale2;              
                // float2 deltaUV = mul(trace_vector, WtT).xy;


               //uv1 is the uv after trace
                // float maxHight = 0.1;
                // float2 uv1 = uv0 + deltaUV *_displacementStrength *0.1 ;

                //new pos after shift height
                //float3 pos_w = IN.pos_w + IN.nor * tex2D(_DisplacementMap, uv1).x * _displacementStrength;

                // float3 l_dir = normalize(_WorldSpaceLightPos0) ;
                // float shadow_att = raymarch_shadow( l_dir , 10 ,uv0,  WtT);
                
                //albedo
                float4 albedo = getAlbedo(uv1);
               

                float lighting = DotClamped(IN.nor,l_dir) ;

                float4 col;
                col = float4(albedo.rgb* shadow_att,1) ;
                
                return col;
            }
            ENDCG
        }
    }
    
}
