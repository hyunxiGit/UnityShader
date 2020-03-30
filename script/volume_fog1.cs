using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class compare_Fx_3d_position : MonoBehaviour
{
	private Shader _shader;
    private Shader shader
    {
         get { return _shader != null ? _shader : (_shader = Shader.Find("Hidden/volume_fog")); }
    }

    private Material _material;
    private Material material
    {
         get
         {
             if (_material == null)
             {
                 _material = new Material(shader);
                 _material.hideFlags = HideFlags.HideAndDontSave;
             }
             return _material;
         }
    }

    private Camera camera;

    // Start is called before the first frame update
    void Start()
    {
        // Debug.Log(shader);
        // Debug.Log(material);
        camera = GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		if (shader != null)
		{
			Vector3[] frustumCorners = new Vector3[4];
	        camera.CalculateFrustumCorners(new Rect(0f, 0f, 1f, 1f),camera.farClipPlane,camera.stereoActiveEye,frustumCorners);

    		Vector4[] vectorArray = new Vector4[4] ;
	  //       //pass to shader to the correct order
			vectorArray[0] = frustumCorners[0];
			vectorArray[1] = frustumCorners[3];
			vectorArray[2] = frustumCorners[1];
			vectorArray[3] = frustumCorners[2];

			material.SetVectorArray("_FrustumCorners" , vectorArray);
			Shader.SetGlobalMatrix("_InverseViewMatrix", camera.cameraToWorldMatrix);
		}

		Graphics.Blit(src, dest, material);
	}
}
