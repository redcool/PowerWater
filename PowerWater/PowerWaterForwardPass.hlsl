#if !defined(POWER_WATER_FORWARD_PASS_HLSL)
#define POWER_WATER_FORWARD_PASS_HLSL
    #include "PowerLib/UnityLib.hlsl"
    #include "PowerLib/PowerUtils.hlsl"
    #include "PowerLib/NodeLib.hlsl"
	#include "PowerLib/URPLib/Lighting.hlsl"



    #include "PowerWaterInput.hlsl"
    #include "PowerWaterCore.hlsl"
    #include "PowerLib/WaveLib.hlsl"
    #include "PowerLib/FogLib.hlsl"

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
        float2 noiseUV = CalcOffsetTiling(worldPos.xz * _WaveTiling.xy,_WaveDir.xy,_WaveSpeed,1);
        float simpleNoise = Unity_SimpleNoise_half(noiseUV,_WaveScale) ;
        // simpleNoise = (simpleNoise -0.5)*2;
        simpleNoise = smoothstep(_WaveNoiseMin,_WaveNoiseMax,simpleNoise);


        float3 tangent = v.tangent.xyz;//normalize(float3(1,simpleNoise,0));
        float3 normal = v.normal; //float3(-tangent.y,tangent.x,0);

        // apply wave
        v.vertex.y += simpleNoise * _WaveStrength;
        if(_ApplyGerstnerWaveOn){
            _WaveDir += _WaveDirNoiseScale * simpleNoise;
            // _WaveDir.zw += float2(.1,0.0001) * simpleNoise;
            v.vertex.xyz += GerstnerWave(_WaveDir,worldPos,tangent,normal);
            simpleNoise = v.vertex.y;
        }

        o.vertex = TransformObjectToHClip(v.vertex.xyz);

        o.uvNoise.xy = v.uv;
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
        float2 screenUV =  i.vertex.xy /_ScreenParams.xy;

        float3 worldPos = float3(i.tSpace0.w,i.tSpace1.w,i.tSpace2.w);
        float3 vertexTangent = (float3(i.tSpace0.x,i.tSpace1.x,i.tSpace2.x));
        float3 vertexBinormal = normalize(float3(i.tSpace0.y,i.tSpace1.y,i.tSpace2.y));
        float3 vertexNormal = normalize(float3(i.tSpace0.z,i.tSpace1.z,i.tSpace2.z));

        // float2 noiseUV = CalcOffsetTiling(worldPos.xz * _WaveTiling.xy,_WaveDir,_WaveSpeed,1);
        // simpleNoise = Unity_SimpleNoise_half(noiseUV,_WaveScale);
        // return simpleNoise;
// blend 2 normals 
        float3 n = Blend2Normals(worldPos,i.tSpace0.xyz,i.tSpace1.xyz,i.tSpace2.xyz);

//------ brdf info

        if(_FixedViewOn){
            _WorldSpaceCameraPos = _ViewPosition;
        }
        float3 v = normalize(GetWorldSpaceViewDir(worldPos));

        float nv = saturate(dot(n,v));
// calc sea color
        float waveCrestColor = smoothstep(_WaveCrestMin,_WaveCrestMax,simpleNoise);
// return waveCrestColor;        
        float3 seaColor = CalcSeaColor(screenUV,worldPos,vertexNormal,v,clampNoise,n,mainUV);
        seaColor += waveCrestColor;

        float3 emissionColor = 0;
//-------- pbr
        
        float4 pbrMask = tex2D(_PBRMask,mainUV);

        float smoothness = _Smoothness * pbrMask.y;
        float roughness = 1 - smoothness;
        float a = max(roughness * roughness, HALF_MIN_SQRT);
        float a2 = max(a * a ,HALF_MIN);
//         float d = nh*nh * (a2-1)+1;
// return a2/(d*d);

        float metallic = _Metallic * pbrMask.x;
        float occlusion = lerp(1, pbrMask.z,_Occlusion);

        float4 mainTex = tex2D(_MainTex, mainUV);
        float3 albedo = mainTex.xyz * seaColor;
        float alpha = mainTex.w;

        float3 diffColor = albedo * (1-metallic);
        float3 specColor = lerp(0.04,albedo,metallic);
		float3 giDiff = CalcGIDiff(n,diffColor);
		float3 giSpec = CalcGISpec(_ReflectionCubemap,sampler_ReflectionCubemap,_ReflectionCubemap_HDR,specColor,n,v,_ReflectDirOffset,_ReflectionIntensity,nv,roughness,a2,smoothness,metallic);

        float4 col = 0;
        col.xyz = (giDiff + giSpec) * occlusion;

        Light mainLight = GetMainLight();
        col.xyz += CalcLight(mainLight,diffColor,specColor,n,v,a,a2);

		#if defined(_ADDITIONAL_LIGHTS)
			col.xyz += CalcAdditionalLights(worldPos,diffColor,specColor,n,v,a,a2,0,0,0);
		#endif

//---------emission
        col.xyz += emissionColor;
//---------fog
        BlendFogSphere(col.xyz/**/,worldPos,i.fogCoord,false,false);
        
        return saturate(col);
    }
#endif //POWER_WATER_FORWARD_PASS_HLSL