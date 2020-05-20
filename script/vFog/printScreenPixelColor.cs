//a class to help print the screen based color
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class printScreenPixelColor : MonoBehaviour
{
	Texture2D tex ;
	Camera cam;
	Vector3 mpos;
	bool clicked = false;
    // WaitForEndOfFrame frameEnd = new WaitForEndOfFrame();
    // Start is called before the first frame update
    void Start()
    {
        cam = this.gameObject.GetComponent(typeof(Camera)) as Camera;
    }

    void sshot()//:Texture2D
	{
	    // Make a new texture of the right size and
	    // read the camera image into it.

	    var tex = new Texture2D(Screen.width, Screen.height, TextureFormat.RGB24, false);
	    tex.ReadPixels(new Rect(0, 0, Screen.width, Screen.height), 0, 0);
	    tex.Apply();
	 
	    var bla = tex.GetPixel  ( (int)(mpos.x), (int)(mpos.y) );
	    print(bla);
	    print("inside");
	    // Destroy (tex);
	    //return tex;
	    clicked = false;
	}
	void moonrake ()
	{
	    mpos = Input.mousePosition;
	    
	    var ray = cam.ScreenPointToRay (mpos);
	    GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
	    cube.transform.localScale = new Vector3(20f, 20f, 1f);
	    cube.transform.position = new Vector3(0f, 0.5f, 0f);
	    cube.transform.LookAt(cam.transform,Vector3.up);
	    Destroy (cube.GetComponent<Renderer>().material);
	 
	    // Application.CaptureScreenshot("Assets/savedmeshes/assets/ " + "Screenshot2.png");
	    // sshot();
	}
	public void OnPostRender()
    {
    	if(clicked)
    	{
		    sshot();
    	}
    }

    void Update()
    {
        if (Input.GetMouseButtonDown(2)) 
        { 
        	clicked = true;
        	print("clicked");
        	moonrake();
        }
    }
}
