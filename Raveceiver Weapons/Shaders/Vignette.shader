// Made by ChatGPT, because I am absolute dogwater in shader making.
Shader "Custom/Vignette Cutout" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _VignetteColor ("Vignette Color", Color) = (0,0,0,1)
        _VignetteAmount ("Vignette Amount", Range(0,1)) = 0.5
        _AlphaThreshold ("Alpha Threshold", Range(0,1)) = 0.1
    }

    SubShader {
        Tags {"Queue"="Transparent" "RenderType"="Opaque"}

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _VignetteColor;
            float _VignetteAmount;
            float _AlphaThreshold;

            v2f vert (appdata v) {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                float4 texColor = tex2D(_MainTex, i.uv);
                float4 vignetteColor = lerp(texColor, _VignetteColor, _VignetteAmount);

                float2 dist = i.uv - 0.5;
                float vignetteAmount = 1.0 - length(dist) * 2.0;
                vignetteAmount = clamp(vignetteAmount, 0.0, 1.0);

                if (texColor.a < _AlphaThreshold) {
                    discard;
                }

                return vignetteColor * vignetteAmount;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}