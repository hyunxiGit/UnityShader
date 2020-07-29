struct rayMarchStr
{
    float _DensityPara; //user control how dens the fog is
    float useShadow;
    float z_align;
    float4 _p0;         //enter point in obj space
    float4 _p1;         //out point in obj space
    float3 z_step;      //cam view march step
    float3 l_step;      //fog point light march step
    float4 cam_o;       //cam in obj space
    float zbuffer;   
    sampler3D _Volume;
    int full_steps;     //how many steps to travel from cam view 
    float _ShasowStepInt;//step length of a fog when accumulate shadow ,user input parameter
    float _lightScale;  //scale fog light to normalize
    float _UseShadow;
    float _UseFinalStep;
    float _UseFinalStepShadow;
};

void obb_intersect(float4 _ab_ray_p0 , float4 _ab_ray_p1 , out float4 p0_o , out float4 p1_o , out float4 p0_w ,out float4 p1_w )
{
    //object space intersection
    //_ab_ray_p0 ：camera
    //p0，p1 相交两点，若cam在volume中，则p0为cam - p1 反方向点
    float4 obb_min = float4(-0.5f,-0.5f,-0.5f,1.0f);
    float4 obb_max = float4(0.5f,0.5f,0.5f,1.0f);

    float3 ray_full = _ab_ray_p1 -_ab_ray_p0;
    float3 min_inter , max_inter; // intersection point

    float3 ray_min = obb_min - _ab_ray_p0;
    float3 ray_max = obb_max - _ab_ray_p0;

    float3 xyz_sclae_min;
    float3 xyz_sclae_max;

    //full ray on x , y , z value
    float3 ray_projected = float3( ray_full.x , ray_full.y , ray_full.z);
    ray_projected.x = ray_projected.x == 0.0f?0.00001f : ray_projected.x;
    ray_projected.y = ray_projected.y == 0.0f?0.00001f : ray_projected.y;
    ray_projected.z = ray_projected.z == 0.0f?0.00001f : ray_projected.z;

    float _x1 = ray_min.x / ray_projected.x;
    float _x2 = ray_max.x / ray_projected.x;

    xyz_sclae_min.x = _x1 < _x2 ? _x1 : _x2;
    xyz_sclae_max.x = _x1 > _x2 ? _x1 : _x2;

    float _y1 = ray_min.y / ray_projected.y;
    float _y2 = ray_max.y / ray_projected.y;

    xyz_sclae_min.y = _y1 < _y2 ? _y1 : _y2;
    xyz_sclae_max.y = _y1 > _y2 ? _y1 : _y2;

    float _z1 = ray_min.z / ray_projected.z;
    float _z2 = ray_max.z / ray_projected.z;

    xyz_sclae_min.z = _z1 < _z2 ? _z1 : _z2;
    xyz_sclae_max.z = _z1 > _z2 ? _z1 : _z2;

    float min_scale = max(max(xyz_sclae_min.x ,xyz_sclae_min.y),xyz_sclae_min.z);
    float max_scale = min(min(xyz_sclae_max.x ,xyz_sclae_max.y),xyz_sclae_max.z);

    //two intersect point in object space
    p0_o =float4(_ab_ray_p0.xyz + max(max(xyz_sclae_min.x  ,xyz_sclae_min.y),xyz_sclae_min.z) *ray_full,1);
    p1_o =float4(_ab_ray_p0.xyz + min(min(xyz_sclae_max.x  ,xyz_sclae_max.y),xyz_sclae_max.z) *ray_full,1);
    //two intersect point in object space
    p0_w = float4(mul(unity_ObjectToWorld,p0_o).xyz,1);
    p1_w = float4(mul(unity_ObjectToWorld, p1_o).xyz,1);       

    // p0_o = p0_w;  
    // p1_o = p1_w;  

    bool min_exist=false;
    bool max_exist=false;

    if ( min_scale < max_scale)
    {
        if (min_scale > 0 && min_scale <1)
        {
            min_exist=true;
        }

        if(max_scale > 0 && max_scale <1 )
        {
            max_exist=true;
        }
    }
}

float debugPoint(float4 p ,float s,  UNITY_VPOS_TYPE screenPos)
{   
    //print a white dot at p (object space), with size s
    // p : point position , s: point size in float 
    p = ComputeScreenPos (UnityObjectToClipPos(p));
    //p point in screen uv (0-1)
    float2 uv_p = p.xy / p.w;
    //screen space uv (0-1)
    float2 uv_screen = screenPos / _ScreenParams ;
    float2 circle = (uv_p - uv_screen);
    circle.y*=_ScreenParams.y/_ScreenParams.x;
    float c = step(length(circle),s);
    return c;
}

