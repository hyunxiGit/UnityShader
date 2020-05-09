using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class cpu_ray_march_volumn : MonoBehaviour
{
    // Start is called before the first frame update
    public GameObject test_cube;
    public bool is_aabb;
    public int max_steps = 500;

    //intersector 
    public intersector inter;
    public Texture3D volume;
    //debug cubes
    DCube_pool pool;
    DCube_Ray dcubes;
    List <DCube_Ray> dCube_rays;
    
    //DCube c_int1;
    Camera cam;
    List <AB_RAY> cam_rays;
    int w_rays ;
    int h_rays ;

    public AB_RAY ab_ray;
    public AABB aabb;
    public OBB obb;

    float step_size;
    float max_distance;

    //turn off update dcube each frame
    bool use_cam_handler = false;
    bool dcube_created = false;      

    void Start()
    {

        inter = new intersector();
        //test cube pool
        pool = new DCube_pool();
        dCube_rays = new List <DCube_Ray>();
        //camera rays
        cam = this.gameObject.GetComponent(typeof(Camera)) as Camera;

        w_rays = 10;
        h_rays = (int)((float)w_rays * cam.pixelHeight / cam.pixelWidth );

        cam_rays = new List<AB_RAY>();
        for (int i = 0; i <h_rays ;i++)
        {
            //need to create the last ray at right edge
            for (int j = 0; j <w_rays ;j++)
            {
                //create ray at correct gap
                Ray myRay = cam.ViewportPointToRay(new Vector3(1.0f/(w_rays-1)*j, 1.0f/(h_rays-1)*i, 0));
                GameObject A_object = new GameObject();
                A_object . transform.position = myRay.origin;
                Vector3 B = (myRay.origin - cam.transform.position)* cam.farClipPlane / cam.nearClipPlane + cam.transform.position;
                GameObject B_object = new GameObject();
                B_object.transform.position = B;
                // DCube fc = pool.getDCube();
                // fc.position = B;
                // fc.setParent(cam.transform);

                // DCube nc = pool.getDCube();
                // nc.position = myRay.origin;
                // nc.setParent(cam.transform);

                AB_RAY cam_ab_ray = new AB_RAY(A_object.transform, B_object.transform);
                cam_rays.Add(cam_ab_ray);

            }   
        }

        //test the cube is a obb or aabb
        if (is_aabb)
        {
            aabb = new AABB(test_cube);
            //debug cubes for a ray
            dcubes = new DCube_Ray(pool);
        } 
        else
        {
            obb = new OBB(test_cube);
            //debug cubes for a ray
            dcubes = new DCube_Ray(pool);

        }

        //create ray
        ab_ray = new AB_RAY(cam.transform, GetComponent<Transform>().Find("cam_ray_handeler"));
        //ray march parameters
        max_distance = cam.farClipPlane - cam.nearClipPlane;
        step_size = max_distance/max_steps;

    }

    Color sample3dTexture(Vector3 p)
    {
        p += new Vector3(0.5f, 0.5f, 0.5f);
        int max_sample = 10;
        // print("volume.depth" + volume.depth);
        // print("volume.height" + volume.height);
        // print("volume.width" + volume.width);
        Color c = volume.GetPixel( (int)(p.x * volume.width),(int)(p.y * volume.height), (int)(p.z*volume.depth));
        return c;
        // for (int i = 0 ; i < volume.depth ; i=i+10)
        // {
        //     for (int j = 0 ; j < volume.height ; j=j+10)
        //     {
        //         for (int k = 0 ; k < volume.width ;k=k+10)
        //         {
        //             Color c = volume.GetPixel( k,j,i);
        //             print ("volumen :" + k+","+j+","+i+":"+ c);
        //         }   
        //     }   
        // }
        
    }

    void rayMarch(inter_point inter_p , float _step_size , float max_distance , int _max_steps , OBB _obb)
    {
        int full_step_w = (int)((inter_p.p1_world - inter_p.p0_world).magnitude / max_distance * _max_steps);
        // print("_obb.w2o : "+_obb.w2o);
        
        // print ("full_step_w :" +full_step_w );
        //ray marching in obj
        for (int i = 0 ; i <full_step_w ; i++ )
        {
            //object space ab
            Vector3 full_ray = inter_p.p1_world -inter_p.p0_world;
            Debug.DrawLine(inter_p.p0_world, inter_p.p1_world , Color.red);
            // print("full_step_w :" + full_step_w);
            Vector3 stop_p = inter_p.p0_world  + full_ray / full_step_w *i;

        }
    }

    void rayMarch2(inter_point inter_p , float _step_size , float max_distance , int _max_steps , OBB _obb, Vector3 cam_pos)
    {
        //z-plane alignment
        bool use_object = true; 
        Vector3 p0 = inter_p.p0_world;
        Vector3 p1 = inter_p.p1_world;
        Vector3 cam = cam_pos;
        Vector3 z_step = new Vector3 (0,0, max_distance / _max_steps);

        if (use_object)
        {
            p0 = inter_p.p0_object;
            p1 = inter_p.p1_object;
            cam = _obb.w2o.MultiplyPoint3x4(cam);
            z_step = _obb.w2o.MultiplyVector(z_step);
        }

        //the plane alignment should be calculated on cam pos as origin
        Vector3 p0_c = p0 -cam;
        Vector3 z_dir = z_step.normalized;
        //step on p0-p1 align z
        Vector3 p_step = p0_c * Vector3.Dot(z_step , z_dir) / Vector3.Dot(p0_c,z_dir);
        Vector3 p0_z_pro = Vector3.Dot(p0_c, z_dir)*z_dir;
        float scale_p0 = Vector3.Dot(p0_z_pro , z_dir);
        float scale_z_step = Vector3.Dot(z_step , z_dir);
        int scale_p0_z_step = (int)(scale_p0 / scale_z_step);
        Vector3 z_plane = scale_p0_z_step * z_step;
        Vector3 p0_new = (int)(scale_p0_z_step) * scale_z_step /scale_p0 * p0_c + cam;   

        int full_step = (int)((p1 -p0).magnitude / p_step.magnitude);

        for (int i = 0 ; i <full_step+1 ; i++)
        {
            Vector3 pos = p0_new + i *p_step;
            Color c = sample3dTexture (pos);

            //debug cubes
            if (dcube_created == false)
            {
                print("pos :" + pos );
                print("color :" + c);
                DCube pd_t = pool.getDCube();        
                pd_t.position = use_object ? _obb.o2w.MultiplyPoint3x4( pos) : pos ;  
                pd_t.color = c ;
            }
            
        }
    }

    void cam_rays_marching()
    {
        for (int i = 0; i <h_rays ;i++)
        {
            for (int j = 0; j <w_rays ;j++)
            {
                AB_RAY _ray = cam_rays[i *w_rays + j];
                Debug.DrawLine(_ray.PA.position, _ray.PB.position, Color.gray);
                if (is_aabb)
                {
                    // inter_point inter_p = inter.aabb_intersection(ab_ray , aabb , dcubes);
                    // print("inter_p.p0_w " + inter_p.p0_world );
                }
                else
                {
                     // obb_intersection(ab_ray , obb);
                    inter_point inter_p = inter.obb_intersection_cube(_ray ,obb, dcubes);
                    if (inter_p.p0_exist && inter_p.p1_exist) 
                    {
                        rayMarch2(inter_p, step_size,max_distance,max_steps , obb, cam.transform.position);
                    }
                }
            }   
        }
    }

    void cam_handler_marching()
    {
        Debug.DrawLine(ab_ray.PA.position, ab_ray.PB.position, Color.white);
        // draw aabb
        if (is_aabb)
        {
            inter_point inter_p = inter.aabb_intersection(ab_ray , aabb , dcubes);
            print("inter_p.p0_w " + inter_p.p0_world );
        }
        else
        {
             // obb_intersection(ab_ray , obb);

            inter_point inter_p = inter.obb_intersection_cube(ab_ray ,obb, dcubes);
            if (inter_p.p0_exist && inter_p.p1_exist) 
            {
                rayMarch2(inter_p, step_size,max_distance,max_steps , obb, cam.transform.position);
            }
        }
    }

    // Update is called once per frame
    void Update()
    {   	
        // cam_rays_marching();
        if (use_cam_handler) { cam_handler_marching(); }
        else { cam_rays_marching(); }
        //only update dcube onece
        dcube_created = true;
    }
}
