using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpringRotationTest : MonoBehaviour
{
    public Transform targetObject;
    public float springConstant = 100f;
    public float dampingRatio = 0.1f;
    public Vector3 rotationAxis = Vector3.up;

    void Update()
    {
        float input = Input.GetAxis("Horizontal");
        float angle = input * 45f;

        float currentAngle = targetObject.localRotation.eulerAngles.y;
        float angleDiff = angle - currentAngle;
        float angularVelocity = targetObject.localRotation.eulerAngles.y - currentAngle;
        float springForce = angleDiff * springConstant - angularVelocity * dampingRatio;

        targetObject.RotateAround(targetObject.position, rotationAxis, springForce * Time.deltaTime);
    }
}
