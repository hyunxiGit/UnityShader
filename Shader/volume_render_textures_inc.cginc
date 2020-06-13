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

void get_p0_step(bool z_align , inout float4 _p0, float4 _p1,  inout float3 z_step, float4 cam_o, out int full_steps)
{
    //若cam在volume 中则需要对起始点进行调整
    float3 ray_dir = normalize(_p1-cam_o);
    float3 p_start = dot((_p0 - cam_o),ray_dir)>0?_p0 : cam_o;

    if (z_align) 
    {
        //calculate the p0 (first interact point) with z align and no z align
        //the plane alignment should be calculated on cam pos as origin
        //calculate new start point and zstep
        float3 p0_cam = _p0 -cam_o;
        float3 z_dir = normalize(z_step);
        //step on p0-p1 align z plane
        float3 p_step = p0_cam * dot(z_step , z_dir) / dot(p0_cam,z_dir);

        float3 p0_z_pro = dot(p0_cam, z_dir)*z_dir;
        float scale_p0 = dot(p0_z_pro , z_dir);
        float scale_z_step = dot(z_step , z_dir);
        int scale_p0_z_step = ceil(scale_p0 / scale_z_step);
        float3 z_plane = scale_p0_z_step * z_step;
        //position
        _p0.xyz = scale_p0_z_step * scale_z_step /scale_p0 * p0_cam + cam_o;  
        _p0.w = 1;
        z_step = p_step;
        full_steps = floor(length(_p1 -_p0) / length(p_step));
    }
    else
    {
        _p0 = float4(p_start,1);
        float3 ray_full = _p1 - _p0;
        float scale = length(z_step) / length(ray_full) ;
        z_step = ray_full * scale;
        full_steps = ceil(length(ray_full) / length(z_step));
    }

}
// work in the loop which can only handle constance
#define steps 128
#define step_size 0.01
float4 rayMarch(  float4 _p0, float4 _p1 , float3 z_step ,float4 cam_o, sampler3D _Volume,float zbuffer)
{
    int full_steps;
    bool z_align = false;
    get_p0_step(z_align,_p0, _p1, z_step, cam_o, full_steps);
    float4 dst = float4(0, 0, 0, 0);
    float _Threshold = 0.8;
    int ITERATION = 100;
    float3 p0 = _p0.xyz;
    float3 p1 = _p0.xyz;
    float4 p0_c = UnityObjectToClipPos(p0);
    float4 p1_c = p0_c;
    float d0 = 0;
    float d1 = 0;
    float4 col = float4(1,1,0,1); 
    for (int i = 0 ; i <ITERATION ; i++)
    {
        p0 = p1;
        d1 = d0;
        p0_c = p1_c;
        p1 = _p0.xyz + i *z_step;
        float v = tex3D(_Volume, p1 + float3(0.5,0.5,0.5)).r ;

        //todo : optimize clip space calculation,simple calculate p1_c and z_step will not work, because w will be different in different step
        //research the projection matrix , find out if possible find out w
        p1_c = UnityObjectToClipPos(p1);
        d0 = p1_c.z / p1_c.w; 

        if (d0 < zbuffer) 
        {
            //final step , sample on the scene object surface to avoid slice artifact
            //calculate z buffer 3d position in clip space
            float d = zbuffer==0 ? 0.0001 : zbuffer;
            // 已知 p1 p0 为clip 上两点, d 为 p点 depth buffer, 求出 pz pw 为 p 点clip 上3d 坐标
            float a = p1_c.z - p0_c.z ;
            float b = p1_c.w - p0_c.w;
            float pz_c = (b*p0_c.z - a*p0_c.w)/(b-a/d);
            float pw_c = pz_c/d;
            //此处pz_c pw_c 正确
            col = float4(pz_c,pw_c,0,1);
            //求scale = p.z-p0.z /p0.z-p1.z, object space 和 clip space值为一样
            float s = (pz_c - p0_c.z)/(p1_c.z - p0_c.z);
            // 此处是否正好在球面上?
            p1 = p0 + s *z_step;
            v = tex3D(_Volume, p1 + float3(0.5,0.5,0.5)).r ;
            //每step opacity为1, 按照final step大小scale 相对于整步的opacity
            v *= s;
            float4 src = float4(1, 1, 1, v * 0.2f);
            dst = (1.0 - dst.a) * src + dst;
            return saturate(dst);
        }
        float4 src = float4(1, 1, 1, v * 0.2f);
        // blend
        dst = (1.0 - dst.a) * src + dst;
         
        if (i > full_steps) break;
    }
    return saturate(dst);           
    // return col;           
}