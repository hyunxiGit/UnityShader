using System.Collections;
using System.Collections.Generic;
using UnityEngine;

class AABB_BOX
{
    public Vector3 min;
    public Vector3 max;

    public AABB_BOX (GameObject go)
    {

        float cube_size = 0.04f;
        this.min = go.transform.position - go.transform.lossyScale/2;
        this.max = go.transform.position + go.transform.lossyScale/2;


        GameObject p_min = GameObject.CreatePrimitive(PrimitiveType.Cube);
        p_min.transform.position = min;
        p_min.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        p_min.GetComponent<MeshRenderer>().material.color =new Color(0,0,0);
        p_min.name = "p_min";

        GameObject p_max = GameObject.CreatePrimitive(PrimitiveType.Cube);
        p_max.transform.position = max;
        p_max.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        p_max.GetComponent<MeshRenderer>().material.color =new Color(0,0,0);
        p_max.name = "p_max";
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

public class aabb_intersector : MonoBehaviour
{
    // Start is called before the first frame update
    public GameObject aabb;
    GameObject cube_x1 , cube_x2 , cube_y1 , cube_y2 , cube_z1, cube_z2 , cube_in1 , cube_in2;
    Transform my_transform, pa_transform , pb_transform, aabb_transform;
    AB_RAY ab_ray;
    AABB_BOX aabb_box;
    float cube_size = 0.04f;

    void create_cube(ref GameObject _cube, string _name , Vector3 _pos, float _size, Color _col)
    {
        _cube.transform.position = _pos;
        _cube.transform.localScale = new Vector3(_size,_size,_size);
        _cube.GetComponent<MeshRenderer>().material.color = _col;
        _cube.name = _name;
    }

    void create_cubes()
    {
        cube_x1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_x1, "x_1" , new Vector3(0, 0.5f, 0), cube_size, new Color(0.5f,0f,0f));

        cube_x2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_x2, "x_2" , new Vector3(0, 0.5f, 0), cube_size, new Color(2000f,0f,0f));

        cube_y1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_y1, "y_1" , new Vector3(0, 0.5f, 0), cube_size, new Color(0f,0.5f,0f));

        cube_y2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_y2, "y_2" , new Vector3(0, 0.5f, 0), cube_size, new Color(0f,2000f,0f));

        cube_z1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_z1, "z_1" , new Vector3(0, 0.5f, 0), cube_size, new Color(0f,0f,0.5f));
 
        cube_z2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_z2, "z_2" , new Vector3(0, 0.5f, 0), cube_size, new Color(0f,0f,2000f));

        cube_in1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_in1, "in_1" , new Vector3(0, 0.5f, 0), cube_size, new Color(0,0.5f,0.5f));

        cube_in2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        create_cube(ref cube_in2, "in_2" , new Vector3(0, 0.5f, 0), cube_size, new Color(0,2000f,2000f));
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
    
    void intersection(AB_RAY _ray, AABB_BOX _box)
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

    void Awak()
    {

    }
    void Start()
    {
        aabb_box = new AABB_BOX(aabb);

        my_transform = GetComponent<Transform>();
        ab_ray = new AB_RAY(my_transform.Find("point_a"), my_transform.Find("point_b"));

        create_cubes();
    }

    // Update is called once per frame
    void Update()
    {
        //update line
    	Debug.DrawLine(ab_ray.PA.position, ab_ray.PB.position, Color.white);
        intersection(ab_ray , aabb_box);
    }
}
