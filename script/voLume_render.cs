using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class voLume_render : MonoBehaviour
{
    // Start is called before the first frame update
    public GameObject test_cube;
    public bool is_aabb;
    public int max_steps = 100;

    //intersector 
    public intersector inter;
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

                Vector3 B = (myRay.origin - cam.transform.position)* cam.farClipPlane / cam.nearClipPlane + cam.transform.position;

                DCube fc = pool.getDCube();
                fc.position = B;
                fc.setParent(cam.transform);

                DCube nc = pool.getDCube();
                nc.position = myRay.origin;
                nc.setParent(cam.transform);

                AB_RAY cam_ab_ray = new AB_RAY(nc.transform, fc.transform);
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
            inter.aabb_intersection(ab_ray , aabb , dcubes);
        }
        else
        {
             // obb_intersection(ab_ray , obb);

            inter.obb_intersection_cube(ab_ray ,obb, dcubes);
            // Debug.DrawLine(obb.pos, obb.pos + obb.x_axis , Color.red);
            // Debug.DrawLine(obb.pos, obb.pos + obb.y_axis , Color.green);
            // Debug.DrawLine(obb.pos, obb.pos + obb.z_axis , Color.blue);
        }
    }
}
