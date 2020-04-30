using System.Collections;
using System.Collections.Generic;
using UnityEngine;

class AABB
{
    private GameObject cube;
    public AABB (GameObject _cube)
    {
        this.cube = _cube;
    }
    public Vector3 pos
    {
        get{ return this.cube.transform.position;}
    }

    public Vector3 min
    {
        get
        { 
            return cube.transform.position - cube.transform.lossyScale/2;
        }
    }
    public Vector3 max
    {
        get
        { 
            return cube.transform.position + cube.transform.lossyScale/2;
        }
    }
}


class OBB
{
    private GameObject cube;
    //public Matrix4x4 worldInverse;

    public OBB (GameObject _cube)
    {
        this.cube = _cube;
    }

    public Vector3 pos
    {
        get{ return this.cube.transform.position;}
    }

    public Matrix4x4 w2o
    {
        get{ return this.cube.transform.worldToLocalMatrix;}
    }
    public Matrix4x4 o2w
    {
        get{ return this.cube.transform.localToWorldMatrix;}
    }
    public Vector3 x_axis
    {
        get
        { 
            Matrix4x4 o2w =this.cube.transform.localToWorldMatrix;
            return Vector3.Normalize(new Vector3(o2w[0,0] ,o2w[1,0] , o2w[2,0]));
        }
    }

    public Vector3 y_axis
    {
        get
        { 
            Matrix4x4 o2w =this.cube.transform.localToWorldMatrix;       
            return Vector3.Normalize(new Vector3(o2w[0,1] ,o2w[1,1] , o2w[2,1]));
        }
    }
    public Vector3 z_axis
    {
        get
        { 
            Matrix4x4 o2w =this.cube.transform.localToWorldMatrix;
            return Vector3.Normalize(new Vector3(o2w[0,2] ,o2w[1,2] , o2w[2,2]));
        }
    }
    public Vector3 min
    {
        get
        { 
            Matrix4x4 o2w =this.cube.transform.localToWorldMatrix;
            return o2w.MultiplyPoint3x4(new Vector3(-0.5f,-0.5f,-0.5f));
        }
    }
    public Vector3 max
    {
        get
        { 
            Matrix4x4 o2w =this.cube.transform.localToWorldMatrix;
            return o2w.MultiplyPoint3x4(new Vector3(0.5f,0.5f,0.5f));
        }
    }
    public Vector3 min_o
    {
        get
        { 
            return new Vector3(-0.5f,-0.5f,-0.5f);
        }
    }
    public Vector3 max_o
    {
        get
        { 
            return new Vector3(0.5f,0.5f,0.5f);
        }
    }
    public float diagonal
    {
        get
        { 
            Vector3 _scale = this.cube.transform.lossyScale;
            return  Mathf.Sqrt(_scale.x *_scale.x + _scale.y * _scale.y + _scale.z *_scale.z );
        }
    }

}