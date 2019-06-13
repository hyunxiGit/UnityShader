using UnityEngine;
using System;

[ExecuteInEditMode]
public class deferredFog : MonoBehaviour
{
    [NonSerialized]
	Material mat;
    public Shader deferedFogShader;
	//Shader vfxShader;
	//called when render image is finished
    [NonSerialized]
    Camera deferredCam;
    // [NonSerialized]
    // Vector3[] frustumCorners;
    // [NonSerialized]
    // Vector4[] vectorArray;

    //[ImageEffectOpaque]
	void OnRenderImage (RenderTexture src, RenderTexture dest)
	{
        if (deferedFogShader != null)
        {
            mat = new Material(deferedFogShader);
        }
        if (mat!=null)
        {

            deferredCam = GetComponent<Camera>();
            // frustumCorners = new Vector3[4];
            // vectorArray = new Vector4[4];
            // deferredCam.CalculateFrustumCorners( new Rect(0f, 0f, 1f, 1f),deferredCam.farClipPlane,deferredCam.stereoActiveEye,frustumCorners);
            // for(int i = 0; i<4;i++)
            // {
            //     vectorArray[i] = frustumCorners[i];
            // }
            // mat.SetVectorArray("_FrustumCorners" , vectorArray);
            Graphics.Blit(src,dest,mat);
        }
	}
    // Start is called before the first frame update
    void Start()
    {        

    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
