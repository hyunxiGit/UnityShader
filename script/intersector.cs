using System.Collections;
using System.Collections.Generic;
using UnityEngine;

class DCube_Ray
{
    private DCube_pool _pool;
    public DCube p0 , p1 , x0, x1 ,y0 ,y1 ,z0,z1;
    public DCube_Ray (DCube_pool p)
    {
        this._pool = p;
        this.p0 = this._pool.getDCube();
        this.p1 = this._pool.getDCube();
        this.x0 = this._pool.getDCube();
        this.x1 = this._pool.getDCube();
        this.y0 = this._pool.getDCube();
        this.y1 = this._pool.getDCube();
        this.z0 = this._pool.getDCube();
        this.z1 = this._pool.getDCube();
        this.p0.color = new Color(0f, 2000f,2000f);
        this.p1.color = new Color(0f, 1f,1f);
        this.x0.color = new Color(2000f, 0f,0f);
        this.x1.color = new Color(1f, 0f,0f);
        this.y0.color = new Color(0f, 2000f,0f);
        this.y1.color = new Color(0f, 1f,0f);
        this.z0.color = new Color(0f, 0f,2000f);
        this.z1.color = new Color(0f, 0f,1f);
    }   
    public void use()
    {
        this.p0.use();
        this.p1.use();
        this.x0.use();
        this.x1.use();
        this.y0.use();
        this.y1.use();
        this.z0.use();
        this.z1.use();
    }
    public void release ()
    {
        this.p0.release();
        this.p1.release();
        this.x0.release();
        this.x1.release();
        this.y0.release();
        this.y1.release();
        this.z0.release();
        this.z1.release();
    }
}

public class intersector : MonoBehaviour
{
    // Start is called before the first frame update
    public GameObject test_cube;

    public bool is_aabb;
    public int max_steps = 100;

    //debug cubes
    DCube_pool pool;
    DCube_Ray dcubes;
    List <DCube_Ray> dCube_rays;
    
    //DCube c_int1;
    Camera cam;
    List <AB_RAY> cam_rays;
    int w_rays ;
    int h_rays ;

    AB_RAY ab_ray;
    AABB aabb;
    OBB obb;

    void aabb_intersection(AB_RAY _ray, AABB _box)
    {
        bool min_exist, max_exist;

        Vector3 ray_min = _box.min - _ray.PA.position;
        Vector3 ray_max = _box.max - _ray.PA.position;

        Vector3 xyz_sclae_min ;
        Vector3 xyz_sclae_max ;

        Vector3 fullRay = new Vector3( _ray.fullRay.x == 0? 0.0001f : _ray.fullRay.x ,
                                        _ray.fullRay.x == 0? 0.0001f : _ray.fullRay.y,
                                        _ray.fullRay.x == 0? 0.0001f : _ray.fullRay.z);

        float _x1 = ray_min.x / _ray.fullRay.x;
        float _x2 =  ray_max.x / _ray.fullRay.x;

        xyz_sclae_min.x = _x1 < _x2 ? _x1 : _x2;
        xyz_sclae_max.x =  _x1 > _x2 ? _x1 : _x2;
        
        float _y1 = ray_min.y / _ray.fullRay.y;
        float _y2 =  ray_max.y / _ray.fullRay.y;

        xyz_sclae_min.y = _y1 < _y2 ? _y1 : _y2;
        xyz_sclae_max.y =  _y1 > _y2 ? _y1 : _y2;
        
       float _z1 = ray_min.z / _ray.fullRay.z;
       float _z2 =  ray_max.z / _ray.fullRay.z;
       xyz_sclae_min.z = _z1 < _z2 ? _z1 : _z2;
       xyz_sclae_max.z =  _z1 > _z2 ? _z1 : _z2;
        

        float min_scale = Mathf.Max(Mathf.Max(xyz_sclae_min.x ,xyz_sclae_min.y),xyz_sclae_min.z);
        float max_scale = Mathf.Min(Mathf.Min(xyz_sclae_max.x ,xyz_sclae_max.y),xyz_sclae_max.z);

        min_exist=false;
        max_exist=false;

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

        dcubes.p0.position = _ray.PA.position + min_scale * _ray.fullRay;
        dcubes.p1.position = _ray.PA.position + max_scale * _ray.fullRay;
        dcubes.x0.position = _ray.PA.position + xyz_sclae_min.x * _ray.fullRay;
        dcubes.x1.position = _ray.PA.position + xyz_sclae_max.x * _ray.fullRay;
        dcubes.y0.position = _ray.PA.position + xyz_sclae_min.y * _ray.fullRay;
        dcubes.y1.position = _ray.PA.position + xyz_sclae_max.y * _ray.fullRay;
        dcubes.z0.position = _ray.PA.position + xyz_sclae_min.z * _ray.fullRay;
        dcubes.z1.position = _ray.PA.position + xyz_sclae_max.z * _ray.fullRay;
        if (!min_exist)  { dcubes.p0.release(); } else{ dcubes.p0.use();  }
        if (!max_exist)  { dcubes.p1.release(); } else{ dcubes.p1.use();  }

    }

