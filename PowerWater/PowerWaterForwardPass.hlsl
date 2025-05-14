#if !defined(POWER_WATER_FORWARD_PASS_HLSL)
#define POWER_WATER_FORWARD_PASS_HLSL
    #include "../../PowerShaderLib/Lib/UnityLib.hlsl"
    #include "../../PowerShaderLib/Lib/PowerUtils.hlsl"
    #include "../../PowerShaderLib/Lib/NodeLib.hlsl"
    #include "../../PowerShaderLib/URPLib/Lighting.hlsl"
    #include "../../PowerShaderLib/Lib/FlowMapLib.hlsl"
    #include "../../PowerShaderLib/Lib/MaterialLib.hlsl"

    #include "PowerWaterInput.hlsl"
    #include "PowerWaterCore.hlsl"
    #include "../../PowerShaderLib/Lib/WaveLib.hlsl"
    #include "../../PowerShaderLib/Lib/FogLib.hlsl"

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
        float3 normal:NORMAL;
        float4 tangent:TANGENT;
    };

    struct v2f
    {
        float4 uvNoise : TEXCOORD0;
        float4 vertex : SV_POSITION;
        float4 tSpace0:TEXCOORD1;
        float4 tSpace1:TEXCOORD2;
        float4 tSpace2:TEXCOORD3;
        float2 fogCoord : TEXCOORD4;
    };


    v2f vert (appdata v)
    {
        v2f o = (v2f)0;
// simple noise
        float3 worldPos = TransformObjectToWorld(v.vertex.xyz);

        float2 dirModes[3] = {worldPos.xz,worldPos.xy,worldPos.yz};
        float2 dirMode = dirModes[_DirMode];

        float2 noiseUV = CalcOffsetTiling(dirMode * _WaveTiling.xy,_WaveDir.xy,_WaveSpeed,1);
        float simpleNoise = Unity_SimpleNoise_half(noiseUV,_WaveScale) ;
        // simpleNoise = simpleNoise * 2 - 1;
        simpleNoise = smoothstep(_WaveNoiseMin,_WaveNoiseMax,simpleNoise);


        float3 tangent = v.tangent.xyz;//normalize(float3(1,simpleNoise,0));
        float3 normal = v.normal; //float3(-tangent.y,tangent.x,0);

        // apply wave
        worldPos.y += simpleNoise * _WaveStrength;
        // if(_ApplyGerstnerWaveOn)
        #if defined(_GERSTNER_WAVE_ON)
        {
            half4 noiseScale = _WaveDirNoiseScale * (simpleNoise) + 0.00001;
            half4 noiseScaleSpeed = _WaveDirNoiseSpeed * (_Time.x*0.001);
            half4 waveDir = _WaveDir + noiseScale ;
            worldPos += GerstnerWave(tangent/**/,normal/**/,waveDir,worldPos,_WaveScrollSpeed);
            // simpleNoise = worldPos.y;
        }
        #endif

        o.vertex = TransformWorldToHClip(worldPos);

        o.uvNoise.xy = dirMode * _MainTex_ST.xy + _MainTex_ST.zw * _Time.yy;
        o.uvNoise.z = simpleNoise;


        float3 t = normalize(TransformObjectToWorldDir(tangent.xyz));
        float3 n = normalize(TransformObjectToWorldNormal(normal));
        float3 b = normalize(cross(n,t)) * v.tangent.w;

        o.tSpace0 = float4(t.x,b.x,n.x,worldPos.x);
        o.tSpace1 = float4(t.y,b.y,n.y,worldPos.y);
        o.tSpace2 = float4(t.z,b.z,n.z,worldPos.z);

        o.fogCoord = CalcFogFactor(worldPos);
        return o;
    }


    float4 frag (v2f i) : SV_Target
    {
        float2 mainUV = i.uvNoise.xy;
        float simpleNoise = i.uvNoise.z;
        float clampNoise = clamp(simpleNoise,0.3,1);
// return clampNoise;

        #if defined(_FLOW_MAP_ON)
        float4 flowDir = CalcFlowDir(_FlowMap,mainUV,_FlowMap_ST.xy,_FlowMap_ST.zw,_FlowInfo.xy,_FlowInfo.zw);
        // float2 flowDir = (tex2D(_FlowMap,mainUV* _FlowMap_ST.xy+_FlowMap_ST.zw*_Time.yy).xy*2-1) * _FlowInfo.xy + _FlowInfo.zw*_Time.yy;
        // float flowDirScale = smoothstep(0.3,0.6,flowDir.x);
        // flowDir.xy *= flowDirScale;
        #else
        float2 flowDir = 0;
        #endif //_FLOW_MAP_ON

        mainUV += flowDir.xy * _FlowMapApplyMainTexOn;

        float2 screenUV =  i.vertex.xy /_ScaledScreenParams.xy;

        float3 worldPos = float3(i.tSpace0.w,i.tSpace1.w,i.tSpace2.w);

        float2 dirModes[3] = {worldPos.xz,worldPos.xy,worldPos.yz};
        float2 dirMode = dirModes[_DirMode];

        float3 vertexTangent = (float3(i.tSpace0.x,i.tSpace1.x,i.tSpace2.x));
        float3 vertexBinormal = normalize(float3(i.tSpace0.y,i.tSpace1.y,i.tSpace2.y));
        float3 vertexNormal = normalize(float3(i.tSpace0.z,i.tSpace1.z,i.tSpace2.z));
// blend 2 normals 
        float2 worldUV = dirMode + flowDir.xy;
        float3 n = Blend2Normals(_NormalMap,worldUV,_NormalTiling,_NormalSpeed,_NormalScale,i.tSpace0.xyz,i.tSpace1.xyz,i.tSpace2.xyz);
        // float3 n = Blend2Normals(worldUV,i.tSpace0.xyz,i.tSpace1.xyz,i.tSpace2.xyz);
//------ brdf info
        _WorldSpaceCameraPos = _FixedViewOn ? _ViewPosition : _WorldSpaceCameraPos;

        float3 v = normalize(_WorldSpaceCameraPos - worldPos);

        float nv = saturate(dot(n,v));
// calc sea color
        half crestHeight = worldPos.y - _WaveCrestHeight;
        float waveCrestColor = smoothstep(_WaveCrestMin,_WaveCrestMax,crestHeight);
// return crestHeight; 
        // float4 seaColorDepth = CalcSeaColor(screenUV,worldPos,vertexNormal,v,clampNoise,n,mainUV);
        float seaSideDepth;
        float3 seaBedColor;
        float3 seaColor = CalcSeaColor(screenUV,worldPos,vertexNormal,v,clampNoise,n,mainUV,seaSideDepth/**/,seaBedColor/**/);
        seaColor += waveCrestColor;// * _WaveCrestColor;

        float3 emissionColor = 0;
//-------- pbr
        
        float4 pbrMask = tex2D(_PBRMask,mainUV);
        float smoothness = _Smoothness * pbrMask.y;
        float roughness = 1 - smoothness;
        float a = max(roughness * roughness, HALF_MIN_SQRT);
        float a2 = max(a * a ,HALF_MIN);

        float metallic = _Metallic * pbrMask.x;
        float occlusion = lerp(1, pbrMask.z,_Occlusion);

        float4 mainTex = tex2D(_MainTex, mainUV) * _Color;
        float3 albedo = mainTex.xyz * seaColor;
        float alpha = mainTex.w;
        float3 diffColor = albedo * (1-metallic);
        float3 specColor = lerp(0.04,albedo,metallic);
        float3 giDiff = CalcGIDiff(n,diffColor);
        float3 giSpec = CalcGISpec(_ReflectionCubemap,sampler_ReflectionCubemap,_ReflectionCubemap_HDR,specColor,worldPos,n,v,_ReflectDirOffset,_ReflectionIntensity,nv,roughness,a2,smoothness,metallic);

        float4 col = float4(0,0,0,1);
        col.xyz = (giDiff + giSpec) * occlusion;

        Light mainLight = GetMainLight();
        col.xyz += CalcLight(mainLight,diffColor,specColor,n,v,a,a2);
        #if defined(_ADDITIONAL_LIGHTS)
            float4 shadowMask = 0;
            col.xyz += CalcAdditionalLights(worldPos,diffColor,specColor,n,v,a,a2,shadowMask);
        #endif

//---------emission
        col.xyz += emissionColor;
//---------fog
        BlendFogSphere(col.xyz/**/,worldPos,i.fogCoord,true,false);
//--------- blend (sea bed, col)
        col.xyz = lerp(seaBedColor,col,(1-seaSideDepth));
        
        return half4(col.xyz,alpha);
    }
#endif //POWER_WATER_FORWARD_PASS_HLSL