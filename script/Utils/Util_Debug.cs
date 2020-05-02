using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;

public class DCube
{
    private GameObject _cube;
    private bool _used;
    public DCube(string n, float s, Vector3 p, Color c)
    {
        this._cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
        this._cube.transform.position = p;
        this._cube.transform.localScale = new Vector3(s,s,s);
        this._cube.GetComponent<MeshRenderer>().material.color = c;
        this._cube.GetComponent<MeshRenderer>().enabled = false;
        this._cube.name = n;
        this.release();
    }
    public Vector3 position
    {
        set{this._cube.transform.position = value;}
    } 
    public Color color
    {
        set{this._cube.GetComponent<MeshRenderer>().material.color = value;}
    }
    public Transform transform
    {
        get{return this._cube.transform;}
    }
    public GameObject cube
    {
        get{return this._cube;}
    }
    public bool used_state
    {
        get{return this._used;}
    }
    public void use()
    {
        this.show( true);
        this._used = true;
    }
    public void release()
    {
        this.show(false);
        this._used = false;
    }
    public void show(bool show)
    {
        this._cube.GetComponent<MeshRenderer>().enabled = show;
    }
    public void setParent (Transform p)
    {
        this._cube.transform.parent = p;
    }
}

public class DCube_pool
{
    private List <DCube> _pool;
    public DCube_pool ()
    {
        this._pool =  new List<DCube>();
        newDcube();
    }  

    DCube newDcube()
    {
        string n = "cube_" + (_pool.Count + 1).ToString();
        DCube rcube = new DCube(n, 0.04f, new Vector3(0,0,0),  Color.gray);
        _pool.Add(rcube);
        return rcube;
    } 

    public DCube getDCube( int i = -1)
    {   
        DCube rcube = null;
        //not search by index
        if (i == -1)
        {
            foreach (DCube c in _pool)
            {
                if (c.used_state == false)
                {
                    rcube = c; 
                    break;
                }
            }
            if (rcube == null)
            {
                rcube = newDcube();
            }
        }
        else
        {

            rcube = _pool.ElementAt(i);
            // FindIndex(i);

        }
        
        
        rcube.position = new Vector3(0,0,0);
        rcube.use();
        return rcube;
    }

    public void killDcube(DCube c)
    {
        if (_pool.Contains (c))
        {
            c.release();
        }
    }
}