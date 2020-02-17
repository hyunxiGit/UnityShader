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

            // Texture2D _DisplacementMap;
            // SamplerState sampler_DisplacementMap; 

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

            float4 getAlbedo(float2 uv)
            {
                float4 col = tex2D(_MainTex, uv) * tex2D(_GridTex, uv);
                return col;
            }

            float getDisplacement(float2 uv)
            {
                //float col = _DisplacementMap.SampleLevel(sampler_DisplacementMap, uv, 0).x;
                float col = tex2D(_DisplacementMap, uv);
                return col;
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



            void reverseHeightMapTrace( inout float2 uv , float3 march_vector , int steps)
            {
                //apply displacement height by scale the trace vector, height map, height_plane position
                 float height_plane = 1.0 * _displacementStrength;
                //(x,y,1)
                march_vector = march_vector/abs(march_vector.z); //[z: 0 ~ 1]
                march_vector *= _displacementStrength; //[z: 0 ~ _displacementStrength]
                
                float step_scale = 1.0/float(steps);
                float cur_scale = 0.0;
                float last_scaleh =0.0;
 
                
                float trace_height = 0;
                float reverse_map_height = -1;
                float2 uv_delta = float2(0,0);
                while ((cur_scale<1)&&(trace_height>reverse_map_height))
                {
                    last_scaleh = cur_scale;
                    float3 cur_march_vector = march_vector* cur_scale;
                    uv_delta = cur_march_vector.xy;
                    trace_height = cur_march_vector.z;
                    //[height: 0 ~ _displacementStrength] - _displacementStrength
                    reverse_map_height = tex2D(_DisplacementMap, uv + uv_delta).x *_displacementStrength - height_plane;
                    cur_scale += step_scale;
                }
                //interpolate to the middle point
                float use_scale = (last_scaleh + cur_scale) * 0.5;
                float3 cur_march_vector = march_vector* use_scale;
                uv_delta = cur_march_vector.xy;
                uv = uv + uv_delta;      
            }


            // float raymarch_shadow( float3 march_vector , int steps ,float uv0, float3x3 WtT)
            // {
            //     //retuurn the scale of result point / full height
            //     float shadow_att = 1;
            //     int cur_step = 0;
            //     int last_step = 0;

            //     float start_height = tex2D(_DisplacementMap, uv0).x;
            //     float max_height_map_gap = 1- start_height;

            //     float increment = 0.01;
            //     float ac_value = 0;

            //     while(ac_value <1)
            //     {
            //             ac_value +=increment;
            //             float3 ac_vector = march_vector * ac_value;
            //             float2 uv1 = uv0 + mul(ac_vector, WtT).xy *_displacementStrength *0.1;
            //             //uv1 = uv0 - float2(0.01,0.01)*ac_value;
            //             float height_map_value_gap = (tex2D(_DisplacementMap, uv1).x - start_height)/max_height_map_gap;
            //             float trace_height_map_gap = ac_value;
            //             if(trace_height_map_gap < height_map_value_gap)
            //             {
            //                 ac_value = 1;
            //                 shadow_att = 0;
            //             }
            //     }
            //     return 1;
            //     // return shadow_att;
            // }


            float4 frag(VOUT IN):SV_TARGET
            {
                float3 Vd = _WorldSpaceCameraPos - IN.pos_w ;
                float2 uv0 = TRANSFORM_TEX(IN.uv, _MainTex);

                //world to tangent
                float3x3 WtT= transpose(float3x3(IN.tan ,  IN.bi ,IN.nor));

                //trace from eye to world position in tangent space, x and z will be u and v, y is normal
                float3 trace_vector_t =  mul(normalize(IN.pos_w -_WorldSpaceCameraPos), WtT);

                //this step enable _displacementStrength easy to control on GUI
                _displacementStrength *=0.1; 

                reverseHeightMapTrace( IN.uv , trace_vector_t , 100 );


                float4 albedo = getAlbedo(IN.uv);
               

                float4 col;
                col = float4(albedo.rgb,1) ;
                
                return col;
            }
            ENDCG
        }
    }
    
}
