﻿Shader "Photo Filters/X-Filter"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _Ramp ("Ramp", 3D) = "white" { }
        _VignetteRadius ("Vignette Radius", Range(0, 1)) = 0
        _VignetteSoftness ("Vignette Softness", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "PreviewType"="Plane" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "PhotoFilterHelper.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler3D _Ramp;
            float _VignetteRadius;
            float _VignetteSoftness;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                col = tex3D(_Ramp, saturate(float3(col.r, col.g, col.b)));
                col.rgb = max(col.rgb, ToGrayscale(Noise(round(i.uv * _ScreenParams.xy))) * 0.25);
                
                fixed4 vignette = Vignette(i.uv, _VignetteRadius, _VignetteSoftness);
                col = lerp(OverlayBlend(vignette, col), col, vignette);
                
                return col;
            }
            ENDCG
        }
    }
}
