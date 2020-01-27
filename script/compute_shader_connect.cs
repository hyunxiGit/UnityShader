using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class compute_shader_connect : MonoBehaviour
{
	public Texture input;

    public int width = 512;
    public int height = 512;

	public RenderTexture renderTexPing;
	public ComputeShader compute;

	public RenderTexture result;
    // Start is called before the first frame update
    void Start()
    {
    	int kernel = compute.FindKernel("CSMain");
    	result = new RenderTexture(512,512,24);
        result.enableRandomWrite = true;
        result.Create();

        renderTexPing = new RenderTexture(width, height, 24);
        renderTexPing.wrapMode = TextureWrapMode.Repeat;
        renderTexPing.enableRandomWrite = true;
        renderTexPing.filterMode = FilterMode.Point;
        renderTexPing.useMipMap = false;
        renderTexPing.Create();

        compute.SetFloat("Width", width);
        compute.SetFloat("Height", height);

		compute.SetTexture(kernel, "Input", input);
        compute.SetTexture(kernel, "Result" , result);
        compute.Dispatch(kernel, width/8, height/8, 1);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
