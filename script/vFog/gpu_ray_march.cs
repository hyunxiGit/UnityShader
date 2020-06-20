using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;

public class gpu_ray_march : MonoBehaviour
{
    // Start is called before the first frame update
    public int max_steps = 500;
    public GameObject _cube;
    Camera cam;
    float step_size;
    Shader _shader;
    void Start()
    {
        //
         //camera rays
        cam = this.gameObject.GetComponent(typeof(Camera)) as Camera;   
        cam.GetComponent(typeof(Collider));
        cam.depthTextureMode = DepthTextureMode.Depth;    
		Vector4 z_step = new Vector4 (0,0, (cam.farClipPlane - cam.nearClipPlane) / max_steps,1);
		_shader = Shader.Find("Custom/volume_render_texture"); 
		Shader.SetGlobalVector("z_step", z_step);

    }

    bool isVFog(GameObject o)
    {
        return Object.ReferenceEquals (o, _cube);
    }

    void flipFace(GameObject o)
    {
        //镜头进入vfog反面
        Mesh mesh = o.GetComponent<MeshFilter>().mesh;
        print(mesh);
        mesh.triangles = mesh.triangles.Reverse().ToArray();
    }

    private void OnTriggerEnter(Collider other)
    {
        if (isVFog (other.gameObject))
        {
            print ("enter");
            flipFace(other.gameObject);
        }
    }

    private void OnTriggerExit(Collider other)
    {
        if (isVFog (other.gameObject))
        {
            print ("exit");
            flipFace(other.gameObject);
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
