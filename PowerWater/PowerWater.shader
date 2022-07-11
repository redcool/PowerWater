Shader "URP/PowerWater"
{
    Properties
    {
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

        [Group(Wave)]
        [GroupHeader(Wave, Wave function)]
        [GroupEnum(Wave,None 0 ApplyGerstnerWave 1)]_ApplyGerstnerWaveOn("_ApplyGerstnerWaveOn",int) = 1
        [GroupHeader(Wave,Wave( Direction Steep Length))]
        [GroupVectorSlider(Wave,DirX dirZ steep waveLen,0_1 0_1 0_1 0_10)]
        _WaveDir("_WaveDir(xy:dir)(z: steep,w:waveLength)",vector) = (1,1,0.4,5)

        [GroupVectorSlider(Wave,DirXNoise dirZNoise steepNoise waveLenNoise,0_1 0_1 0_1 0_0.1)]
        _WaveDirNoiseScale("_WaveDirNoiseScale",vector) = (0,0,0,0)

        [GroupHeader(Wave,Wave Tiling)]
        [GroupVectorSlider(Wave,x z no no,0_10 0_10 0_1 0_1)]_WaveTiling("_WaveTiling",vector) = (0.1,1,0,0)
        [GroupItem(Wave)]_WaveScale("_WaveScale",range(0,1)) = 1
        [GroupItem(Wave)]_WaveSpeed("_WaveSpeed",float) = 1
        [GroupItem(Wave)]_WaveStrength("_WaveStrength",range(0,5)) = 1

        [GroupHeader(Wave, Noise Size)]
        [GroupItem(Wave)]_WaveNoiseMin("_WaveNoiseMin",range(0,1)) = 0.1
        [GroupItem(Wave)]_WaveNoiseMax("_WaveNoiseMax",range(0,1)) = 1

        [GroupHeader(Wave ,Crest Color)]
        [GroupItem(Wave)]_WaveCrestMin("_WaveCrestMin",range(0,1)) = 0.3
        [GroupItem(Wave)]_WaveCrestMax("_WaveCrestMax",range(0,1)) = 1


        [Group(Depth)]
        [GroupItem(Depth)]_Depth("_Depth",float) = -1.3
        [GroupItem(Depth)][hdr]_DepthColor("_DepthColor",color) = (0.5,0.7,.8,1)
        [GroupItem(Depth)][hdr]_ShallowColor("_ShallowColor",color) = (1,1,1,1)

        [Group(Env)]
        [GroupHeader(Env,Refraction)]
        [GroupItem(Env)]_RefractionIntensity("_RefractionIntensity",range(0,1)) = 0.5

        [GroupHeader(Env,Reflection)]
        [GroupItem(Env)][noscaleoffset]_ReflectionCubemap("_ReflectionCubemap",cube) = ""{}
        [GroupItem(Env)]_ReflectDirOffset("_ReflectDirOffset",vector) = (0,0,0,0)
        [GroupItem(Env)]_ReflectionIntensity("_ReflectionIntensity",range(0,2)) = 1

        [GroupHeader(Env,Fog)]
        [GroupToggle(Env)]_FogOn("_FogOn",int) = 1

        [Group(FoamAndCaustics)]
        [GroupItem(FoamAndCaustics)]_FoamTex("_FoamTex",2d) = ""{}
        [GroupItem(FoamAndCaustics)]_FoamDepthMin("_FoamDepthMin",range(0,1)) = 0
        [GroupItem(FoamAndCaustics)]_FoamDepthMax("_FoamDepthMax",range(0,1)) = 1
        [GroupItem(FoamAndCaustics)]_FoamSpeed("_FoamSpeed",float) = 1
        [GroupItem(FoamAndCaustics)]_FoamColor("_FoamColor",color) = (1,1,1,1)

        [Space(10)]
        [GroupHeader(FoamAndCaustics,Caustics)]
        [GroupItem(FoamAndCaustics)]_CausticsIntensity("_CausticsIntensity",range(0,3)) = 1
        [GroupItem(FoamAndCaustics)]_CausticsSpeed("_CausticsSpeed",float) = 1
        [GroupItem(FoamAndCaustics)]_CausticsTiling("_CausticsTiling",float) = 1
        [GroupItem(FoamAndCaustics)]_CausticsColor("_CausticsColor",color) = (.5,.5,.5,1)

        [Group(SunAndEye)]
        [GroupToggle(SunAndEye)]_FixedViewOn("_FixedViewOn",int) = 0
        [GroupItem(SunAndEye)]_ViewPosition("_ViewPosition",vector) = (10,-10,10)
    }
    SubShader
    {
        Tags{"Queue"="Transparent"}
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHTS

            // #define _REFLECTION_PROBE_BLENDING
            // #define _REFLECTION_PROBE_BOX_PROJECTION
            #include "PowerWaterForwardPass.hlsl"

            
            ENDHLSL
        }
    }
}
