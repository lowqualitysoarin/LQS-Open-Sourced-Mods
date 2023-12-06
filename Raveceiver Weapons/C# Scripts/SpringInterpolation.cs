using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpringInterpolation : MonoBehaviour
{
    public Transform objToMove;
    public Transform target;

    public static float EaseInOutBack(float t)
    {
        const float c1 = 1.70158f;
        const float c2 = c1 * 1.525f;
        float t2 = t - 1f;
        return t < 0.5
            ? t * t * 2 * ((c2 + 1) * t * 2 - c2)
            : t2 * t2 * 2 * ((c2 + 1) * t2 * 2 + c2) + 1;
    }

    void Update()
    {
        objToMove.position = Vector3.LerpUnclamped(objToMove.position, target.position, EaseInOutBack(0.1f * Time.deltaTime));
    }
}
