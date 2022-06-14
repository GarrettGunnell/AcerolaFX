#include "ReShade.fxh"
#include "Common.fxh"

float4 PS_End(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 originalCol = tex2D(ReShade::BackBuffer, uv);

    return float4(lerp(tex2D(Common::AcerolaBuffer, uv).rgb, originalCol.rgb, originalCol.a), originalCol.a);
}

technique AcerolaFXEnd <ui_tooltip = "(REQUIRED) Put after any Acerola shaders.";> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_End;
    }
}