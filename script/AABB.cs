using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AABB_BOX
{
	public Vector3 min;
	public Vector3 max;

	public AABB_BOX (GameObject go)
	{
		this.min = go.transform.position - go.transform.lossyScale/2;
		this.max = go.transform.position + go.transform.lossyScale/2;
		// print ("go :" + go.transform.position);
  		// print ("go :" + go.transform.lossyScale);
	}
}
public class AABB : MonoBehaviour
{
	public Transform prefab;
	GameObject my_gameObjecto ;
    // Start is called before the first frame update
    void Start()
    {
    	if (this.name != "aabb")
    	{
    		my_gameObjecto = gameObject;
    	}
    	else return;

    	makeBox(my_gameObjecto);

    }

   void makeBox(GameObject go)
   {
   		AABB_BOX box = new AABB_BOX(go);

        Transform point_min = Instantiate<Transform>(prefab);
        point_min.position = box.min;
        point_min.GetComponent<MeshRenderer>().material.color =Red_Color();

        Transform point_max = Instantiate<Transform>(prefab);
        point_max.position = box.max;
        point_max.GetComponent<MeshRenderer>().material.color =Green_Color();

   }
    Color Red_Color()
    {
    	return new Color(1,0,0);
    }
    Color Green_Color()
    {
    	return new Color(0,1,0);
    }
    Color Blue_Color()
    {
    	return new Color(0,0,1);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