void get_p0_step(inout rayMarchStr stru)
{
    //zstep传入的时候有价值的只有长度，（0,0,step）world -> object
    //calculate the p0 (first interact point) with z align and no z align
    //若cam在volume 中则需要对起始点进行调整
    float3 ray_dir = normalize(stru._p1-stru.cam_o);
    //>0 : inside， <=0 outside 
    //避免p0,cam重叠
    stru._p0 = float4(dot((stru._p0 - stru.cam_o),ray_dir)>0?stru._p0 : stru.cam_o + 0.01*ray_dir,1); 
    //cam 向前方向 dir
    float3 cDir = normalize(mul(unity_WorldToObject,mul((float3x3)unity_CameraToWorld, float3(0,0,1))));
    //cam 向前每一步vector
    float3 cStep = cDir*length(stru.z_step);
    stru.z_step.xyz = cStep.xyz;
    if (stru.z_align == 0)
    {
        float3 ray_full = stru._p1 - stru._p0;
        stru.z_step = normalize(ray_full)*length(stru.z_step);
        stru.full_steps = ceil(length(ray_full) / length(stru.z_step));
    }
    else
    {
        //以O为anchor做平面
        // 【co】 cam->O,cube中心`
        float3 co = float3(0,0,0) - cStep;
        // 【coPrj】 cam向前vec，L为vec 上 O齐平点
        // 【len_coPrj】 coPrj带符号长度 /cDir
        float len_coPrj = dot(co,cDir);
        float3 coPrj = dot(co,cDir)*cDir;
        // 【len_cStep】 cam step 的带符号长度 /cDir
        float len_cStep = dot(cStep , cDir);
        // 【scale_cl_cStep】 cStep/coPrj 倍数
        float scale_cStep_coPrj = len_cStep / len_coPrj;

        //【cp0】 cam到第一个接触点
        float3 cp0 = stru._p0.xyz -stru.cam_o;
        float3 mDir = normalize(cp0);
        //【cp0】 prj CL 长度
        float len_cp0Prj = dot(cp0 ,cDir);
        //【s_coPrj_cp0Prj】 coPrj为cp0Prj多少倍
        float s_coPrj_cp0Prj = len_coPrj / len_cp0Prj;
        //【coPrj1】oPrj1为 p0 p1 上 O 平面上点 
        float3 coPrj1 = cp0*s_coPrj_cp0Prj;
        float3 oPrj1 = stru.cam_o.xyz + coPrj1;
        // 【z_step】 march step
        stru.z_step = coPrj1*scale_cStep_coPrj;
        //[cp0Prj] cp0 cam dir的projection
        float3 cp0Prj = len_cp0Prj*cDir;
        //[p0_prj_O] 从cp0Prj到coPrj
        float3 cp0Prj_coPrj = coPrj - cp0Prj;
        float len_cp0Prj_coPrj = dot(cp0Prj_coPrj,cDir);
        //从M点反推p0新位置
        stru._p0.xyz= oPrj1 - ceil(len_cp0Prj_coPrj/len_cStep)*stru.z_step;                     
        stru.full_steps = dot(stru._p1-stru._p0,mDir)/ dot(stru.z_step,mDir);   
    }
}

void accumulate(inout float step_density , float v ,float len_step)
{
    //v为采样
    float3 fogColor = float3(1,1,1);
    step_density = step_density + len_step * v;
}

float calLight(float step_density,float light_distance)
{
    float transmittance = exp( - step_density *light_distance );
    return transmittance;
}

float sampleVolumen(sampler3D _Volume , float3 uvw , float _DensityPara)
{
    return tex3Dlod(_Volume, float4(uvw + float3(0.5,0.5,0.5),0)).r * _DensityPara;
}

float shadowFactor(float3 p1, float3 l_step ,float len_l_step ,  sampler3D _Volume , float _DensityPara ,float shadow_dens_p_v, float i , float len_z_step , float _ShasowStepInt)
{
    //need add final step to avoid artifect
    float shadow_dens_l_p = 0;//从march点p向light方向累计的fog density

    float j;
    float3 p_l = p1;
    int _step = 0;
    float opacity = sampleVolumen(_Volume , p_l , _DensityPara );
    for (j = 0 ; j <20 ; j++)
    {

        p_l = p_l + l_step;
        if ( p_l.x>0.5 || p_l.y>0.5 || p_l.z>0.5 ||p_l.x<-0.5 || p_l.y<-0.5 || p_l.z<-0.5)
            break;  
        _step = j;
        shadow_dens_l_p +=  len_l_step * sampleVolumen(_Volume , p_l , _DensityPara ) ;
    }

    float transmittance_l_p = exp( - shadow_dens_l_p * _step * len_l_step * _ShasowStepInt);
    float transmittance_p_v = exp( - shadow_dens_p_v * i * len_z_step * _ShasowStepInt);
    
    //opacity ,加了之后会变的很奇怪,以后需要再看
    //opacity = 1;
    return transmittance_l_p * transmittance_p_v * opacity;
}

