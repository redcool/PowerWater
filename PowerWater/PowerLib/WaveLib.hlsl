#if !defined(WAVE_LIB_HLSL)
#define WAVE_LIB_HLSL

half3 GerstnerWave(half4 wave,half3 p,inout half3 tangent,inout half3 binormal){
    half steepness = wave.z;
    half waveLength = max(0.001,wave.w);
    half k = 2 * PI / waveLength;
    half c = sqrt(9.8/k);
    half2 d = normalize(wave.xy);
    float f = k * dot(d,p.xz) - c * _Time.y;
    half a = steepness/k;

    tangent += half3(
        -d.x * d.x * steepness * sin(f),
        d.x * steepness * cos(f),
        -d.x * d.y * steepness * sin(f)
    );
    binormal += half3(
        -d.x * d.y * steepness * sin(f),
        d.y * steepness * cos(f),
        -d.y * d.y * steepness * sin(f)
    );

    return half3(
        d.x * a * cos(f),
        a * sin(f),
        d.y * a*cos(f)
    );
}

#endif //WAVE_LIB_HLSL