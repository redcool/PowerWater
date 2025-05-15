#if !defined(POWER_WATER_CORE_HLSL)
#define POWER_WATER_CORE_HLSL

    float3 CalcWorldPosFromDepth(float2 screenUV){
        float depth = tex2D(_CameraDepthTexture,screenUV).x;

        float3 bedPos = ScreenToWorldPos(screenUV,depth,unity_MatrixInvVP);
        return bedPos;
    }

    float CalcDepth(float3 bedPos,float3 worldPos,float3 depthRange/*(x:depth,yz:depth(min,max))*/){
        // xz plane: 1 component, xy : 2 , yz:0
        half compId = (_DirMode+1)%3;
        float bedPosArr[3] = {bedPos.x,bedPos.y,worldPos.z};
        float worldPosArr[3] = {worldPos.x,worldPos.y,bedPos.z};
        float depth = saturate(bedPosArr[compId] - worldPosArr[compId] - depthRange.x);

        // depth = saturate(bedPos.z - worldPos.z -depthRange.x);
        depth = smoothstep(depthRange.y,depthRange.z,depth);
        return depth;
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
        float3 blendNormal,float2 uv,out float seaSideDepth/**/,out float3 seaBedColor/**/,
        half faceId/*1: front,2:back face*/
    ){
        seaSideDepth = 0;
        seaBedColor = 0;
        // -------------------- fresnel color
        float nv  = saturate(dot(vertexNormal,viewDir));
        float fresnel = 1- nv*nv;
        float3 seaColor = lerp(_Color1,_Color2,fresnel).xyz;
        // -------------------- noise depth shadow
        seaColor *= clampNoise;
#if SEA_SIMPLE
return seaColor;
#endif
        float3 bedPos = CalcWorldPosFromDepth(screenUV);// scene world position
        bedPos*= faceId;

        float seaDepth = CalcDepth(bedPos,worldPos,float3(_Depth,0,.5));
        seaSideDepth =  CalcDepth(bedPos,worldPos,float3(_SeaSideDepth,0,0.1));
        seaSideDepth *= faceId;
        // -------------------- depth and shallow color
        seaColor *= lerp(_DepthColor,_ShallowColor,seaDepth).xyz;
        // -------------------- foam, depth is 0.5
        float foamDepth = CalcDepth(bedPos,worldPos,_FoamDepth);
        float3 foamColor = CalcFoamColor(_FoamTex,uv,blendNormal,clampNoise,_FoamNoiseScale,_FoamTex_ST.xy,_FoamTex_ST.zw);
        seaColor += foamColor.xyz * _FoamColor * foamDepth;

#if SEA_FOAM
return seaColor;
#endif
        // -------------------- caustics ,depth is 1
        float causticsDepth = CalcDepth(bedPos,worldPos,_CausticsDepth);
        half3 causticsColor = CalcFoamColor(_CausticTex,uv,blendNormal*2,clampNoise ,_CausticsNoiseScale,_CausticTex_ST.xy,_Time.xx*_CausticTex_ST.zw+blendNormal*0.05);
        half3 causticsColor2 = CalcFoamColor(_CausticTex,uv,blendNormal,clampNoise ,_CausticsNoiseScale*0.5,_CausticTex_ST.xy,_Time.xx*_CausticTex_ST.zw*0.1+blendNormal*0.1);

        causticsColor *= causticsColor2;        
        causticsColor *= _CausticsIntensity * _CausticsColor * causticsDepth;

        // -------------------- refraction color
        float refractionIntensity = _RefractionIntensity * (1-seaSideDepth); // front face
        refractionIntensity += faceId>0?0 : .1; // back face

        seaBedColor = tex2D(_CameraOpaqueTexture,screenUV + blendNormal.xz * clampNoise * refractionIntensity).xyz;

        float3 refractionColor = lerp(causticsColor,seaBedColor,seaDepth);
// return refractionColor ;
        seaColor += refractionColor;
        return lerp(seaColor,seaBedColor,seaSideDepth);
    }
#endif //POWER_WATER_CORE_HLSL