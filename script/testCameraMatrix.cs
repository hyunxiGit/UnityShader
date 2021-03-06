﻿//testCamera matrix example : script
using System.Collections;
using System.Collections;
using UnityEngine;


public class testCameraMatrix : MonoBehaviour
{
	private Camera camera;
    // public Material material;

    private Shader _shader;
    private Shader shader
    {
         get { return _shader != null ? _shader : (_shader = Shader.Find("Hidden/testCamMatrix")); }
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

    //public Gameobject;
   
    // Start is called before the first frame update
    void Start()
    {
        camera = GetComponent<Camera>();
        Debug.Log(camera);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
	{

		Matrix4x4 worldToCameraMatrix = camera.worldToCameraMatrix ;
		Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(camera.projectionMatrix, false);
		material.SetMatrix("_WorldToCameraMatrix", worldToCameraMatrix);
        // Debug.Log(worldToCameraMatrix);
		material.SetMatrix("_ProjectionMatrix", projectionMatrix);

		Graphics.Blit(src, dest,material);
	}
}
