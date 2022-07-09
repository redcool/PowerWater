#if !defined(POWER_WATER_INPUT_HLSL)
#define POWER_WATER_INPUT_HLSL
            
    sampler2D _MainTex;
    sampler2D _NormalMap;
    sampler2D _PBRMask;
    sampler2D _CameraOpaqueTexture;
    sampler2D _CameraDepthTexture;
    sampler2D _FoamTex;

    TEXTURECUBE(_ReflectionCubemap); SAMPLER(sampler_ReflectionCubemap);

    
    CBUFFER_START(UnityPerMaterial)
    float _Smoothness;
    float _Metallic;
    float _Occlusion;

    float _Depth;
    float4 _DepthColor,_ShallowColor;

    float _NormalScale;
    // float4 _NormalMap_ST;
    float _NormalSpeed,_NormalTiling;
    float4 _Color2,_Color1;

    float _ApplyGerstnerWaveOn;
    float2 _WaveTiling;
    float4 _WaveDir;
    float _WaveScale,_WaveSpeed,_WaveStrength;
    float _WaveCrestMax,_WaveCrestMin;
    float _WaveNoiseMin,_WaveNoiseMax;

    float4 _FoamTex_ST;
    float _FoamDepthMin,_FoamDepthMax,_FoamSpeed;
    half4 _FoamColor;

    float _RefractionIntensity;
    float _CausticsIntensity,_CausticsTiling,_CausticsSpeed;
    half4 _CausticsColor;

    float _FixedViewOn;
    float3 _ViewPosition;


    float3 _ReflectDirOffset;
    float _ReflectionIntensity;
    float4 _ReflectionCubemap_HDR;
    CBUFFER_END            

#endif //POWER_WATER_INPUT_HLSL