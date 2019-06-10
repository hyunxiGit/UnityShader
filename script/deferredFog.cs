using UnityEngine;

[ExecuteInEditMode]
public class deferredFog : MonoBehaviour
{
	Material mat;
    public Shader deferedFogShader;
	//Shader vfxShader;
	//called when render image is finished
	void OnRenderImage (RenderTexture src, RenderTexture dest)
	{

        if (mat!=null)
        {
		  Graphics.Blit(src,dest,mat);
        }
	}
    // Start is called before the first frame update
    void Start()
    {        
        if (deferedFogShader != null)
        {
            mat = new Material(deferedFogShader);
            print ("build material");
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
