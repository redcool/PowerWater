#if !defined(POWER_WATER_INPUT_HLSL)
#define POWER_WATER_INPUT_HLSL
            
    CBUFFER_START(UnityPerMaterial)
    half _Smoothness;
    half _Metallic;
    half _Occlusion;

    half _Depth;
    half4 _DepthColor,_ShallowColor;

    half _NormalScale;
    // half4 _NormalMap_ST;
    half _NormalSpeed,_NormalTiling;
    half4 _Color2,_Color1;

    half _ApplyGerstnerWaveOn;
    half2 _WaveTiling;
    half4 _WaveDir;
    half _WaveScale,_WaveSpeed,_WaveStrength;
    half _WaveCrestMax,_WaveCrestMin;

    half4 _FoamTex_ST;
    half _FoamDepthMin,_FoamDepthMax,_FoamSpeed;

    half _RefractionIntensity;
    half _CausticsIntensity,_CausticsTiling,_CausticsSpeed;

    CBUFFER_END            

#endif //POWER_WATER_INPUT_HLSL