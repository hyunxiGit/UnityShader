using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class cameraDepth : MonoBehaviour
{
	[Range(0f, 3f)]
    public float depthLevel = 0.5f;

	private Shader _shader;
    private Shader shader
    {
         get { return _shader != null ? _shader : (_shader = Shader.Find("Custom/RenderDepth")); }
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
        Debug.Log(shader);
        Debug.Log(material);
        camera = GetComponent<Camera>();
 		if (!SystemInfo.supportsImageEffects)
		{
			Debug.Log("System doesn't support image effects");
			enabled = false;
			return;
		}
 		if (shader == null || !shader.isSupported)
		{
			enabled = false;
			Debug.Log("Shader " + shader.name + " is not supported");
			return;
		}

		// turn on depth rendering for the camera so that the shader can access it via _CameraDepthTexture
		camera.depthTextureMode = DepthTextureMode.Depth;
    }

	private void OnDisable()
    {
        if (_material != null)
        	DestroyImmediate(_material);
    }

 	private void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		if (shader != null)
		{
			material.SetFloat("_DepthLevel", depthLevel);
			Graphics.Blit(src, dest, material);
		}
		else
		{
			Graphics.Blit(src, dest);
		}
	}
}
