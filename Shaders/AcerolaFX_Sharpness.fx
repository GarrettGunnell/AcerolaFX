#include "Includes/AcerolaFX_Sharpness.fxh"

#ifndef AFX_SHARPNESS_CLONE_COUNT
    #define AFX_SHARPNESS_CLONE_COUNT 0
#endif

uniform int _Filter <
    ui_category = "Sharpness 1 Settings";
    ui_category_closed = true;
    ui_type = "combo";
    ui_label = "Filter Type";
    ui_items = "Basic\0"
               "Adaptive\0";
    ui_tooltip = "Which sharpness filter to use.";
> = 0;

uniform float _Sharpness <
    ui_category = "Sharpness 1 Settings";
    ui_category_closed = true;
    ui_min = -1.0f; ui_max = 1.0f;
    ui_label = "Sharpness";
    ui_type = "drag";
    ui_tooltip = "Adjust sharpening strength.";
> = 0.0f;

uniform float _SharpnessFalloff <
    ui_category = "Sharpness 1 Settings";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 0.01f;
    ui_label = "Sharpness Falloff";
    ui_type = "slider";
    ui_tooltip = "Adjust rate at which sharpness falls off at a distance.";
> = 0.0f;

uniform float _Offset <
    ui_category = "Sharpness 1 Settings";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 1000.0f;
    ui_label = "Falloff Offset";
    ui_type = "slider";
    ui_tooltip = "Offset distance at which sharpness starts to falloff.";
> = 0.0f;

float4 PS_AdaptiveSharpness(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = saturate(tex2D(Common::AcerolaBuffer, uv));

    float3 output = 0;
    if (_Filter == 0) Basic(uv, _Sharpness, output);
    if (_Filter == 1) Adaptive(uv, _Sharpness, output);
    
    if (_SharpnessFalloff > 0.0f) {
        float depth = ReShade::GetLinearizedDepth(uv);
        float viewDistance = depth * 1000;

        float falloffFactor = 0.0f;

        falloffFactor = (_SharpnessFalloff / log(2)) * max(0.0f, viewDistance - _Offset);
        falloffFactor = exp2(-falloffFactor);

        output = lerp(col.rgb, output, saturate(falloffFactor));
    }

    return float4(output, col.a);
}

technique AFX_AdaptiveSharpness <ui_label = "Sharpness"; ui_tooltip = "(LDR) Increases the contrast between edges to create the illusion of high detail."; > {
    pass Sharpen {
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_AdaptiveSharpness;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}

#if AFX_SHARPNESS_CLONE_COUNT > 0
AFX_SHARPNESS_SHADOW_CLONE(AFX_SHARPNESS2, "Sharpness 2", "Sharpness 2 Settings", _Filter2, _Sharpness2, _SharpnessFalloff2, _SharpnessOffset2, PS_Sharpness2)
#endif

#if AFX_SHARPNESS_CLONE_COUNT > 1
AFX_SHARPNESS_SHADOW_CLONE(AFX_SHARPNESS3, "Sharpness 3", "Sharpness 3 Settings", _Filter3, _Sharpness3, _SharpnessFalloff3, _SharpnessOffset3, PS_Sharpness3)
#endif

#if AFX_SHARPNESS_CLONE_COUNT > 2
AFX_SHARPNESS_SHADOW_CLONE(AFX_SHARPNESS4, "Sharpness 4", "Sharpness 4 Settings", _Filter4, _Sharpness4, _SharpnessFalloff4, _SharpnessOffset4, PS_Sharpness4)
#endif

#if AFX_SHARPNESS_CLONE_COUNT > 3
AFX_SHARPNESS_SHADOW_CLONE(AFX_SHARPNESS5, "Sharpness 5", "Sharpness 5 Settings", _Filter5, _Sharpness5, _SharpnessFalloff5, _SharpnessOffset5, PS_Sharpness5)
#endif

#if AFX_SHARPNESS_CLONE_COUNT > 4
AFX_SHARPNESS_SHADOW_CLONE(AFX_SHARPNESS6, "Sharpness 6", "Sharpness 6 Settings", _Filter6, _Sharpness6, _SharpnessFalloff6, _SharpnessOffset6, PS_Sharpness6)
#endif

#if AFX_SHARPNESS_CLONE_COUNT > 5
AFX_SHARPNESS_SHADOW_CLONE(AFX_SHARPNESS7, "Sharpness 7", "Sharpness 7 Settings", _Filter7, _Sharpness7, _SharpnessFalloff7, _SharpnessOffset7, PS_Sharpness7)
#endif

#if AFX_SHARPNESS_CLONE_COUNT > 6
AFX_SHARPNESS_SHADOW_CLONE(AFX_SHARPNESS8, "Sharpness 8", "Sharpness 8 Settings", _Filter8, _Sharpness8, _SharpnessFalloff8, _SharpnessOffset8, PS_Sharpness8)
#endif

#if AFX_SHARPNESS_CLONE_COUNT > 7
AFX_SHARPNESS_SHADOW_CLONE(AFX_SHARPNESS9, "Sharpness 9", "Sharpness 9 Settings", _Filter9, _Sharpness9, _SharpnessFalloff9, _SharpnessOffset9, PS_Sharpness9)
#endif

#if AFX_SHARPNESS_CLONE_COUNT > 8
AFX_SHARPNESS_SHADOW_CLONE(AFX_SHARPNESS10, "Sharpness 10", "Sharpness 10 Settings", _Filter10, _Sharpness10, _SharpnessFalloff10, _SharpnessOffset10, PS_Sharpness10)
#endif