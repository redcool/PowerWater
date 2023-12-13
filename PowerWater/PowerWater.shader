Shader "URP/PowerWater"
{
    Properties
    {
        [GroupHeader(v(0.0.3))]
        [Group(Fresnel Color)]
        [GroupItem(Fresnel Color)][hdr]_Color1("_Color1",color) = (0,0.1,.99,1)
        [GroupItem(Fresnel Color)][hdr]_Color2("_Color2",color) = (0,0.34,.99,1)

        [Group(Main)]
        [GroupItem(Main)]_MainTex ("Texture", 2D) = "white" {}

        [GroupHeader(Main,Normal)]
        [GroupItem(Main)][NoScaleOffset]_NormalMap("_NormalMap",2d) = "bump"{}
        [GroupItem(Main)]_NormalScale("_NormalScale",range(0,4)) = .5
        [GroupItem(Main)]_NormalSpeed("_NormalSpeed",range(0,2)) = 1
        [GroupItem(Main)]_NormalTiling("_NormalTiling",float) = 0.1

        [GroupHeader(Main,PBR Mask)]
        [GroupItem(Main)]_PBRMask("_PBRMask(Metallic:R,Smoothness:G,Occlusion:B)",2d)="white"{}
        [GroupItem(Main)]_Metallic("_Metallic",range(0,1)) = 0.5
        [GroupItem(Main)]_Smoothness("_Smoothness",range(0,1)) = 0.9
        [GroupItem(Main)]_Occlusion("_Occlusion",range(0,1)) = 0
//------------ Wave 
        [Group(Wave)]
        [GroupHeader(Wave, Wave function)]
        [GroupEnum(Wave,SIMPLE _GERSTNER_WAVE_ON,true)]_ApplyGerstnerWaveOn("_ApplyGerstnerWaveOn",int) = 0

        [GroupHeader(Wave,Wave( Direction Steep Length))]
        [GroupVectorSlider(Wave,dirX dirZ steep(gerstner) waveLen(gerstner),0_1 0_1 0_1 0_10,,field)]
        _WaveDir("_WaveDir(xy:dir)(z:steep,w:waveLength gerstner only)",vector) = (1,1,0.4,5)

        [GroupVectorSlider(Wave,dirXNoise dirZNoise steepNoise waveLenNoise,0_1 0_1 0_1 0_0.1,gerstner use,field)]
        _WaveDirNoiseScale("_WaveDirNoiseScale (gerstner only)",vector) = (0,0,0,0)

        // [GroupVectorSlider(Wave,dirXNoiseSpeed dirZNoiseSpeed steepNoiseSpeed waveLenNoiseSpeed,0_1 0_1 0_1 0_0.1,gerstner use,field)]
        // _WaveDirNoiseSpeed("_WaveDirNoiseSpeed (gerstner only)",vector) = (0,0,0,0)

        [GroupItem(Wave,more big more quick)]_WaveScrollSpeed("_WaveScrollSpeed (gerstner only)",float) = 1

        [GroupHeader(Wave,Wave Tiling)]
        [GroupVectorSlider(Wave,x z ,0_10 0_10,scale world pos.xz ,field)]_WaveTiling("_WaveTiling",vector) = (0.1,1,0,0)
        [GroupItem(Wave, wave noise scale)]_WaveScale("_WaveScale",float) = 1
        [GroupItem(Wave)]_WaveSpeed("_WaveSpeed",float) = 1
        [GroupItem(Wave,worldPos.y move strength)]_WaveStrength("_WaveStrength",float) = 1

        [GroupHeader(Wave, Noise Range)]
        [GroupItem(Wave)]_WaveNoiseMin("_WaveNoiseMin",range(0,1)) = 0.1
        [GroupItem(Wave)]_WaveNoiseMax("_WaveNoiseMax",range(0,1)) = 1

        [GroupHeader(Wave ,Crest Color Range)]
        [GroupItem(Wave)]_WaveCrestHeight("_WaveCrestHeight",float) = 1
        [GroupItem(Wave)]_WaveCrestMin("_WaveCrestMin",range(0,1)) = 0.3
        [GroupItem(Wave)]_WaveCrestMax("_WaveCrestMax",range(0,1)) = 1

//------------ Depth 
        [Group(Depth)]
        [GroupItem(Depth)]_Depth("_Depth",float) = -1.3
        [GroupItem(Depth)][hdr]_DepthColor("_DepthColor",color) = (0.5,0.7,.8,1)
        [GroupItem(Depth)][hdr]_ShallowColor("_ShallowColor",color) = (1,1,1,1)

        [Group(Env)]
        [GroupHeader(Env,Refraction)]
        [GroupItem(Env,effect by normal)]_RefractionIntensity("_RefractionIntensity",float) = 0.5

        [GroupHeader(Env,Reflection)]
        [GroupItem(Env)][noscaleoffset]_ReflectionCubemap("_ReflectionCubemap",cube) = ""{}
        [GroupItem(Env)]_ReflectDirOffset("_ReflectDirOffset",vector) = (0,0,0,0)
        [GroupItem(Env)]_ReflectionIntensity("_ReflectionIntensity",range(0,2)) = 1

        [GroupHeader(Env,Fog)]
        [GroupToggle(Env)]_FogOn("_FogOn",int) = 1

        [Group(FoamAndCaustics)]
        [GroupEnum(FoamAndCaustics,_SEA_FULL SEA_SIMPLE SEA_FOAM,true)]_FoamMode("_FoamMode",int) = 0
        [GroupItem(FoamAndCaustics)]_FoamTex("_FoamTex",2d) = ""{}

        [GroupHeader(FoamAndCaustics,SeaSide Depth)]
        [GroupItem(FoamAndCaustics)]_SeaSideDepth("_SeaSideDepth",range(0,-0.21)) = -0.1

        [Space(10)]
        [GroupHeader(FoamAndCaustics,Foam)]
        [GroupItem(FoamAndCaustics)]
        
        [GroupVectorSlider(FoamAndCaustics,FoamDepth depthMin depthMax ,0_1 0_1 0_1 ,,field float float )]
        _FoamDepth("_FoamDepth(x:depth,yz:(Depth range))",vector) = (-0.13,0,0.15,0)

        [GroupItem(FoamAndCaustics)]_FoamSpeed("_FoamSpeed",float) = 1
        [GroupItem(FoamAndCaustics)]_FoamColor("_FoamColor",color) = (1,1,1,1)

        // [Space(10)]
        [GroupHeader(FoamAndCaustics,Caustics)]
        [GroupItem(FoamAndCaustics)]_CausticsIntensity("_CausticsIntensity",range(0,3)) = 1
        [GroupItem(FoamAndCaustics)]_CausticsSpeed("_CausticsSpeed",float) = 1
        [GroupItem(FoamAndCaustics)]_CausticsTiling("_CausticsTiling",float) = 1
        [GroupItem(FoamAndCaustics)]_CausticsColor("_CausticsColor",color) = (.5,.5,.5,1)

        [GroupVectorSlider(FoamAndCaustics,Depth depthMin depthMax,0_1 0_1 0_1,,field float float)]
        _CausticsDepth("_CausticsDepth(x:Depth,yz:(Depth range))",vector) = (-0.37,0,1,0)

        [Group(SunAndEye)]
        [GroupToggle(SunAndEye)]_FixedViewOn("_FixedViewOn",int) = 0
        [GroupItem(SunAndEye)]_ViewPosition("_ViewPosition",vector) = (10,-10,10)

        [Group(Alpha)]
        [GroupHeader(Alpha,BlendMode)]
        [GroupPresetBlendMode(Alpha,,_SrcMode,_DstMode)]_PresetBlendMode("_PresetBlendMode",int)=0
        // [GroupEnum(Alpha,UnityEngine.Rendering.BlendMode)]
        [HideInInspector]_SrcMode("_SrcMode",int) = 1
        [HideInInspector]_DstMode("_DstMode",int) = 0

        // [GroupHeader(Alpha,Premultiply)]
        // [GroupToggle(Alpha)]_AlphaPremultiply("_AlphaPremultiply",int) = 0

        // [GroupHeader(Alpha,AlphaTest)]
        // [GroupToggle(Alpha,ALPHA_TEST)]_AlphaTestOn("_AlphaTestOn",int) = 0
        // [GroupSlider(Alpha)]_Cutoff("_Cutoff",range(0,1)) = 0.5

        [Group(Settings)]
        [GroupEnum(Settings,UnityEngine.Rendering.CullMode)]_CullMode("_CullMode",int) = 2
		[GroupToggle(Settings)]_ZWriteMode("ZWriteMode",int) = 0
		/*
		Disabled,Never,Less,Equal,LessEqual,Greater,NotEqual,GreaterEqual,Always
		*/
		[GroupEnum(Settings,UnityEngine.Rendering.CompareFunction)]_ZTestMode("_ZTestMode",float) = 4  
    }
    SubShader
    {
        Tags{"Queue"="Transparent"}
        Pass
        {
			ZWrite[_ZWriteMode]
			Blend [_SrcMode][_DstMode]
			// BlendOp[_BlendOp]
			Cull[_CullMode]
			ztest[_ZTestMode]
			// ColorMask [_ColorMask]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_vertex _GERSTNER_WAVE_ON
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHTS

            // #pragma shader_feature_fragment ALPHA_TEST
            #pragma shader_feature_fragment _SEA_FULL SEA_SIMPLE SEA_FOAM

            // #define _REFLECTION_PROBE_BLENDING
            // #define _REFLECTION_PROBE_BOX_PROJECTION
            #include "PowerWaterForwardPass.hlsl"

            
            ENDHLSL
        }
    }
}