// work in the loop which can only handle constance
#define steps 128
#define step_size 0.01
float4 rayMarch(rayMarchStr stru)
{
    get_p0_step(stru);
    float len_z_step = length(stru.z_step);
    float step_density = 0;
    int ITERATION = 30;
    float3 p0 = stru._p0.xyz;
    float3 p1 = stru._p0.xyz;
    float4 p0_c = UnityObjectToClipPos(p0);
    float4 p1_c = p0_c;
    float d0 = 0;
    float d1 = 0;
    float4 col = float4(1,1,0,1); 
    //calculate light march step
    float shadow_dens_p_v = 0;
    //light march使用和z step一样的长度
    float len_l_step = len_z_step;
    stru.l_step = len_l_step * stru.l_step ;
    float3 fogColor = float3(1,1,1);
    float fogLight = stru._UseShadow > 0.98 ? 0:1;
    for (int i = 0 ; i <ITERATION ; i++)
    {
        if (i > stru.full_steps) break;
        p0 = p1;
        d0 = d1;
        p0_c = p1_c;
        p1 = stru._p0.xyz + i *stru.z_step;
        float v = sampleVolumen(stru._Volume, p1 ,stru._DensityPara);
        shadow_dens_p_v +=  len_z_step * v;

        //todo : optimize clip space calculation,simple calculate p1_c and z_step will not work, because w will be different in different step
        //research the projection matrix , find out if possible find out w
        p1_c = UnityObjectToClipPos(p1);
        d1 = p1_c.z / p1_c.w; 

        if (d1 < stru.zbuffer) 
        {
             if (stru._UseFinalStep < 0.01)
             {
                break;
             }
            //can be optimize
            //final step , sample on the scene object surface to avoid slice artifact
            //calculate z buffer 3d position in clip space
            float d = stru.zbuffer==0 ? 0.0001 : stru.zbuffer;
            // 已知 p1 p0 为clip 上两点, d 为 p点 depth buffer, 求出 pz pw 为 p 点clip 上3d 坐标
            float a = p1_c.z - p0_c.z ;
            float b = p1_c.w - p0_c.w;
            float _devid = b-a/d; 
            _devid = _devid == 0? 0.0001 : _devid;
            float pz_c = (b*p0_c.z - a*p0_c.w)/_devid;
            float pw_c = pz_c/d;
            //此处pz_c pw_c 正确
            col = float4(pz_c,pw_c,0,1);
            //求scale = p.z-p0.z /p0.z-p1.z, object space 和 clip space值为一样
            _devid = p1_c.z - p0_c.z;
            _devid = _devid == 0? 0.0001 : _devid;
            float s = (pz_c - p0_c.z)/_devid;
            // 此处是否正好在球面上?
            p1 = p0 + s *stru.z_step;
            v = sampleVolumen(stru._Volume , p1 , stru._DensityPara ) ;
            //每step opacity为1, 按照final step大小scale 相对于整步的opacity
            accumulate(step_density , v ,len_z_step*s);
            if (stru._UseFinalStepShadow > 0.0001)
            {
                if (stru._UseShadow > 0.98)
                {
                    if (v>0.01 )
                    {
                        float shadowTrans =  shadowFactor( p1, stru.l_step, len_l_step, stru._Volume , stru._DensityPara ,shadow_dens_p_v, i-1+s , len_z_step , stru._ShasowStepInt);
                        fogLight = fogLight +  shadowTrans/stru._lightScale;
                    }
                }
            }
            
            fogColor = fogColor * fogLight ;
            float transmittance = calLight(step_density, len_z_step*i + len_z_step*s);
            return float4(fogColor,1-transmittance);
        }

        step_density += v  * len_z_step;
        //accumulate(step_density , v ,len_z_step);
        if (stru._UseShadow > 0.98)
        {
            if (v>0.01 )
            {
                float shadowTrans =  shadowFactor( p1, stru.l_step, len_l_step, stru._Volume , stru._DensityPara ,shadow_dens_p_v, i , len_z_step , stru._ShasowStepInt);
                fogLight = fogLight +  shadowTrans/stru._lightScale;
            }
        }        
    }
    fogColor = fogColor * fogLight ;
    float transmittance = calLight(step_density, len_z_step * i);
    return float4(fogColor,1-transmittance); 
    // return col;        
}