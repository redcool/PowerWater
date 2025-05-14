#if !defined(POWER_WATER_CORE_HLSL)
#define POWER_WATER_CORE_HLSL
    float2 CalcOffsetTiling(float2 posXZ,float2 dir,float speed,float tiling){
        float2 uv = posXZ* tiling + dir * (speed *_Time.x);
        return uv ;
    }
    float3 CalcWorldPosFromDepth(float2 screenUV){
        float depth = tex2D(_CameraDepthTexture,screenUV).x;

        float3 bedPos = ScreenToWorldPos(screenUV,depth,unity_MatrixInvVP);
        return bedPos;
    }

    float CalcDepth(float3 bedPos,float3 worldPos,float3 depthRange/*(x:depth,yz:depth(min,max))*/){
        float depth = saturate(bedPos.y - worldPos.y - depthRange.x);
        return smoothstep(depthRange.y,depthRange.z,depth);
    }
//_FoamTex
    float3 CalcFoamColor(sampler2D tex,float2 uv,float3 blendNormal,float clampNoise,float offsetScale,float2 uvTiling,float2 uvOffset=0){
        float2 foamOffset = blendNormal.xz*0.05 + float2(clampNoise*0.1,0);
        foamOffset *= offsetScale;
        uv = frac(uv * uvTiling + foamOffset + uvOffset);
        float3 foamTex = tex2D(tex,uv).xyz;
        return foamTex;
    }
    

    float3 CalcSeaColor(float2 screenUV,float3 worldPos,float3 vertexNormal,float3 viewDir,float clampNoise,
        float3 blendNormal,float2 uv,out float seaSideDepth/**/,out float3 seaBedColor/**/
    ){
        seaSideDepth = 0;
        seaBedColor = 0;
        // -------------------- fresnel color
        half nv  = saturate(dot(vertexNormal,viewDir));
        float fresnel = 1- nv*nv;
        float3 seaColor = lerp(_Color1,_Color2,fresnel).xyz;
        // -------------------- noise depth shadow
        seaColor *= clampNoise;
#if SEA_SIMPLE
return seaColor;
#endif

        float3 bedPos = CalcWorldPosFromDepth(screenUV);// scene world position
        float seaDepth = CalcDepth(bedPos,worldPos,float3(_Depth,0,.5));
// return seaDepth;
        seaSideDepth =  CalcDepth(bedPos,worldPos,float3(_SeaSideDepth,0,0.1));
// return seaSideDepth;

        // -------------------- depth and shallow color
        seaColor *= lerp(_DepthColor,_ShallowColor,seaDepth).xyz;
// return seaColor;
        // -------------------- foam, depth is 0.5
        float foamDepth = CalcDepth(bedPos,worldPos,_FoamDepth);
// return foamDepth;
        float3 foamColor = CalcFoamColor(_FoamTex,uv,blendNormal,clampNoise,_FoamNoiseScale,_FoamTex_ST.xy,_FoamTex_ST.zw);
        seaColor += foamColor.xyz * _FoamColor * foamDepth;
#if SEA_FOAM
return seaColor;
#endif
        // -------------------- caustics ,depth is 1
        float causticsDepth = CalcDepth(bedPos,worldPos,_CausticsDepth);
        half3 causticsColor = CalcFoamColor(_CausticTex,uv,blendNormal*2,clampNoise ,_CausticsNoiseScale,_CausticTex_ST.xy,_Time.xx*_CausticTex_ST.zw+blendNormal*0.05);
        half3 causticsColor2 = CalcFoamColor(_CausticTex,uv,blendNormal,clampNoise ,_CausticsNoiseScale*0.5,_CausticTex_ST.xy,_Time.xx*_CausticTex_ST.zw*0.1+blendNormal*0.1);
// return causticsColor2;
        causticsColor *= causticsColor2;
        
        causticsColor *= _CausticsIntensity * _CausticsColor * causticsDepth;

        // -------------------- refraction color
        float refractionIntensity = _RefractionIntensity * (1-seaSideDepth);
        seaBedColor = tex2D(_CameraOpaqueTexture,screenUV + blendNormal.xz * clampNoise * refractionIntensity).xyz;
        float3 refractionColor = lerp(causticsColor,seaBedColor,seaDepth);
// return refractionColor ;
        seaColor += refractionColor;
// return seaColor;

        return lerp(seaColor,seaBedColor,seaSideDepth);
    }
#endif //POWER_WATER_CORE_HLSL