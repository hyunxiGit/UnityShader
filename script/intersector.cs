using System.Collections;
using System.Collections.Generic;
using UnityEngine;

class AABB
{
    private GameObject cube;
    public AABB (GameObject _cube)
    {
        this.cube = _cube;
    }
    public Vector3 pos
    {
        get{ return this.cube.transform.position;}
    }

    public Vector3 min
    {
        get
        { 
            return cube.transform.position - cube.transform.lossyScale/2;
        }
    }
    public Vector3 max
    {
        get
        { 
            return cube.transform.position + cube.transform.lossyScale/2;
        }
    }
}

class OBB
{
    private GameObject cube;
    //public Matrix4x4 worldInverse;

    public OBB (GameObject _cube)
    {
        this.cube = _cube;
    }

    public Vector3 pos
    {
        get{ return this.cube.transform.position;}
    }
    public Matrix4x4 o2w
    {
        get{ return this.cube.transform.localToWorldMatrix;}
    }
    public Vector3 x_axis
    {
        get
        { 
            Matrix4x4 o2w =this.cube.transform.localToWorldMatrix;
            return Vector3.Normalize(new Vector3(o2w[0,0] ,o2w[1,0] , o2w[2,0]));
        }
    }

    public Vector3 y_axis
    {
        get
        { 
            Matrix4x4 o2w =this.cube.transform.localToWorldMatrix;       
            return Vector3.Normalize(new Vector3(o2w[0,1] ,o2w[1,1] , o2w[2,1]));
        }
    }
    public Vector3 z_axis
    {
        get
        { 
            Matrix4x4 o2w =this.cube.transform.localToWorldMatrix;
            return Vector3.Normalize(new Vector3(o2w[0,2] ,o2w[1,2] , o2w[2,2]));
        }
    }
    public Vector3 min
    {
        get
        { 
            Matrix4x4 o2w =this.cube.transform.localToWorldMatrix;
            return o2w.MultiplyPoint3x4(new Vector3(-0.5f,-0.5f,-0.5f));
        }
    }
    public Vector3 max
    {
        get
        { 
            Matrix4x4 o2w =this.cube.transform.localToWorldMatrix;
            return o2w.MultiplyPoint3x4(new Vector3(0.5f,0.5f,0.5f));
        }
    }

}

class AB_RAY
{
    public Transform PA;
    public Transform PB;

    public AB_RAY (Transform A , Transform B)
    {
        this.PA = A;
        this.PB = B;
    }
}

public class intersector : MonoBehaviour
{
    // Start is called before the first frame update
    public GameObject test_cube;
    public bool is_aabb;
    Camera cam;
    List <Ray> cam_rays;
    GameObject cube_x1 , cube_x2 , cube_y1 , cube_y2 , cube_z1, cube_z2 , cube_in1 , cube_in2;
    Transform my_transform, pa_transform , pb_transform, aabb_transform;
    AB_RAY ab_ray;
    AABB aabb;
    OBB obb;
    GameObject cube_obb_min , cube_obb_max;
    float cube_size = 0.04f;

    void create_cube(ref GameObject _cube, string _name , Vector3 _pos, float _size, Color _col)
    {
        _cube.transform.position = _pos;
        _cube.transform.localScale = new Vector3(_size,_size,_size);
        _cube.GetComponent<MeshRenderer>().material.color = _col;
        _cube.GetComponent<MeshRenderer>().enabled = false;
        _cube.name = _name;
    }

    void create_test_cubes()
    {
        cube_x1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_x1, "x_1" , new Vector3(0, 0, 0), cube_size, new Color(0.5f,0f,0f));
        cube_x1.GetComponent<MeshRenderer>().enabled = true;

