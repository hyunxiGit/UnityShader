using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class temp_debug : MonoBehaviour
{
    // Start is called before the first frame update
    Camera cam;
     public GameObject cube;
    void Start()
    {
    	cam = this.gameObject.GetComponent(typeof(Camera)) as Camera;
        Matrix4x4 w2o =cube.transform.worldToLocalMatrix;
        Matrix4x4 o2w =cube.transform.localToWorldMatrix;
        Vector3 z_step = new Vector4 (0,0, (cam.farClipPlane - cam.nearClipPlane) / 100);
        z_step = w2o.MultiplyVector(z_step);
   		Debug.Log(z_step.ToString("F4"));     

        // Vector3 p = o2w.MultiplyPoint3x4(new Vector3(-0.5f, -0.5f, -0.5f));
   
        // Debug.Log(p.ToString("F4"));
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
