#if !defined(POWER_WATER_CORE_HLSL)
#define POWER_WATER_CORE_HLSL
    float2 CalcOffsetTiling(float2 posXZ,float2 dir,float speed,float tiling){
        float2 uv = posXZ* tiling + dir * speed *_Time.x;
        return uv ;
    }
    float3 CalcWorldPos(float2 screenUV){
        float depth = tex2D(_CameraDepthTexture,screenUV).x;
        float3 wpos = ScreenToWorldPos(screenUV,depth,unity_MatrixInvVP);
        return wpos;
    }

    float3 Blend2Normals(float3 worldPos,float3 tSpace0,float3 tSpace1,float3 tSpace2){
        // calc normal uv then 2 normal blend
        float2 normalUV1 = CalcOffsetTiling(worldPos.xz,float2(1,0.2),_NormalSpeed,_NormalTiling);
        float2 normalUV2 = CalcOffsetTiling(worldPos.xz,float2(-1,-0.2),_NormalSpeed,_NormalTiling);

        float3 tn = UnpackNormalScale(tex2D(_NormalMap,normalUV1),_NormalScale);
        float3 tn2 = UnpackNormalScale(tex2D(_NormalMap,normalUV2),_NormalScale);
        tn = BlendNormal(tn,tn2);

        float3 n = normalize(float3(
            dot(tSpace0.xyz,tn),
            dot(tSpace1.xyz,tn),
            dot(tSpace2.xyz,tn)
        ));
        return n;
    }

    float3 CalcFoamColor(float2 uv,float3 wpos,float3 worldPos,float depth,float depthMin,float depthMax,float3 blendNormal,float clampNoise,float offsetSpeed,float2 uvTiling){
        float foamDepth = saturate(wpos.y - worldPos.y + depth);
        foamDepth = smoothstep(depthMin,depthMax,foamDepth);
// return foamDepth;
        float2 foamOffset = blendNormal.xz*0.05 + float2(clampNoise*0.1,0);
        foamOffset *= offsetSpeed;
        float3 foamTex = tex2D(_FoamTex,uv * uvTiling + foamOffset).xyz;
        return foamTex * foamDepth;
    }

    float3 CalcSeaColor(float2 screenUV,float3 worldPos,float3 vertexNormal,float3 viewDir,float clampNoise,float3 blendNormal,float2 uv){
        // -------------------- fresnel color
        float fresnel = 1-saturate(dot(vertexNormal,viewDir));
        float3 seaColor = lerp(_Color1,_Color2,fresnel).xyz;
        // -------------------- noise depth shadow
        // seaColor *= clampNoise;

        float3 wpos = CalcWorldPos(screenUV);// scene world position
        float seaDepth = saturate( wpos.y - worldPos.y - _Depth);
// return seaDepth;
        // -------------------- depth and shallow color
        seaColor *= lerp(_DepthColor,_ShallowColor,seaDepth).xyz;
        // return lerp(_DepthColor,_ShallowColor,seaDepth).xyz;
        // -------------------- caustics ,depth is 1
        float3 causticsColor = CalcFoamColor(uv,wpos,worldPos,0.5,0.3,0,blendNormal*2,clampNoise,_CausticsSpeed,_CausticsTiling);
        causticsColor *= _CausticsIntensity;
        // seaColor += causticsColor * seaDepth;
// return seaColor;

        // -------------------- refraction color
        float3 refractionColor = tex2D(_CameraOpaqueTexture,screenUV + blendNormal.xz * clampNoise * _RefractionIntensity).xyz;
        refractionColor = lerp(causticsColor,refractionColor,seaDepth);
// return refractionColor;
        seaColor += refractionColor * seaDepth;
        // seaColor = lerp(seaColor,refractionColor,seaDepth);

        // -------------------- foam, depth is 0.5
        float3 foamColor =  CalcFoamColor(uv,wpos,worldPos,0.5,_FoamDepthMin,_FoamDepthMax,blendNormal,clampNoise,_FoamSpeed,_FoamTex_ST.xy);
        seaColor += foamColor;

        return seaColor;
    }
#endif //POWER_WATER_CORE_HLSL