Shader "URP/Nature/FlowRiver"
{
    Properties
    {
        [Group(Main)]
        // _MainTex ("Texture", 2D) = "white" {}
        [GroupItem(Main)] _Color("_Color",color) = (1,1,1,1)

        [GroupHeader(Main,Spec1)]
        [GroupItem(Main)] _SpecTex1("_SpecTex1",2d) = ""{}
        [GroupItem(Main)] [hdr]_SpecColor1("_SpecColor1",color) = (1,1,1,1)
        [GroupItem(Main)] _SpecNoiseScale1("_SpecNoiseScale1",float) = 0.01

        [GroupHeader(Main,Spec2)]
        [GroupItem(Main)] _SpecTex2("_SpecTex2",2d) = ""{}
        [GroupItem(Main)] [hdr]_SpecColor2("_SpecColor2",color) = (1,1,1,1)
        [GroupItem(Main)] _SpecNoiseScale2("_SpecNoiseScale2",float) = 0.01

        [Group(FlowMap)]
        [GroupHeader(FlowMap,FlowMap)]
        [GroupItem(FlowMap,control uv offset)] _FlowMap("_FlowMap",2d) = ""{}

        [Group(Foam)]
        [GroupHeader(Foam,Foam Tex)]
        [GroupItem(Foam)] _FoamTex("_FoamTex",2d) = ""{}
        [GroupItem(Foam)] [hdr]_FoamColor("_FoamColor",color) = (1,1,1,1)
        [GroupItem(Foam)] _FoamNoiseScale("_FoamNoiseScale",float) = 0.01

        [GroupHeader(Foam,Foam Depth)]
        [GroupItem(Foam,show foam in range)] _FoamDepth("_FoamDepth",float) = 1

        [GroupVectorSlider(Foam,Bottom_X Bottom_Y Top_X Top_Y,0_1 0_1 0_1 0_1,control foam fading range)]
        _FoamDepthRange("_FoamDepthRange",vector) = (0,1,0,1)

        [Group(Alpha)]
        [GroupHeader(Alpha,BlendMode)]
        [GroupPresetBlendMode(Alpha,,_SrcMode,_DstMode)]_PresetBlendMode("_PresetBlendMode",int)=0
        // [GroupEnum(Alpha,UnityEngine.Rendering.BlendMode)]
        [HideInInspector]_SrcMode("_SrcMode",int) = 5
        [HideInInspector]_DstMode("_DstMode",int) = 10

        // [GroupHeader(Alpha,Premultiply)]
        // [GroupToggle(Alpha)]_AlphaPremultiply("_AlphaPremultiply",int) = 0

        // [GroupHeader(Alpha,AlphaTest)]
        // [GroupToggle(Alpha,ALPHA_TEST)]_AlphaTestOn("_AlphaTestOn",int) = 0
        // [GroupSlider(Alpha)]_Cutoff("_Cutoff",range(0,1)) = 0.5

        [Group(Settings)]
        [GroupEnum(Settings,UnityEngine.Rendering.CullMode)]_CullMode("_CullMode",int) = 2
		[GroupToggle(Settings)]_ZWriteMode("ZWriteMode",int) = 0
		/*
		Disabled,Never,Less,Equal,LessEqual,Greater,NotEqual,GreaterEqual,Always
		*/
		[GroupEnum(Settings,UnityEngine.Rendering.CompareFunction)]_ZTestMode("_ZTestMode",float) = 4  
    }

    HLSLINCLUDE
            #include "../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../PowerShaderLib/Lib/DepthLib.hlsl"
            #include "../../PowerShaderLib/URPLib/URP_Input.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos:TEXCOORD1;
            };

            // sampler2D _MainTex;
            sampler2D _SpecTex1,_SpecTex2;
            sampler2D _FlowMap;
            sampler2D _FoamTex;

            sampler2D _CameraDepthTexture;

            CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            // float4 _MainTex_ST;
            float4 _SpecTex1_ST,_SpecTex2_ST;
            float4 _SpecColor1,_SpecColor2;
            float _SpecNoiseScale1,_SpecNoiseScale2;
            // float2 _SpecDir1,_SpecDir2;

            float4 _FlowMap_ST;

            float4 _FoamTex_ST;
            float4 _FoamColor;
            float _FoamDepth;
            float4 _FoamDepthRange;
            float _FoamNoiseScale;

            CBUFFER_END

            sampler2D _DepthTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                // o.uv.xy = v.uv * _SpecTex1_ST.xy + _SpecTex1_ST.zw * _Time.y;
                // o.uv.zw = v.uv * _SpecTex2_ST.xy + _SpecTex2_ST.zw * _Time.y;
                return o;
            }

            void ApplySpec(inout float4 col,sampler2D tex,float2 uv,float4 color){
                float4 spec1 = tex2D(tex,uv) * color;
                col = lerp(col,spec1,spec1.w);
                // col.w = lerp(col.w,1,spec1.w);
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = _Color;
                float3 curWorldPos = i.worldPos;
                //----- FlowMap
                float2 flowUv = i.uv * _FlowMap_ST.xy + _FlowMap_ST.zw * _Time.y;
                float4 flowMap = tex2D(_FlowMap,flowUv) * 2 - 1;

                //----- SpecMap
                float2 spec1UV = i.uv * _SpecTex1_ST.xy + _SpecTex1_ST.zw * _Time.y + flowMap.x * _SpecNoiseScale1;
                ApplySpec(col,_SpecTex1,spec1UV,_SpecColor1);

                float2 spec2UV = i.uv * _SpecTex2_ST.xy + _SpecTex2_ST.zw * _Time.y + flowMap.x * _SpecNoiseScale2;
                ApplySpec(col,_SpecTex2,spec2UV,_SpecColor2);

                //----- Foam 
                float2 screenUV = i.vertex.xy/_ScaledScreenParams.xy;
                float rawDepth = tex2D(_CameraDepthTexture,screenUV).x;
                float3 worldPos = ScreenToWorldPos(screenUV,rawDepth,UNITY_MATRIX_I_VP);
                float foamRate = 1-saturate(curWorldPos.y - worldPos.y - _FoamDepth);
                // ------ bottom fading
                float bottomFading = smoothstep(_FoamDepthRange.x,_FoamDepthRange.y,foamRate);
// return foamRate;
                // ------ top fading
                float topFading = saturate(curWorldPos.y - worldPos.y);
                topFading = smoothstep(_FoamDepthRange.z,_FoamDepthRange.w,topFading);
// return topFading;
                float foamFading = min(bottomFading,topFading);
                foamRate = lerp(foamFading,foamRate,foamFading);

                float2 foamUV = i.uv * _FoamTex_ST.xy + _FoamTex_ST.zw * _Time.y + flowMap.x * _FoamNoiseScale;
                float4 foamTex= tex2D(_FoamTex,foamUV) * _FoamColor;
                col = lerp(col,foamTex,foamRate);
                
                // ------ alpha fading with topFading
                // col.a *= topFading;

                return col;
            }

    ENDHLSL
    SubShader
    {
        Tags { "RenderType"="Transparent" "queue"="transparent"}
        LOD 100

        ZWrite[_ZWriteMode]
        Blend [_SrcMode][_DstMode]
        // BlendOp[_BlendOp]
        Cull[_CullMode]
        ztest[_ZTestMode]
        // ColorMask [_ColorMask]

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}
