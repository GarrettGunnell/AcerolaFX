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

AFX_SHARPNESS_SHADOW_CLONE(AFX_SHARPNESS2, "Sharpness 2", "Sharpness 2 Settings", _Filter2, _Sharpness2, _SharpnessFalloff2, _SharpnessOffset2, PS_Sharpness2)