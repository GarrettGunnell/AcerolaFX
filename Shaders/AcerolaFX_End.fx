#include "AcerolaFX_Common.fxh"

uniform bool _MaskUI <
    ui_label = "Mask UI";
    ui_tooltip = "Mask UI (disable if dithering/crt effects are enabled).";
> = true;

float4 PS_End(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 originalCol = tex2D(ReShade::BackBuffer, uv);

    return float4(lerp(tex2D(Common::AcerolaBuffer, uv).rgb, originalCol.rgb, originalCol.a * _MaskUI), originalCol.a);
}

technique AcerolaFXEnd <ui_tooltip = "(REQUIRED) Put after all AcerolaFX shaders.";> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_End;
    }
}