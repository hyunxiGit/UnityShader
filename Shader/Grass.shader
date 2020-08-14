Shader "Custom/Grass"
{
    Properties
    {
        _Scale("blade scale", Range(0.5,10)) = 5.0
        _TopColor("Top Color", Color) = (0,0,0,1)
        _BottomColor("Bottom Color", Color) = (1,1,1,1)
    }
    SubShader
    {

        Cull Off // cull off 在前期调试很重要，因为三角形朝向不定
        Tags 
        {              
            "RenderType" = "Opaque"
            "LightMode" = "ForwardBase"
        }
        LOD 100
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #include "UnityCG.cginc"

            float _Scale;
            float3 _TopColor;
            float3 _BottomColor;       

            struct appData
            {
                float4 vertex : POSITION;
                float3 nor : NORMAL;
                float4 tan : TANGENT;
                float2 uv : TEXCOORD0; 
            };

            struct v2g
            {
                float4 pos : SV_POSITION;
                float3 nor : NORMAL;
                float4 tan : TANGENT;
                float2 uv : TEXCOORD0; 
            };
            struct g2f
            {
                float4 pos : SV_POSITION;
                float3 nor : NORMAL;
                float4 tan : TANGENT;
                float2 uv : TEXCOORD0;
            };

            float rand(float3 co)
            {
                return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
            }

            // Construct a rotation matrix that rotates around the provided axis, sourced from:
            // https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
            float3x3 AngleAxis3x3(float angle, float3 axis)
            {
                float c, s;
                sincos(angle, s, c);

                float t = 1 - c;
                float x = axis.x;
                float y = axis.y;
                float z = axis.z;

                return float3x3(
                    t * x * x + c, t * x * y - s * z, t * x * z + s * y,
                    t * x * y + s * z, t * y * y + c, t * y * z - s * x,
                    t * x * z - s * y, t * y * z + s * x, t * z * z + c
                    );
            }

            v2g vert (appData i)
            {
                v2g o;
                o.pos = i.vertex;
                o.nor = i.nor;
                o.tan = i.tan;
                o.uv = i.uv;
                //vert 传入 geo应为object space
                return o;
            }

            [maxvertexcount(3)]
            //最多输出三个点
            void geom(triangle v2g i[3], inout TriangleStream<g2f> triStream)
            {
                //geometry输出为clip space
                g2f o;
                float scale = 1;
                float ran0;
                float ran1;

                float4 T = i[0].tan;
                float3 N = i[0].nor;
                float3 B = cross (N, T)*T.w;

                float3x3 O2T= float3x3( T.x, T.y, T.z,
                                        B.x,B.y,B.z,
                                        N.x,N.y,N.z
                                        );
                float3x3 blade_tri = float3x3(0.5,0,0,
                                         -0.5,0,0,
                                          0,0,1);

                //rotate angle
                float angle;
                //rotate matrix
                float3x3 rM;

                //loop three points of grass blade
                for (int j=0 ; j<3 ; j++)
                {
                    ran0 = rand(i[0].pos);
                    ran1 = rand(i[0].pos.zzx);
                    
                    float3  vertOffset = j==0?blade_tri[0]:(j==1?blade_tri[1]:blade_tri[2]);
                    o.uv = j==0?float2(1,0):(j==1?float2(0,0):float2(0.5,1));

                    //width height random
                    vertOffset[0]*= ran0*0.2;
                    vertOffset[1]*= ran0*0.2;
                    vertOffset[2]*= ran1*0.2 + 0.6; //0.8~1

                    //z rotate
                    angle = ran0*UNITY_TWO_PI;
                    rM = AngleAxis3x3(angle, float3(0,0,1));
                    vertOffset = mul(rM , vertOffset);  

                    //x rotate
                    angle = ran1*UNITY_PI*0.5;
                    rM = AngleAxis3x3(angle, float3(1,0,0));
                    vertOffset = mul(rM , vertOffset);

                    //tangent to object space
                    vertOffset = float4(mul(vertOffset , O2T),1);
                    
                    o.pos = UnityObjectToClipPos(i[0].pos + _Scale * vertOffset); 
                    o.nor = i[0].nor;
                    o.tan = i[0].tan;
                    triStream.Append(o);                    
                }

            }

            float4 frag (g2f i) : SV_Target
            {   
                float4 col = float4(lerp(_TopColor,_BottomColor,i.uv.y),1);
                return col;
            }
            ENDCG
        }
    }
}
