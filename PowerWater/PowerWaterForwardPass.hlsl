#if !defined(POWER_WATER_FORWARD_PASS_HLSL)
#define POWER_WATER_FORWARD_PASS_HLSL
    #include "PowerLib/UnityLib.hlsl"
    #include "PowerLib/PowerUtils.hlsl"
    #include "PowerLib/NodeLib.hlsl"
    #include "PowerLib/URP_GI.hlsl"

    sampler2D _MainTex;
    sampler2D _NormalMap;
    sampler2D _PBRMask;
    sampler2D _CameraOpaqueTexture;
    sampler2D _CameraDepthTexture;
    sampler2D _FoamTex;

    #include "PowerWaterInput.hlsl"
    #include "PowerWaterCore.hlsl"
    #include "PowerLib/WaveLib.hlsl"

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
        float3 normal:NORMAL;
        float4 tangent:TANGENT;
    };

    struct v2f
    {
        half4 uvNoise : TEXCOORD0;
        half4 vertex : SV_POSITION;
        float4 tSpace0:TEXCOORD1;
        float4 tSpace1:TEXCOORD2;
        float4 tSpace2:TEXCOORD3;
    };


    v2f vert (appdata v)
    {
        v2f o = (v2f)0;
// simple noise
        half3 worldPos = TransformObjectToWorld(v.vertex.xyz);
        half2 noiseUV = CalcOffsetTiling(worldPos.xz * _WaveTiling.xy,_WaveDir,_WaveSpeed,1);
        half simpleNoise = Unity_SimpleNoise_half(noiseUV,_WaveScale) ;
        simpleNoise = (simpleNoise -0.5)*2;


        half3 tangent = v.tangent.xyz;//normalize(half3(1,simpleNoise,0));
        half3 normal = v.normal; //half3(-tangent.y,tangent.x,0);

        // apply wave
        v.vertex.y += simpleNoise * _WaveStrength;
        if(_ApplyGerstnerWaveOn){
            v.vertex.xyz += GerstnerWave(_WaveDir,worldPos,tangent,normal);
            simpleNoise = v.vertex.y;
        }

        o.vertex = TransformObjectToHClip(v.vertex);

        o.uvNoise.xy = v.uv;
        o.uvNoise.z = simpleNoise;


        half3 t = normalize(TransformObjectToWorldDir(tangent.xyz));
        half3 n = normalize(TransformObjectToWorldNormal(normal));
        half3 b = normalize(cross(n,t)) * v.tangent.w;

        o.tSpace0 = half4(t.x,b.x,n.x,worldPos.x);
        o.tSpace1 = half4(t.y,b.y,n.y,worldPos.y);
        o.tSpace2 = half4(t.z,b.z,n.z,worldPos.z);


        return o;
    }

    half4 frag (v2f i) : SV_Target
    {
        half2 mainUV = i.uvNoise.xy;
        half simpleNoise = i.uvNoise.z;
        half clampNoise = clamp(simpleNoise,0.3,1);
// return clampNoise;
        half2 screenUV =  i.vertex.xy /_ScreenParams.xy;

        half3 worldPos = half3(i.tSpace0.w,i.tSpace1.w,i.tSpace2.w);
        half3 vertexTangent = (half3(i.tSpace0.x,i.tSpace1.x,i.tSpace2.x));
        half3 vertexBinormal = normalize(half3(i.tSpace0.y,i.tSpace1.y,i.tSpace2.y));
        half3 vertexNormal = normalize(half3(i.tSpace0.z,i.tSpace1.z,i.tSpace2.z));

        // half2 noiseUV = CalcOffsetTiling(worldPos.xz * _WaveTiling.xy,_WaveDir,_WaveSpeed,1);
        // half simpleNoise = Unity_SimpleNoise_half(noiseUV,_WaveScale);
// blend 2 normals 
        half3 n = Blend2Normals(worldPos,i.tSpace0.xyz,i.tSpace1.xyz,i.tSpace2.xyz);

//------ brdf info
        half3 l = GetWorldSpaceLightDir(worldPos);

        if(_FixedViewOn){
            _WorldSpaceCameraPos = _ViewPosition;
        }
        half3 v = normalize(GetWorldSpaceViewDir(worldPos));

        half3 h = normalize(l+v);
        half nl = saturate(dot(n,l));
        half nv = saturate(dot(n,v));
        half nh = saturate(dot(n,h));
        half lh = saturate(dot(l,h));
// calc sea color
        half waveCreast = smoothstep(_WaveCrestMin,_WaveCrestMax,simpleNoise);
        
        half3 seaColor = CalcSeaColor(screenUV,worldPos,vertexNormal,v,clampNoise,n,mainUV);
        seaColor += waveCreast;
// return seaColor.xyzx;
        half3 emissionColor = 0;
//-------- pbr
        
        half4 pbrMask = tex2D(_PBRMask,mainUV);

        half smoothness = _Smoothness * pbrMask.y;
        half roughness = 1 - smoothness;
        half a = max(roughness * roughness, HALF_MIN_SQRT);
        half a2 = max(a * a ,HALF_MIN);
//         half d = nh*nh * (a2-1)+1;
// return a2/(d*d);

        half metallic = _Metallic * pbrMask.x;
        half occlusion = lerp(1, pbrMask.z,_Occlusion);

        half4 mainTex = tex2D(_MainTex, mainUV);
        half3 albedo = mainTex.xyz * seaColor;
        half alpha = mainTex.w;

        half3 diffColor = albedo * (1-metallic);
        half3 specColor = lerp(0.04,albedo,metallic);

        half3 sh = SampleSH(n);
        half3 giDiff = sh * diffColor;

        half mip = roughness * (1.7 - roughness * 0.7) * 6;
        half3 reflectDir = reflect(-v,n);
        half4 envColor = 0;
        // envColor.xyz = GlossyEnvironmentReflection(reflectDir,worldPos,roughness,1);
// ibl as reflection
        envColor = SAMPLE_TEXTURECUBE_LOD(_GlossyEnvironmentCubeMap,sampler_GlossyEnvironmentCubeMap,reflectDir,mip);
        envColor.xyz = DecodeHDREnvironment(envColor,_GlossyEnvironmentCubeMap_HDR);

        half surfaceReduction = 1/(a2+1);
        
        half grazingTerm = saturate(smoothness + metallic);
        half fresnelTerm = Pow4(1-nv);
        half3 giSpec = surfaceReduction * envColor.xyz * lerp(specColor,grazingTerm,fresnelTerm);

        half4 col = 0;
        col.xyz = (giDiff + giSpec) * occlusion;

        half3 radiance = nl * _MainLightColor.xyz;
        half specTerm = MinimalistCookTorrance(nh,lh,a,a2);

        col.xyz += (diffColor + specColor * specTerm) * radiance;
//---------emission
        col.xyz += emissionColor;
        return col;
    }
#endif //POWER_WATER_FORWARD_PASS_HLSL