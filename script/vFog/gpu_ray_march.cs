using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class gpu_ray_march : MonoBehaviour
{
    // Start is called before the first frame update
    public int max_steps = 500;
    public Texture3D volume;
    Camera cam;
    float step_size;
    Shader _shader;
    void Start()
    {
         //camera rays
        cam = this.gameObject.GetComponent(typeof(Camera)) as Camera;   
        cam.depthTextureMode = DepthTextureMode.Depth;    
		Vector4 z_step = new Vector4 (0,0, (cam.farClipPlane - cam.nearClipPlane) / max_steps,1);
		_shader = Shader.Find("Custom/volume_render_texture"); 
		Shader.SetGlobalVector("z_step", z_step);

    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
