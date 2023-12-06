Shader "Custom/ScopeShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Crosshair ("Crosshair", 2D) = "white" {}
        _Glare ("Glare", 2D) = "white" {}

        _CrosshairColor ("Crosshair Color", Color) = (1, 1, 1, 1)

        _ShiftAmount ("Shift amount", float) = 5
        _Radius ("Radius", Range(0, 1)) = 0.5
        _Softness ("Softness", Range(0, 1)) = 0.1
        _FadePower ("Fade Power", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 centerShift : TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _Crosshair;
            sampler2D _Glare;
            float4 _MainTex_ST;
            float4 _CrosshairColor;
            float _ShiftAmount;
            float _Radius;
            float _Softness;
            float _FadePower;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.centerShift = float4(UnityObjectToViewPos(v.vertex), 1);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float2 shiftedUv = i.uv + float2(i.centerShift.x * _ShiftAmount, i.centerShift.y * _ShiftAmount);
                fixed4 glare = tex2D(_Glare, i.uv);
                fixed4 col = tex2D(_MainTex, shiftedUv);

                // crosshair setup
                fixed4 crosshair = tex2D(_Crosshair, shiftedUv);

                float chAlpha = crosshair.r;
                chAlpha = 1 - pow(1 - chAlpha, _FadePower);
                crosshair.a = chAlpha;

                crosshair = crosshair * _CrosshairColor;

                // tunnel vision
                float2 center = float2(0.5, 0.5);
                float2 delta = i.uv - center;
                float distance = length(delta);
                float radius = _Radius;
                float softness = _Softness;
                float falloff = 1.0 - smoothstep(radius, radius + softness, distance);

                // finalize
                float4 finalColor = crosshair * crosshair.a + col * falloff * (1 - crosshair.a) + glare * glare.a;
                UNITY_APPLY_FOG(i.fogCoord, finalColor);

                return finalColor;
            }
            ENDCG
        }
    }
}