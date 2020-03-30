//capture screen depth and save as a texture : script
//render target example
//post process backbon , pass cam frustrum to shader and build 3d pos
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
         get { return _shader != null ? _shader : (_shader = Shader.Find("Hidden/RenderDepth")); }
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

    Vector3[] frustumCorners;
    Vector4[] vectorArray;

    // Start is called before the first frame update
    void Start()
    {
        Debug.Log(shader);
        Debug.Log(material);
        camera = GetComponent<Camera>();
        //calculate frustrum

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

			frustumCorners = new Vector3[4];
	        camera.CalculateFrustumCorners(new Rect(0f, 0f, 1f, 1f),camera.farClipPlane,camera.stereoActiveEye,frustumCorners);
	        vectorArray = new Vector4[4];
	        //pass to shader to the correct order
			vectorArray[0] = frustumCorners[0];
			vectorArray[1] = frustumCorners[3];
			vectorArray[2] = frustumCorners[1];
			vectorArray[3] = frustumCorners[2];

			material.SetVectorArray("_FrustumCorners" , vectorArray);
			var projectionMatrix = GL.GetGPUProjectionMatrix(camera.projectionMatrix, false).inverse;
			material.SetMatrix("_InverseProjectionMatrix", projectionMatrix);
			var inverseViewMatrix = camera.worldToCameraMatrix.inverse ;
			material.SetMatrix("_InverseViewMatrix", inverseViewMatrix);

	        Debug.Log("cfrustrum : " + frustumCorners[0]+frustumCorners[1]);

			Graphics.Blit(src, dest, material);
			// write to a static texture
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
