using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HideOverlayObject : MonoBehaviour
{
    [SerializeField] GameObject overlayOBJ;

    void OnPreCull()
    {
        overlayOBJ.SetActive(false);
    }

    void OnPreRender()
    {
        overlayOBJ.SetActive(true);
    }
}
