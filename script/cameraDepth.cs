using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
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
    private Texture2D depth_texture;
    private bool write_once = false;
    // Start is called before the first frame update
    void Start()
    {
        Debug.Log(shader);
        Debug.Log(material);
        camera = GetComponent<Camera>();
        int w =128;
        int h =128;
        if (camera != null)
        {
        	w = camera.pixelWidth;
        	h = camera.pixelHeight;
        }

        Debug.Log("camera res : " + camera.pixelWidth);
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
		//https://docs.unity3d.com/Manual/SL-CameraDepthTexture.html
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

			if (!write_once)
			{
				depth_texture = new Texture2D(src.width, src.height, TextureFormat.RGB24, false);
				depth_texture.ReadPixels(new Rect(0, 0, src.width, src.height), 0, 0);
	 			depth_texture.Apply();

	 			byte[] bytes;
	     		bytes = depth_texture.EncodeToPNG();
	     		System.IO.File.WriteAllBytes( "d:my_depth.png", bytes );
	     		write_once = true;
			}


		}
		else
		{
			Graphics.Blit(src, dest);
		}
	}
}
