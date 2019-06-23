using UnityEngine;
using System;

[ExecuteInEditMode]
public class deferredFog : MonoBehaviour
{
    [NonSerialized]
	public Material mat;
    public Shader deferedFogShader;
	//Shader vfxShader;
	//called when render image is finished
    [NonSerialized]
    Camera deferredCam;
    [NonSerialized]
    Vector3[] frustumCorners;
    [NonSerialized]
    Vector4[] vectorArray;

    [ImageEffectOpaque]
	void OnRenderImage (RenderTexture src, RenderTexture dest)
	{
        if (deferedFogShader != null)
        {
            mat = new Material(deferedFogShader);
            if (mat!=null)
            {
                deferredCam = GetComponent<Camera>();
                frustumCorners = new Vector3[4];
                vectorArray = new Vector4[4];
                deferredCam.CalculateFrustumCorners( new Rect(0f, 0f, 1f, 1f),deferredCam.farClipPlane,deferredCam.stereoActiveEye,frustumCorners);


                vectorArray[0] = frustumCorners[0];
                vectorArray[1] = frustumCorners[3];
                vectorArray[2] = frustumCorners[1];
                vectorArray[3] = frustumCorners[2];
                //pass the vector to the shader
                mat.SetVectorArray("_FrustumCorners" , vectorArray);
                Graphics.Blit(src,dest,mat);
            }
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