    void obb_intersection(AB_RAY _ray, OBB _box)
    {
        Vector3 min_inter , max_inter; // intersection point
        bool min_exist, max_exist;

        Vector3 ray_min = _box.min - _ray.PA.position;
        Vector3 ray_max = _box.max - _ray.PA.position;

        Vector3 xyz_sclae_min;
        Vector3 xyz_sclae_max;

        //full ray on x , y , z value
        Vector3 ray_projected = new Vector3( Vector3.Dot(_box.x_axis ,_ray.fullRay) , Vector3.Dot(_box.y_axis ,_ray.fullRay) , Vector3.Dot(_box.z_axis ,_ray.fullRay));
        ray_projected.x = ray_projected.x == 0?0.0000001f : ray_projected.x;
        ray_projected.y = ray_projected.y == 0?0.0000001f : ray_projected.y;
        ray_projected.z = ray_projected.z == 0?0.0000001f : ray_projected.z;

        float _x1 = Vector3.Dot(_box.x_axis , ray_min ) / ray_projected.x;
        float _x2 = Vector3.Dot(_box.x_axis , ray_max ) / ray_projected.x;

        xyz_sclae_min.x = _x1 < _x2 ? _x1 : _x2;
        xyz_sclae_max.x = _x1 > _x2 ? _x1 : _x2;

        float _y1 = Vector3.Dot(_box.y_axis , ray_min ) / ray_projected.y;
        float _y2 = Vector3.Dot(_box.y_axis , ray_max ) / ray_projected.y;

        xyz_sclae_min.y = _y1 < _y2 ? _y1 : _y2;
        xyz_sclae_max.y = _y1 > _y2 ? _y1 : _y2;

        float _z1 = Vector3.Dot(_box.z_axis , ray_min ) / ray_projected.z;
        float _z2 = Vector3.Dot(_box.z_axis , ray_max ) / ray_projected.z;

        xyz_sclae_min.z = _z1 < _z2 ? _z1 : _z2;
        xyz_sclae_max.z = _z1 > _z2 ? _z1 : _z2;

        float min_scale = Mathf.Max(Mathf.Max(xyz_sclae_min.x ,xyz_sclae_min.y),xyz_sclae_min.z);
        float max_scale = Mathf.Min(Mathf.Min(xyz_sclae_max.x ,xyz_sclae_max.y),xyz_sclae_max.z);

        min_exist=false;
        max_exist=false;

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

        //debug info display
        dcubes.p0.position = _ray.PA.position + min_scale * _ray.fullRay;
        dcubes.p1.position = _ray.PA.position + max_scale * _ray.fullRay;
        dcubes.x0.position = _ray.PA.position + xyz_sclae_min.x * _ray.fullRay;
        dcubes.x1.position = _ray.PA.position + xyz_sclae_max.x * _ray.fullRay;
        dcubes.y0.position = _ray.PA.position + xyz_sclae_min.y * _ray.fullRay;
        dcubes.y1.position = _ray.PA.position + xyz_sclae_max.y * _ray.fullRay;
        dcubes.z0.position = _ray.PA.position + xyz_sclae_min.z * _ray.fullRay;
        dcubes.z1.position = _ray.PA.position + xyz_sclae_max.z * _ray.fullRay;
        if (!min_exist)  { dcubes.p0.release(); } else{ dcubes.p0.use();  }
        if (!max_exist)  { dcubes.p1.release(); } else{ dcubes.p1.use();  }
    }

