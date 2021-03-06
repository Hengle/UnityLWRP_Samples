﻿Shader "N-IX/oldRandomizeOneWithTileColors"
{
    Properties
    {
        _Color("Tinting Color ", Color) = (1,1,1,1)
        _MainTex("Albedo Map", 2D) = "white" {}
        _RandomizatonOfTilesScaleMap("Randomize Noise Map", 2D) = "white" {}
        _RandomizatonOfTiles(" Randomize Tiles", Range(0.0, 1.0)) = 0
        [PerRendererData] _AllowedOffsett (" Offset  X Y of the UV", Vector) = (0,0,0,0)
        [PerRendererData] _ColorTint (" _ColorTint", Color) = (1,1,1,1)


        _ColorTOBeUsedFor("Color for use in Lerping", Color) = (0,0,0)

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
        _GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
        [Enum(Metallic Alpha,0,Albedo Alpha,1)] _SmoothnessTextureChannel ("Smoothness texture channel", Float) = 0

        [Gamma] _Metallic("Metallic Strength", Range(0.0, 1.0)) = 0.0
        _MetallicGlossMap("Metallic Map", 2D) = "white" {}

        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        [ToggleOff] _GlossyReflections("Glossy Reflections", Float) = 1.0

        _BumpScale("Bump Scale", Float) = 1.0
        [Normal] _BumpMap("Normal Map", 2D) = "bump" {}

        [HideInInspector] _Parallax ("Height Scale", Range (0.005, 0.08)) = 0.02
        [HideInInspector] _ParallaxMap ("Height Map", 2D) = "black" {}

        _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap("Occlusion Map", 2D) = "white" {}

        _EmissionColor("Emission Color", Color) = (0,0,0)
        _EmissionMap("Emission Map", 2D) = "white" {}

        _DetailMask("Detail Mask", 2D) = "white" {}

        _DetailAlbedoMap("Detail Albedo x2", 2D) = "grey" {}
        _DetailNormalMapScale("Scale", Float) = 1.0
        [Normal] _DetailNormalMap("Normal Map", 2D) = "bump" {}

        [Enum(UV0,0,UV1,1)] _UVSec ("UV Set for secondary textures", Float) = 0


        // Blending state
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
    }

    CGINCLUDE
    // #define _EMISSION 1
    ENDCG

    SubShader
    {

        // Forward Pass
        //
        Pass
        {
            Tags 
            { 
                "Queue"="Geometry" 
                "RenderType"="Opaque" 
                "LightMode" = "ForwardBase"
            }
            LOD 100
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vertBase
            #pragma fragment  frag  
            // custom frag
            // native Unity fragBase
            #pragma fragmentoption ARB_precision_hint_fastest


            #pragma shader_feature _NORMALMAP
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _EMISSION
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local _GLOSSYREFLECTIONS_OFF
            // #pragma shader_feature_local _PARALLAXMAP
            // #pragma shader_feature_local _DETAIL_MULX2

            // make fog work
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            // #include "AutoLight.cginc"
            #include "UnityStandardCoreForward.cginc"

            // #include "UnityStandardCoreForwardSimple.cginc"
            // VertexOutputBaseSimple vertBase (VertexInput v) { return vertForwardBaseSimple(v); }
            // VertexOutputForwardAddSimple vertAdd (VertexInput v) { return vertForwardAddSimple(v); }
            // half4 fragBase (VertexOutputBaseSimple i) : SV_Target { return fragForwardBaseSimpleInternal(i); }
            // half4 fragAdd (VertexOutputForwardAddSimple i) : SV_Target { return fragForwardAddSimpleInternal(i); }
            // #include "UnityStandardCore.cginc" 
            // Standart Default Shader
            // VertexOutputForwardBase vertBase (VertexInput v) { return vertForwardBase(v); }
            // VertexOutputForwardAdd vertAdd (VertexInput v) { return vertForwardAdd(v); }
            // half4 fragBase (VertexOutputForwardBase i) : SV_Target { return fragForwardBaseInternal(i); }
            // half4 fragAdd (VertexOutputForwardAdd i) : SV_Target { return fragForwardAddInternal(i); }

            // struct appdata
            // {
                //     float4 position_OS : POSITION;
                //     float2 uv : TEXCOORD0;
                //     float4 uv1 : TEXCOORD1;
                //     float4 uv2 : TEXCOORD2;                
                //     float3 normal : NORMAL;
                //     float4 tangent   : TANGENT;
                //     UNITY_VERTEX_INPUT_INSTANCE_ID
            // };
            
            // struct v2f
            // {
                //     float4 position_CS                    : SV_POSITION;
                //     float2 uv                             : TEXCOORD0;
                //     UNITY_FOG_COORDS(1)                   // TEXCOORD[number]
                //     float4 ambientOrLightmapUV            : TEXCOORD2;
                //     float4 tangentToWorldAndPackedData[3] : TEXCOORD3;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
                //     float4 eyeVecCustom                   : TEXCOORD8;  // eyeVecCustom.xyz | fogCoord
                //     #if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
                //         float3 posWorld                    : TEXCOORD5;
                //     #endif

                //     LIGHTING_COORDS(6, 7) // TEXCOORD[number1], TEXCOORD[number2]
                //     UNITY_VERTEX_INPUT_INSTANCE_ID
                //     UNITY_VERTEX_OUTPUT_STEREO
            // };

            // float _RandomizatonOfTilesScale;
            float _RandomizatonOfTiles;
            half4 _ColorTOBeUsedFor;    
            sampler2D _RandomizatonOfTilesScaleMap;
            float4 _RandomizatonOfTilesScaleMap_ST;

            UNITY_INSTANCING_BUFFER_START(Props)
                // put more per-instance properties here
                UNITY_DEFINE_INSTANCED_PROP(  float4, _AllowedOffsett)  // acces via UNITY_ACCESS_INSTANCED_PROP(Props, _AllowedOffsett);
                UNITY_DEFINE_INSTANCED_PROP(  float4, _ColorTint)  // acces via UNITY_ACCESS_INSTANCED_PROP(Props, _ColorTint);
            UNITY_INSTANCING_BUFFER_END(Props)

            // half4 GetAmbientOrLightFromUV_Custom(appdata input, float3 posWorld, half3 normalWorld)
            // {
                //     half4 ambientOrLightmapUV = 0;

                //     // Static lightmaps
                //     #ifdef LIGHTMAP_ON
                //         ambientOrLightmapUV.xy = input.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                //         ambientOrLightmapUV.zw = 0;
                //         // Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
                //     #elif UNITY_SHOULD_SAMPLE_SH
                //         #ifdef VERTEXLIGHT_ON
                //             // Approximated illumination from non-important point lights
                //             ambientOrLightmapUV.rgb = Shade4PointLights (
                //             unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                //             unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                //             unity_4LightAtten0, posWorld, normalWorld);
                //         #endif

                //         ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, ambientOrLightmapUV.rgb);
                //     #endif

                //     #ifdef DYNAMICLIGHTMAP_ON
                //         ambientOrLightmapUV.zw = input.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                //     #endif

                //     return ambientOrLightmapUV;
            // }

            float2 Unity_GradientNoise_Dir_float(float2 p)
            {
                // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }

            void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
            { 
                float2 p = UV * Scale;
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
                float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
            }

            inline float Unity_SimpleNoise_RandomValue_float (float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
            }

            inline float Unity_SimpleNnoise_Interpolate_float (float a, float b, float t)
            {
                return (1.0-t)*a + (t*b);
            }


            inline float Unity_SimpleNoise_ValueNoise_float (float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);

                uv = abs(frac(uv) - 0.5);
                float2 c0 = i + float2(0.0, 0.0);
                float2 c1 = i + float2(1.0, 0.0);
                float2 c2 = i + float2(0.0, 1.0);
                float2 c3 = i + float2(1.0, 1.0);
                float r0 = Unity_SimpleNoise_RandomValue_float(c0);
                float r1 = Unity_SimpleNoise_RandomValue_float(c1);
                float r2 = Unity_SimpleNoise_RandomValue_float(c2);
                float r3 = Unity_SimpleNoise_RandomValue_float(c3);

                float bottomOfGrid = Unity_SimpleNnoise_Interpolate_float(r0, r1, f.x);
                float topOfGrid = Unity_SimpleNnoise_Interpolate_float(r2, r3, f.x);
                float t = Unity_SimpleNnoise_Interpolate_float(bottomOfGrid, topOfGrid, f.y);
                return t;
            }
            void Unity_SimpleNoise_float(float2 UV, float Scale, out float Out)
            {
                float t = 0.0;

                float freq = pow(2.0, float(0));
                float amp = pow(0.5, float(3-0));
                t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(1));
                amp = pow(0.5, float(3-1));
                t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(2));
                amp = pow(0.5, float(3-2));
                t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                Out = t;
            }

            // parallax transformed texcoord is used to sample occlusion
            inline FragmentCommonData MetallicSetup_Custom (float4 i_tex, float3 posWorld)
            {
                half2 metallicGloss = MetallicGloss(i_tex.xy);
                half metallic = metallicGloss.x;
                half smoothness = metallicGloss.y; // this is 1 minus the square root of real roughness m.

                half oneMinusReflectivity;
                half3 specColor;

                // noise
                float StrenghOfNoise;
                float StrenghOfNois1;
                float StrenghOfNois2;


                //tex2D(_RandomizatonOfTiles_MAP, currentOne).r;
                // float2 c0 = i_tex.xy + float2(0.0, 0.0);
                // float2 c1 = i_tex.xy + float2(1.0, 0.0);
                // float2 r0 = float2(Unity_SimpleNoise_RandomValue_float(c0)*_RandomizatonOfTilesScale,Unity_SimpleNoise_RandomValue_float(c1)* _RandomizatonOfTilesScale);
                // r0 = float2(Unity_SimpleNnoise_Interpolate_float(i_tex.x,r0.x,_RandomizatonOfTilesScale),Unity_SimpleNnoise_Interpolate_float(i_tex.y,r0.y,_RandomizatonOfTilesScale) );
                float4 offestInstanced = UNITY_ACCESS_INSTANCED_PROP(Props, _AllowedOffsett);
                float2 uv_texture = i_tex.xy + offestInstanced.xy;
                

                float2 currenUVTarget =  float2(posWorld.x + uv_texture.x,posWorld.z + uv_texture.y);
                // Unity_GradientNoise_float(currenUVTarget, _RandomizatonOfTilesScale,StrenghOfNoise);
                // Unity_SimpleNoise_float(currenUVTarget, _RandomizatonOfTilesScale,StrenghOfNois1);
                currenUVTarget = TRANSFORM_TEX(currenUVTarget,_RandomizatonOfTilesScaleMap);
                StrenghOfNois2 = tex2D(_RandomizatonOfTilesScaleMap, currenUVTarget);

                StrenghOfNoise = StrenghOfNois2 ; // StrenghOfNoise + StrenghOfNois1 + StrenghOfNois2;
                // StrenghOfNoise = StrenghOfNoise ; *0.333;
                
                half3 albedoColor = Albedo(i_tex);
                albedoColor = albedoColor * lerp(albedoColor,UNITY_ACCESS_INSTANCED_PROP(Props, _ColorTint).xyz,_RandomizatonOfTiles );
                albedoColor = lerp(albedoColor,albedoColor * _ColorTOBeUsedFor, StrenghOfNoise *  _RandomizatonOfTiles);
                half3 diffColor = DiffuseAndSpecularFromMetallic ( albedoColor, metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

                FragmentCommonData o = (FragmentCommonData)0;
                o.diffColor = diffColor;
                o.specColor = specColor;
                o.oneMinusReflectivity = oneMinusReflectivity;
                o.smoothness = smoothness;
                return o;
            }

            FragmentCommonData FragmentSetup_Custom (float4 i_tex, float3 i_eyeVecCustom, half3 i_viewDirForParallax, float4 tangentToWorld[3], float3 i_posWorld)
            {
                i_tex = Parallax(i_tex, i_viewDirForParallax);

                half alpha = Alpha(i_tex.xy);
                #if defined(_ALPHATEST_ON)
                    clip (alpha - _Cutoff);
                #endif

                FragmentCommonData o = MetallicSetup_Custom (i_tex, i_posWorld);
                o.normalWorld = PerPixelWorldNormal(i_tex, tangentToWorld);
                o.eyeVec = NormalizePerPixelNormal(i_eyeVecCustom);
                o.posWorld = i_posWorld;

                // NOTE: shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
                o.diffColor = PreMultiplyAlpha (o.diffColor, alpha, o.oneMinusReflectivity, /*out*/ o.alpha);
                return o;
            }


            // v2f vert (appdata input)
            // {
                //     v2f output;

                //     UNITY_SETUP_INSTANCE_ID(input);
                //     UNITY_TRANSFER_INSTANCE_ID(input, output);
                //     UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                //     output.position_CS = UnityObjectToClipPos(input.position_OS);
                //     output.uv = TRANSFORM_TEX(input.uv, _MainTex);

                //     float4 posWorld = mul(unity_ObjectToWorld, input.position_OS);
                //     #if UNITY_REQUIRE_FRAG_WORLDPOS
                //         #if UNITY_PACK_WORLDPOS_WITH_TANGENT
                //             output.tangentToWorldAndPackedData[0].w = posWorld.x;
                //             output.tangentToWorldAndPackedData[1].w = posWorld.y;
                //             output.tangentToWorldAndPackedData[2].w = posWorld.z;
                //         #else
                //             output.posWorld = posWorld.xyz;
                //         #endif
                //     #endif

                //     float3 normalWorld = UnityObjectToWorldNormal(input.normal);
                //     #ifdef _TANGENT_TO_WORLD
                //         float4 tangentWorld = float4(UnityObjectToWorldDir(input.tangent.xyz), input.tangent.w);

                //         float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
                //         output.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
                //         output.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
                //         output.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
                //     #else
                //         output.tangentToWorldAndPackedData[0].xyz = 0;
                //         output.tangentToWorldAndPackedData[1].xyz = 0;
                //         output.tangentToWorldAndPackedData[2].xyz = normalWorld;
                //     #endif
                //     output.eyeVecCustom.xyz = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
                
                //     // Lightmap from Scratch   
                //     // output.ambientOrLightmapUV = input.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;

                //     // From Unity
                //     output.ambientOrLightmapUV = GetAmbientOrLightFromUV_Custom(input, posWorld, normalWorld);
                
                //     // Transfer realtime shadows
                //     TRANSFER_SHADOW(output);

                //     //We need this for shadow receving
                //     UNITY_TRANSFER_LIGHTING(output, input.uv1);

                //     // Transfer Fog
                //     UNITY_TRANSFER_FOG(output,output.position_CS);
                //     return output;
            // }

            // half4 frag (v2f input) : SV_Target
            // {
                //     UNITY_APPLY_DITHER_CROSSFADE(input.position_CS.xy);
                //     // sample the texture
                //     half4 col = tex2D(_MainTex, input.uv);

                //     FragmentCommonData s = FragmentSetup_Custom(col, input.eyeVecCustom, IN_VIEWDIR4PARALLAX(input), input.tangentToWorldAndPackedData,IN_WORLDPOS( input));
                //     UNITY_SETUP_INSTANCE_ID(input); 
                //     UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);


                //     UnityLight mainLight = MainLight ();
                //     UNITY_LIGHT_ATTENUATION(atten, input, s.posWorld);

                //     half occlusion = Occlusion(input.uv.xy);
                //     UnityGI gi = FragmentGI (s, occlusion, input.ambientOrLightmapUV, atten, mainLight);

                //     half4 c = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
                //     c.rgb += Emission(input.uv.xy);

                //     // apply fog
                //     UNITY_APPLY_FOG(input.fogCoord, col);
                //     col = OutputForward (col, s.alpha); // will make a clip from aplha

                //     return col;
            // }

            half4 frag (VertexOutputForwardBase i) : SV_Target
            {
                UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy); // LOD
                UNITY_SETUP_INSTANCE_ID(i);

                FragmentCommonData s = FragmentSetup_Custom(i.tex, i.eyeVec, IN_VIEWDIR4PARALLAX(i), i.tangentToWorldAndPackedData,IN_WORLDPOS(i));

                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                UnityLight mainLight = MainLight ();
                UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);

                half occlusion = Occlusion(i.tex.xy);
                UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, mainLight);

                half4 c = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
                c.rgb += Emission(i.tex.xy);

                UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
                UNITY_APPLY_FOG(_unity_fogCoord, c.rgb);
                return OutputForward (c, s.alpha);
            }

            ENDCG
        }
        //Pass  ------------------------------------------------------------------

        //  Shadow rendering pass
        //
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma target 3.0

            // -------------------------------------


            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature _PARALLAXMAP
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster

            #include "UnityStandardShadow.cginc"

            ENDCG
        }
        // Pass Shadow ------------------------------------------------------------------

        // //  Deferred pass
        // // 
        // Pass
        // {
        //     Name "DEFERRED"
        //     Tags { "LightMode" = "Deferred" }

        //     CGPROGRAM
        //     #pragma target 3.0
        //     #pragma exclude_renderers nomrt


        //     // -------------------------------------

        //     #pragma shader_feature _NORMALMAP
        //     #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
        //     #pragma shader_feature _EMISSION
        //     #pragma shader_feature _METALLICGLOSSMAP
        //     #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        //     #pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
        //     #pragma shader_feature ___ _DETAIL_MULX2
        //     #pragma shader_feature _PARALLAXMAP

        //     #pragma multi_compile_prepassfinal
        //     #pragma multi_compile_instancing
        //     // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
        //     //#pragma multi_compile _ LOD_FADE_CROSSFADE

        //     #pragma vertex vertDeferred
        //     #pragma fragment fragDeferred

        //     #include "UnityStandardCore.cginc"

        //     ENDCG
        // }
        // // Pass Deferred------------------------------------------------------------------

        // Extracts information for lightmapping, GI (emission, albedo, ...)
        // This pass it not used during regular rendering.
        Pass
        {
            Name "META"
            Tags { "LightMode"="Meta" }

            Cull Off

            CGPROGRAM
            #pragma vertex vert_meta
            #pragma fragment frag_meta

            #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature ___ _DETAIL_MULX2
            #pragma shader_feature EDITOR_VISUALIZATION

            #include "UnityStandardMeta.cginc"
            ENDCG
        }
    }
    Fallback "VertexLit"
}