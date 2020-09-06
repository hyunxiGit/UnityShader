// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/Grass"
{
    Properties
    {
        _windMap("wind map" , 2d) = "white" {}
        _windFreq("wind Speed" , Vector) = (1,1,1,1)
        _tessFactor("grass amount", Range (1,64)) = 5.0
        _bendScale ("bend forward" , Range (0 , 1)) = 0.2
        _curveScale ("curve" , Range(0,4)) = 2
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
            #pragma target 4.6 // 4.6支持tesselation
            #pragma vertex myVert
            #pragma hull myHull  
            #pragma domain myDomain           
            #pragma geometry myGeom
            #pragma fragment myFrag
            #include "UnityCG.cginc"
            #include "UnityStandardUtils.cginc"

            float _tessFactor;
            float _bendScale;
            float _curveScale;
            float _Scale;
            float3 _TopColor;
            float3 _BottomColor;      

            sampler2D _windMap; 
            float4 _windMap_ST;
            float4 _windFreq;

            //--structures--
            struct appData
            {
                float4 vertex : POSITION;
                float3 nor : NORMAL;
                float4 tan : TANGENT;
                float2 uv : TEXCOORD0; 
            };

            struct TessellationControlPoint {
                //tesselation vert shader must output position using [INTERNALTESSPOS] semantic
                float4 pos : INTERNALTESSPOS;
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

            //--structures--

            //--util functions--

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

            //--util functions--

            //--vertex--

            TessellationControlPoint myVert (appData i)
            {
                TessellationControlPoint o;
                o.pos = i.vertex;
                o.nor = i.nor;
                o.tan = i.tan;
                o.uv = i.uv;
                //vert 传入 geo应为object space
                return o;
            }

            //--vertex--

            //----tesselation----
            
            struct TessellationFactors
            {
                float edge[3]   : SV_TessFactor;
                float inside    : SV_InsideTessFactor;
            };

            TessellationFactors myPatchConstant(InputPatch<TessellationControlPoint,3> patch)
            {
                TessellationFactors f;
                f.edge[0]   = _tessFactor;
                f.edge[1]   = _tessFactor;
                f.edge[2]   = _tessFactor;
                f.inside    = _tessFactor;
                return f;
            }

            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_partitioning("integer")]
            [UNITY_patchconstantfunc("myPatchConstant")]
            TessellationControlPoint myHull (InputPatch<TessellationControlPoint,3> patch , uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }

            [UNITY_domain("tri")]
            v2g myDomain (TessellationFactors f, OutputPatch<TessellationControlPoint,3> patch , float3 barycentricCoordinates : SV_DomainLocation)
            {
                v2g o;
                #define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) o.fieldName = \
                        patch[0].fieldName  * barycentricCoordinates.x + \
                        patch[1].fieldName  * barycentricCoordinates.y + \
                        patch[2].fieldName  * barycentricCoordinates.z ;

                o.pos = MY_DOMAIN_PROGRAM_INTERPOLATE(pos)
                o.nor = MY_DOMAIN_PROGRAM_INTERPOLATE(nor)
                o.tan = MY_DOMAIN_PROGRAM_INTERPOLATE(tan)
                o.uv = MY_DOMAIN_PROGRAM_INTERPOLATE(uv)

                return o;
            }

            //----tesselation----
            #define seg 4
            #define vert_count seg*2+1
            #define inc_x 0.5/uint(seg)
            #define inc_y 1.0/uint(seg)
            [maxvertexcount(vert_count)]
            //最多输出三个点
            void myGeom(triangle v2g i[3], inout TriangleStream<g2f> triStream)
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

                //rotate angle
                float angle;
                //rotate matrix
                float3x3 rM;
                ran0 = rand(i[0].pos);
                ran1 = rand(i[0].pos.zyx);
                //loop three points of grass blade
                for (int j=0 ; j<vert_count ; j++)
                {

                    //grass topology 
                    //    6
                    //  5  4
                    //  3  2
                    //  1  0
                    //计算生成点相对于输入点位置
                    float _x = (1-j%2*2)*(0.5-floor(float(j)/2)*inc_x);
                    float _z = floor(float(j/2))*inc_y;
                    float3  vertOffset = float3(_x,0,_z);
                    o.uv = float2(_x+0.5,_z);


                    //width height random
                    vertOffset.x*= ran0*0.2;
                    vertOffset.y*= ran0*0.2;
                    vertOffset.z*= ran1*0.2 + 0.6; //0.8~1
                    

                    //z rotate,random facing

                    angle = ran0*UNITY_TWO_PI;
                    float3x3 rM_face = AngleAxis3x3(angle, float3(0,0,1));

                    //x rotate,random bending
                    ran1 = ran1 ;
                    angle = ran1*UNITY_TWO_PI*_bendScale;
                    //apply curve by associate the bend degree with how close the vertex is to the bottom
                    angle = angle * pow(_z , _curveScale);
                    float3x3 rM_bend = AngleAxis3x3(angle, float3(1,0,0));

                    //wind
                    //scale the uv (world position used to sample wind)
                    float2 uv = i[0].pos.xy*_windMap_ST.xy + _windMap_ST.zw + _Time.y *_windFreq.xy;
                    //create the wind vector from wind texture
                    half2 wind_s = tex2Dlod(_windMap, float4(uv, 0, 0)).xy*2-1;
                    half3 wind_vec = normalize (float3 (wind_s,0));
                    //convert to tangent space
                    wind_vec = mul(unity_WorldToObject, wind_vec);
                    wind_vec = mul(O2T,wind_vec);

                    float3x3 rM_wind = AngleAxis3x3(wind_s.x, wind_vec);

                    float3x3 rm_bottom = mul(rM_face,rM_bend);
                    float3x3 rm_top = mul(rM_wind,rm_bottom);

                    //为top点添加风矩阵 为bottom点添加普通矩阵
                    rM = (j==0||j ==1)? rm_bottom : rm_top ;

                    //rotate in tangent space
                    vertOffset = mul(rM , vertOffset);

                    //tangent to object space
                    vertOffset = float4(mul(vertOffset , O2T),1);
                    


                    o.pos = UnityObjectToClipPos(i[0].pos + _Scale * vertOffset); 
                    o.nor = i[0].nor;
                    o.tan = i[0].tan;
                    triStream.Append(o);                    
                }

            }

            float4 myFrag (g2f i) : SV_Target
            {   
                float2 uv = i.pos.xy*_windMap_ST.xy + _windMap_ST.zw + _Time.y *_windFreq.xy;
                half2 wind_vec = tex2D(_windMap, uv).xy;
                float4 col = float4(lerp(_TopColor,_BottomColor,i.uv.y),1);

                
                return col;
            }
            ENDCG
        }
    }
}