    void obb_intersection_cube(AB_RAY _ray, OBB _box)
    {
        Vector3 _PA_pos_cube = _box.w2o.MultiplyPoint3x4(_ray.PA.position);
        Vector3 _PB_pos_cube = _box.w2o.MultiplyPoint3x4(_ray.PB.position);

        //object space
        Vector3 ray_full = _PB_pos_cube -_PA_pos_cube;
        Vector3 min_inter , max_inter; // intersection point
        bool min_exist, max_exist;

        Vector3 ray_min = _box.min_o - _PA_pos_cube;
        Vector3 ray_max = _box.max_o - _PA_pos_cube;

        Vector3 xyz_sclae_min;
        Vector3 xyz_sclae_max;

        //full ray on x , y , z value
        Vector3 ray_projected = new Vector3( ray_full.x , ray_full.y , ray_full.z);
        ray_projected.x = ray_projected.x == 0?0.0000001f : ray_projected.x;
        ray_projected.y = ray_projected.y == 0?0.0000001f : ray_projected.y;
        ray_projected.z = ray_projected.z == 0?0.0000001f : ray_projected.z;

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

        float min_scale = Mathf.Max(Mathf.Max(xyz_sclae_min.x ,xyz_sclae_min.y),xyz_sclae_min.z);
        float max_scale = Mathf.Min(Mathf.Min(xyz_sclae_max.x ,xyz_sclae_max.y),xyz_sclae_max.z);

        //two intersect point in object space
        Vector3 p0 =_PA_pos_cube +   Mathf.Max(Mathf.Max(xyz_sclae_min.x  ,xyz_sclae_min.y),xyz_sclae_min.z) *ray_full;
        Vector3 p1 =_PA_pos_cube +   Mathf.Min(Mathf.Min(xyz_sclae_max.x  ,xyz_sclae_max.y),xyz_sclae_max.z) *ray_full;
        //two intersect point in object space
        p0 = _box.o2w.MultiplyPoint3x4(p0);
        p1 = _box.o2w.MultiplyPoint3x4(p1);

        min_exist=false;
        max_exist=false;

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

        //debug info display
        dcubes.p0.position = p0;
        dcubes.p1.position = p1;
        dcubes.x0.position = _ray.PA.position + xyz_sclae_min.x * _ray.fullRay;
        dcubes.x1.position = _ray.PA.position + xyz_sclae_max.x * _ray.fullRay;
        dcubes.y0.position = _ray.PA.position + xyz_sclae_min.y * _ray.fullRay;
        dcubes.y1.position = _ray.PA.position + xyz_sclae_max.y * _ray.fullRay;
        dcubes.z0.position = _ray.PA.position + xyz_sclae_min.z * _ray.fullRay;
        dcubes.z1.position = _ray.PA.position + xyz_sclae_max.z * _ray.fullRay;
        if (!min_exist)  { dcubes.p0.release(); } else{ dcubes.p0.use();  }
        if (!max_exist)  { dcubes.p1.release(); } else{ dcubes.p1.use();  }
    }



    void Start()
    {
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
            dcubes = new DCube_Ray(pool);
        } 
        else
        {
            obb = new OBB(test_cube);
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
                // obb_intersection_cube(_ray , obb);
            }   
        }
        
        // draw aabb
        if (is_aabb)
        {
            aabb_intersection(ab_ray , aabb);
        }
        else
        {
             // obb_intersection(ab_ray , obb);

            obb_intersection_cube(ab_ray , obb);
            // Debug.DrawLine(obb.pos, obb.pos + obb.x_axis , Color.red);
            // Debug.DrawLine(obb.pos, obb.pos + obb.y_axis , Color.green);
            // Debug.DrawLine(obb.pos, obb.pos + obb.z_axis , Color.blue);
        }
    }
}
