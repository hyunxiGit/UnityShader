using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AB_RAY
{
    public Transform PA;
    public Transform PB;

    public AB_RAY (Transform A , Transform B)
    {
        this.PA = A;
        this.PB = B;
    }
    public Vector3 fullRay
    {
        get
        { 
            return  PB.position - PA.position;
        }
    }
}
