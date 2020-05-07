using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class voLume_render : MonoBehaviour
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

    //temp
    DCube pd , pd1 ,pd2,pd3;       

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
        ab_ray = new AB_RAY(cam.transform, GetComponent<Transform>().Find("point_b"));
        //ray march parameters
        max_distance = cam.farClipPlane - cam.nearClipPlane;
        step_size = max_distance/max_steps;

        // cretae3dTexture();
    }

    void cretae3dTexture()
    {
        int max_sample = 10;
        print("volume.depth" + volume.depth);
        print("volume.height" + volume.height);
        print("volume.width" + volume.width);
        for (int i = 0 ; i < volume.depth ; i=i+10)
        {
            for (int j = 0 ; j < volume.height ; j=j+10)
            {
                for (int k = 0 ; k < volume.width ;k=k+10)
                {
                    Color c = volume.GetPixel( k,j,i);
                    print ("volumen :" + k+","+j+","+i+":"+ c);
                }   
            }   
        }
        
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
            // pd = pool.getDCube();
            // print("pd : " + pd);
            // pd.position = stop_p;
            // print("pd.position : " + pd.position);
        }
    }

    void rayMarch2(inter_point inter_p , float _step_size , float max_distance , int _max_steps , OBB _obb, Vector3 cam_pos)
    {
        //the plane alignment should be calculated on cam pos as origin
        Vector3 p0_c = inter_p.p0_world -cam_pos;
        //step size
        float step_size = max_distance / _max_steps;
        //z_step on z plane 
        Vector3 z_step = new Vector3 (0,0, step_size);
        Vector3 z_dir = z_step.normalized;
        //step on p0p1 align z
        Vector3 p_step = p0_c * Vector3.Dot(z_step , z_dir) / Vector3.Dot(p0_c,z_dir);
        
        Vector3 p0_z_pro = Vector3.Dot(p0_c, z_dir)*z_dir;
        float scale_p0 = Vector3.Dot(p0_z_pro , z_dir);
        float scale_z_step = Vector3.Dot(z_step , z_dir);
        int scale_p0_z_step = (int)(scale_p0 / scale_z_step);
        Vector3 z_plane = scale_p0_z_step * z_step;
        float scale3 = Vector3.Dot(z_plane , z_dir);
        Vector3 p0_new = (int)(scale_p0_z_step) * scale_z_step /scale_p0 * p0_c + cam_pos;        
        
        // pd = pool.getDCube();        
        // pd.position = p0_new;
        // pd1 = pool.getDCube();
        // pd1.position = p0_new + p_step;
        // pd2 = pool.getDCube();
        // pd2.position = p0_new + 2*p_step;
        // pd3 = pool.getDCube();
        // pd3.position = p0_new + 3*p_step;

        //------------------------------------------------------------------------------------------

        Vector3 z_step_o = _obb.w2o.MultiplyPoint3x4(new Vector3 (0,0,(float)max_distance / _max_steps));
        float p0_scale_o = Vector3.Dot(inter_p.p0_object , z_step_o.normalized)/z_step.magnitude;
        float p1_scale_o = Vector3.Dot(inter_p.p1_object , z_step_o.normalized)/z_step.magnitude;
        // print("scale p0 object : " + p0_scale  + " ,scale p1 object:" + p1_scale);
        
    }


    // Update is called once per frame
    void Update()
    {
        //draw debug ray
    	Debug.DrawLine(ab_ray.PA.position, ab_ray.PB.position, Color.white);

        for (int i = 0; i <h_rays ;i++)
        {
            for (int j = 0; j <w_rays ;j++)
            {
                // AB_RAY _ray = cam_rays[i *w_rays + j];
                // Debug.DrawLine(_ray.PA.position, _ray.PB.position, Color.gray);
                // inter.obb_intersection_cube(ab_ray ,obb , dcubes);
            }   
        }
        
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
            // Debug.DrawLine(obb.pos, obb.pos + obb.x_axis , Color.red);
            // Debug.DrawLine(obb.pos, obb.pos + obb.y_axis , Color.green);
            // Debug.DrawLine(obb.pos, obb.pos + obb.z_axis , Color.blue);
        }
    }
}
