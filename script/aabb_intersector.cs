using System.Collections;
using System.Collections.Generic;
using UnityEngine;

class AABB_BOX
{
    public Vector3 min;
    public Vector3 max;

    public AABB_BOX (GameObject go)
    {
        this.min = go.transform.position - go.transform.lossyScale/2;
        this.max = go.transform.position + go.transform.lossyScale/2;
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
    GameObject cube_x1 , cube_x2 , cube_y1 , cube_y2 , cube_z1, cube_z2;
    Transform my_transform, pa_transform , pb_transform, aabb_transform;
    AB_RAY ab_ray;
    AABB_BOX aabb_box;
    float cube_size = 0.04f;

    Color Red_Color()
    {
        return new Color(1,0,0);
    }
    Color Green_Color()
    {
        return new Color(0,1,0);
    }
    Color Blue_Color()
    {
        return new Color(0,0,1);
    }

    void create_cubes()
    {
        cube_x1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube_x1.transform.position = new Vector3(0, 0.5f, 0);
        cube_x1.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        cube_x1.GetComponent<MeshRenderer>().material.color =Red_Color();
        // cube_x1.GetComponent<Renderer>().enabled = false;

        cube_x2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube_x2.transform.position = new Vector3(0, 0.5f, 0);
        cube_x2.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        cube_x2.GetComponent<MeshRenderer>().material.color =Red_Color();
        // cube_x2.GetComponent<Renderer>().enabled = false;

        cube_y1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube_y1.transform.position = new Vector3(0, 0.5f, 0);
        cube_y1.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        cube_y1.GetComponent<MeshRenderer>().material.color =Green_Color();
        cube_y1.GetComponent<Renderer>().enabled = false;

        cube_y2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube_y2.transform.position = new Vector3(0, 0.5f, 0);
        cube_y2.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        cube_y2.GetComponent<MeshRenderer>().material.color =Green_Color();
        cube_y2.GetComponent<Renderer>().enabled = false;

        cube_z1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube_z1.transform.position = new Vector3(0, 0.5f, 0);
        cube_z1.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        cube_z1.GetComponent<MeshRenderer>().material.color =Blue_Color();
        cube_z1.GetComponent<Renderer>().enabled = false;

        cube_z2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube_z2.transform.position = new Vector3(0, 0.5f, 0);
        cube_z2.transform.localScale = new Vector3(cube_size,cube_size,cube_size);
        cube_z2.GetComponent<MeshRenderer>().material.color =Blue_Color();
        cube_z2.GetComponent<Renderer>().enabled = false;
    }
    
    void intersection(AB_RAY _ray, AABB_BOX _box)
    {
        Vector3 ray_full = _ray.PB.position -_ray.PA.position;
        Vector3 ray_dir = Vector3.Normalize(ray_full); 
        Vector3 ray_min = _box.min - _ray.PA.position;
        Vector3 ray_max = _box.max - _ray.PA.position;

        Vector3 x_min , x_max;

        if (ray_min.magnitude > ray_max.magnitude)
        {
            Vector3 t = ray_min;
            ray_min = ray_max;
            ray_max = t;
        }
        if (ray_full.x == 0)
        {
            x_min = _ray.PA.position + ray_min.magnitude / ray_full.magnitude * ray_full;
            x_max = _ray.PA.position + ray_max.magnitude / ray_full.magnitude * ray_full;
        }
        else
        {
            x_min = _ray.PA.position + ray_min.x / ray_full.x * ray_full;
            x_max = _ray.PA.position + ray_max.x / ray_full.x * ray_full;
        }

        //print(x_min);
        cube_x1.transform.position = x_min;
        cube_x2.transform.position = x_max;

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