        cube_x2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_x2, "x_2" , new Vector3(0, 0, 0), cube_size, new Color(2000f,0f,0f));
        cube_x2.GetComponent<MeshRenderer>().enabled = true;

        cube_y1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_y1, "y_1" , new Vector3(0, 0, 0), cube_size, new Color(0f,0.5f,0f));
        cube_y1.GetComponent<MeshRenderer>().enabled = true;

        cube_y2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_y2, "y_2" , new Vector3(0, 0, 0), cube_size, new Color(0f,2000f,0f));
        cube_y2.GetComponent<MeshRenderer>().enabled = true;

        cube_z1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_z1, "z_1" , new Vector3(0, 0, 0), cube_size, new Color(0f,0f,0.5f));
        cube_z1.GetComponent<MeshRenderer>().enabled = true;
 
        cube_z2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_z2, "z_2" , new Vector3(0, 0, 0), cube_size, new Color(0f,0f,2000f));
        cube_z2.GetComponent<MeshRenderer>().enabled = true;

        cube_in1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_in1, "in_1" , new Vector3(0, 0, 0), cube_size, new Color(0,0.5f,0.5f));
        cube_in1.GetComponent<MeshRenderer>().enabled = true;

        cube_in2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_in2, "in_2" , new Vector3(0, 0, 0), cube_size, new Color(0,2000f,2000f));
        cube_in2.GetComponent<MeshRenderer>().enabled = true;
    }

    void create_obb_cubes(OBB _obb)
    {
        this.cube_obb_min = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_obb_min, "obb_min" , _obb.min, cube_size, Color.white);
        this.cube_obb_min.GetComponent<MeshRenderer>().enabled = true;

        this.cube_obb_max = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_obb_max, "obb_max" , _obb.max, cube_size, Color.white);
        this.cube_obb_max.GetComponent<MeshRenderer>().enabled = true;
    }

    void display_ref_cube(AB_RAY _ray, Vector3 xyz_sclae_min , Vector3 xyz_sclae_max, bool _display_ref ,  bool _display_int1, bool _display_int2)
    {
        Vector3 ray_full = _ray.PB.position -_ray.PA.position;
        cube_x1.transform.position = _ray.PA.position + xyz_sclae_min.x * ray_full;
        cube_x2.transform.position = _ray.PA.position + xyz_sclae_max.x * ray_full;

        cube_y1.transform.position = _ray.PA.position + xyz_sclae_min.y * ray_full;
        cube_y2.transform.position = _ray.PA.position + xyz_sclae_max.y * ray_full;

        cube_z1.transform.position = _ray.PA.position + xyz_sclae_min.z * ray_full;
        cube_z2.transform.position = _ray.PA.position + xyz_sclae_max.z * ray_full;

        cube_in1.transform.position =_ray.PA.position +   Mathf.Max(Mathf.Max(xyz_sclae_min.x  ,xyz_sclae_min.y),xyz_sclae_min.z) *ray_full;
        cube_in2.transform.position =_ray.PA.position +   Mathf.Min(Mathf.Min(xyz_sclae_max.x  ,xyz_sclae_max.y),xyz_sclae_max.z) *ray_full;

        cube_x1.GetComponent<Renderer>().enabled = _display_ref;
        cube_x2.GetComponent<Renderer>().enabled = _display_ref;
        cube_y1.GetComponent<Renderer>().enabled = _display_ref; 
        cube_y2.GetComponent<Renderer>().enabled = _display_ref; 
        cube_z1.GetComponent<Renderer>().enabled = _display_ref; 
        cube_z2.GetComponent<Renderer>().enabled = _display_ref; 
        cube_in1.GetComponent<Renderer>().enabled = _display_int1;
        cube_in2.GetComponent<Renderer>().enabled = _display_int2;
    }
    
    void aabb_intersection(AB_RAY _ray, AABB _box)
    {
        Vector3 ray_full = _ray.PB.position -_ray.PA.position;
        Vector3 min_inter , max_inter; // intersection point
        bool min_exist, max_exist;

        Vector3 ray_min = _box.min - _ray.PA.position;
        Vector3 ray_max = _box.max - _ray.PA.position;

        float scale_min = ray_min.magnitude / ray_full.magnitude;
        float scale_max = ray_max.magnitude / ray_full.magnitude;

        Vector3 xyz_sclae_min = new Vector3 (scale_min , scale_min, scale_min);
        Vector3 xyz_sclae_max = new Vector3 (scale_max , scale_max, scale_max);

         if (ray_full.x != 0)
         {
            float _x1 = ray_min.x / ray_full.x;
            float _x2 =  ray_max.x / ray_full.x;

            xyz_sclae_min.x = _x1 < _x2 ? _x1 : _x2;
            xyz_sclae_max.x =  _x1 > _x2 ? _x1 : _x2;
         }

         if (ray_full.y != 0)
         {
            float _y1 = ray_min.y / ray_full.y;
            float _y2 =  ray_max.y / ray_full.y;

            xyz_sclae_min.y = _y1 < _y2 ? _y1 : _y2;
            xyz_sclae_max.y =  _y1 > _y2 ? _y1 : _y2;
         }

        if (ray_full.z != 0)
        {
           float _z1 = ray_min.z / ray_full.z;
           float _z2 =  ray_max.z / ray_full.z;
           xyz_sclae_min.z = _z1 < _z2 ? _z1 : _z2;
           xyz_sclae_max.z =  _z1 > _z2 ? _z1 : _z2;
        }

        float min_scale = Mathf.Max(Mathf.Max(xyz_sclae_min.x ,xyz_sclae_min.y),xyz_sclae_min.z);
        float max_scale = Mathf.Min(Mathf.Min(xyz_sclae_max.x ,xyz_sclae_max.y),xyz_sclae_max.z);

        min_inter =_ray.PA.position +   Mathf.Max(Mathf.Max(xyz_sclae_min.x  ,xyz_sclae_min.y),xyz_sclae_min.z) *ray_full;
        max_inter =_ray.PA.position +   Mathf.Min(Mathf.Min(xyz_sclae_max.x  ,xyz_sclae_max.y),xyz_sclae_max.z) *ray_full;

        min_exist=false;
        max_exist=false;

        cube_in1.transform.position = min_inter;
        cube_in2.transform.position = max_inter;

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

        display_ref_cube(_ray, xyz_sclae_min , xyz_sclae_max, false, min_exist, max_exist);
    }

     void obb_intersection(AB_RAY _ray, OBB _box)
    {
        Vector3 ray_full = _ray.PB.position -_ray.PA.position;
        Vector3 min_inter , max_inter; // intersection point
        bool min_exist, max_exist;

        Vector3 ray_min = _box.min - _ray.PA.position;
        Vector3 ray_max = _box.max - _ray.PA.position;

        Vector3 xyz_sclae_min;
        Vector3 xyz_sclae_max;

        //full ray on x , y , z value
        Vector3 ray_projected = new Vector3( Vector3.Dot(_box.x_axis ,ray_full) , Vector3.Dot(_box.y_axis ,ray_full) , Vector3.Dot(_box.z_axis ,ray_full));
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

        display_ref_cube(_ray, xyz_sclae_min , xyz_sclae_max, false, min_exist, max_exist);
    }


    void Start()
    {
        cam = this.gameObject.GetComponent(typeof(Camera)) as Camera;

        cam_rays = new List<Ray>();
        for (int i = 0; i <10 ;i++)
        {
            for (int j = 0; j <10 ;j++)
            {
                Ray myRay = cam.ViewportPointToRay(new Vector3(0.1F*j, 0.1F*i, 0));
                cam_rays.Add(myRay);
            }   
        }

        //test the cube is a obb or aabb
        if (is_aabb)
        {
            aabb = new AABB(test_cube);
        } 
        else
        {
            obb = new OBB(test_cube);
            create_obb_cubes(obb);
        }
        //create ray
        my_transform = GetComponent<Transform>();
        ab_ray = new AB_RAY(cam.transform, my_transform.Find("point_b"));

        //create test cube
        create_test_cubes();
    }

    // Update is called once per frame
    void Update()
    {
        //draw debug ray
    	Debug.DrawLine(ab_ray.PA.position, ab_ray.PB.position, Color.white);
        for (int i = 0; i <10 ;i++)
        {
            for (int j = 0; j <10 ;j++)
            {
                Ray _ray = cam_rays[i *10 + j];
                Debug.DrawLine (_ray.origin , _ray.origin + _ray.direction *10 , Color.grey );
            }   
        }
        
        // draw aabb
        if (is_aabb)
        {
            aabb_intersection(ab_ray , aabb);
        }
        else
        {
            obb_intersection(ab_ray , obb);
            // Debug.DrawLine(obb.pos, obb.pos + obb.x_axis , Color.red);
            // Debug.DrawLine(obb.pos, obb.pos + obb.y_axis , Color.green);
            // Debug.DrawLine(obb.pos, obb.pos + obb.z_axis , Color.blue);
        }
    }
}
