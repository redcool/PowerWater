#if !defined(POWER_WATER_INPUT_HLSL)
#define POWER_WATER_INPUT_HLSL
            
sampler2D _MainTex;
sampler2D _NormalMap;
sampler2D _PBRMask;
sampler2D _CameraOpaqueTexture;
sampler2D _CameraDepthTexture;
sampler2D _FoamTex;
sampler2D _FlowMap;
sampler2D _CausticTex;

TEXTURECUBE(_ReflectionCubemap); SAMPLER(sampler_ReflectionCubemap);


CBUFFER_START(UnityPerMaterial)
half _Smoothness;
half _Metallic;
half _Occlusion;

half _Depth;
half4 _DepthColor,_ShallowColor;
half _SeaSideDepth;

half _NormalScale;
// half4 _NormalMap_ST;
half _NormalSpeed,_NormalTiling;
half4 _Color2,_Color1;
half4 _MainTex_ST;

half _ApplyGerstnerWaveOn;
half _WaveScrollSpeed;
half2 _WaveTiling;
half4 _WaveDir;
half4 _WaveDirNoiseScale;
// half4 _WaveDirNoiseSpeed;
half _WaveScale,_WaveSpeed,_WaveStrength;
half _WaveCrestMax,_WaveCrestMin,_WaveCrestHeight;
half _WaveNoiseMin,_WaveNoiseMax;
// half4 _WaveCrestColor;

half4 _FoamTex_ST;
half4 _FoamDepth;
half _FoamNoiseScale;
half4 _FoamColor;

half _RefractionIntensity;
half4 _CausticTex_ST;
half _CausticsIntensity,_CausticsNoiseScale; //_CausticsTiling
half4 _CausticsColor;
half4 _CausticsDepth;

half _FixedViewOn;
half3 _ViewPosition;


half3 _ReflectDirOffset;
half _ReflectionIntensity;
half4 _ReflectionCubemap_HDR;
half _FogOn;

half4 _FlowMap_ST;
half4 _FlowInfo;
half _FlowMapApplyMainTexOn;

half4 _Color;
half _DirMode;
CBUFFER_END            

#endif //POWER_WATER_INPUT_HLSL