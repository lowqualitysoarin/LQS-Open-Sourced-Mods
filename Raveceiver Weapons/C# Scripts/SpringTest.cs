using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpringTest : MonoBehaviour
{
    public Transform baseTransform;

    // Update is called once per frame
    void Update()
    {
        baseTransform.position += Vector3.up * Mathf.Cos(Time.time);
    }
}
