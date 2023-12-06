Shader "Custom/TunnelVisionCutoff" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _Radius ("Radius", Range(0, 1)) = 0.5
        _Softness ("Softness", Range(0, 1)) = 0.1
        _Invert ("Invert", Range(0, 1)) = 0.0
        _FadeOut ("Fade Out", Range(0, 1)) = 0.2
    }

    SubShader {
        Tags {"Queue"="Transparent" "RenderType"="Opaque"}

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float _Radius;
            float _Softness;
            float _Invert;
            float _FadeOut;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                float2 center = float2(0.5, 0.5);
                float2 delta = i.uv - center;
                float distance = length(delta);
                float radius = _Radius;
                float softness = _Softness;
                float falloff = smoothstep(radius, radius + softness, distance);
                if (_Invert > 0) {
                    falloff = 1.0 - falloff;
                }
                float fadeOut = smoothstep(0.0, _FadeOut, falloff);
                return tex2D(_MainTex, i.uv) * falloff * fadeOut;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}