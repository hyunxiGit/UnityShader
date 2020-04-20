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
        //cube_x1.GetComponent<Renderer>().enabled = false;

        GameObject p_max = GameObject.CreatePrimitive(PrimitiveType.Cube);
        p_max.transform.position = max;
        p_max.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        p_max.GetComponent<MeshRenderer>().material.color =new Color(0,0,0);
        p_max.name = "p_max";
        //cube_x2.GetComponent<Renderer>().enabled = false;
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

    Color Red_Color(float r)
    {
        return new Color(r,0,0);
    }
    Color Green_Color(float g)
    {
        return new Color(0,g,0);
    }
    Color Blue_Color(float b)
    {
        return new Color(0,0,b);
    }

    void create_cubes()
    {
        cube_x1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube_x1.transform.position = new Vector3(0, 0.5f, 0);
        cube_x1.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        cube_x1.GetComponent<MeshRenderer>().material.color =Red_Color(0.5f);
        cube_x1.name = "x_1";
        cube_x1.GetComponent<Renderer>().enabled = false;

        cube_x2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube_x2.transform.position = new Vector3(0, 0.5f, 0);
        cube_x2.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        cube_x2.GetComponent<MeshRenderer>().material.color =Red_Color(2000f);
        cube_x2.name = "x_2";
        cube_x2.GetComponent<Renderer>().enabled = false;

        cube_y1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube_y1.transform.position = new Vector3(0, 0.5f, 0);
        cube_y1.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        cube_y1.GetComponent<MeshRenderer>().material.color =Green_Color(0.5f);
        cube_y1.name = "y_1";
        cube_y1.GetComponent<Renderer>().enabled = false;

        cube_y2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube_y2.transform.position = new Vector3(0, 0.5f, 0);
        cube_y2.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        cube_y2.GetComponent<MeshRenderer>().material.color =Green_Color(2000f);
        cube_y2.name = "y_2";
        cube_y2.GetComponent<Renderer>().enabled = false;

        cube_z1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube_z1.transform.position = new Vector3(0, 0.5f, 0);
        cube_z1.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        cube_z1.GetComponent<MeshRenderer>().material.color =Blue_Color(0.5f);
        cube_z1.name = "z_1";
        cube_z1.GetComponent<Renderer>().enabled = false;

        cube_z2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube_z2.transform.position = new Vector3(0, 0.5f, 0);
        cube_z2.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        cube_z2.GetComponent<MeshRenderer>().material.color =Blue_Color(2000f);
        cube_z2.name = "z_2";
        cube_z2.GetComponent<Renderer>().enabled = false;

        cube_in1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube_in1.transform.position = new Vector3(0, 0.5f, 0);
        cube_in1.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        cube_in1.GetComponent<MeshRenderer>().material.color =new Color(0,0.5f,0.5f);
        cube_in1.name = "in_1";
        // cube_in1.GetComponent<Renderer>().enabled = false;

        cube_in2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube_in2.transform.position = new Vector3(0, 0.5f, 0);
        cube_in2.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        cube_in2.GetComponent<MeshRenderer>().material.color =new Color(0,2000f,2000f);
        cube_in2.name = "in_2";
        // cube_in1.GetComponent<Renderer>().enabled = false;
    }
    
    void intersection(AB_RAY _ray, AABB_BOX _box)
    {
        Vector3 ray_full = _ray.PB.position -_ray.PA.position;

        Vector3 ray_min = _box.min - _ray.PA.position;
        Vector3 ray_max = _box.max - _ray.PA.position;

        Vector3 x_min , x_max , y_min , y_max , z_min , z_max;


        float scale_min = ray_min.magnitude / ray_full.magnitude;
        float scale_max = ray_max.magnitude / ray_full.magnitude;

        float x_scale_min, x_scale_max;
        if (ray_full.x == 0)
        {   
            x_scale_min = scale_min;
            x_scale_max = scale_max;
        }
        else
        {
            x_scale_min = ray_min.x / ray_full.x;
            x_scale_max =  ray_max.x / ray_full.x;
        }

        if (x_scale_min > x_scale_max)
        {
            float t = x_scale_min;
            x_scale_min = x_scale_max ;
            x_scale_max = t;
        }

        x_min = _ray.PA.position + x_scale_min * ray_full;
        x_max = _ray.PA.position + x_scale_max * ray_full;

        float y_scale_min, y_scale_max;
        if (ray_full.y == 0)
        {   
            y_scale_min = scale_min;
            y_scale_max = scale_max;
        }

        else
        {
            y_scale_min = ray_min.y / ray_full.y;
            y_scale_max = ray_max.y / ray_full.y;
        }

        if (y_scale_min > y_scale_max)
        {
            float t = y_scale_min;
            y_scale_min = y_scale_max ;
            y_scale_max = t;
        }


        y_min = _ray.PA.position + y_scale_min * ray_full;
        y_max = _ray.PA.position + y_scale_max * ray_full;

        float z_scale_min, z_scale_max;
        if (ray_full.z == 0)
        {   
            z_scale_min = scale_min;
            z_scale_max = scale_max;
        }
        else
        {
            z_scale_min = ray_min.z / ray_full.z;
            z_scale_max = ray_max.z / ray_full.z;
        }

        if (z_scale_min > z_scale_max)
        {
            float t = z_scale_min ;
            z_scale_min = z_scale_max ; 
            z_scale_max = t; 
        }

        z_min = _ray.PA.position + z_scale_min * ray_full;
        z_max = _ray.PA.position + z_scale_max * ray_full;

        float min_scale = Mathf.Max(Mathf.Max(x_scale_min ,y_scale_min),z_scale_min);
        float max_scale = Mathf.Min(Mathf.Min(x_scale_max ,y_scale_max),z_scale_max);

        Vector3 min_inter =_ray.PA.position +   Mathf.Max(Mathf.Max(x_scale_min ,y_scale_min),z_scale_min) *ray_full;
        Vector3 max_inter =_ray.PA.position +   Mathf.Min(Mathf.Min(x_scale_max ,y_scale_max),z_scale_max) *ray_full;


        //print(x_min);
        cube_x1.transform.position = x_min;
        cube_x2.transform.position = x_max;
        cube_y1.transform.position = y_min;
        cube_y2.transform.position = y_max;
        cube_z1.transform.position = z_min;
        cube_z2.transform.position = z_max;


        cube_in1.transform.position = min_inter;
        cube_in2.transform.position = max_inter;

        if (min_scale < 0 || min_scale >1 || min_scale > max_scale)
        {
            print ("inside by min");
            print ("z_scale_min :" + min_inter);
            cube_in1.GetComponent<Renderer>().enabled = false;
            //only one point out
        }
        else
        {
            cube_in1.GetComponent<Renderer>().enabled = true;
        }

        if (max_scale > 1 || max_scale <0)
        {
            print ("inside by max");
            print ("max_scale :" + max_scale);
            cube_in2.GetComponent<Renderer>().enabled = false;
            //only one point in
        }
        else
        {
            cube_in2.GetComponent<Renderer>().enabled = true;
        }

    }

    void Awak()
    {

    }
    void Start()
    {
        aabb_box = new AABB_BOX(aabb);

        my_transform = GetComponent<Transform>();
        //GameObject my_gameObjecto ;
        ab_ray = new AB_RAY(my_transform.Find("point_a"), my_transform.Find("point_b"));
        // pa_transform = my_transform.Find("point_a");
        // pb_transform = my_transform.Find("point_b");
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
