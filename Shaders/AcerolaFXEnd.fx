#include "ReShade.fxh"
#include "Common.fxh"

float4 PS_End(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return tex2D(Common::AcerolaBuffer, uv).rgba;
}

technique AcerolaFXEnd <ui_tooltip = "(REQUIRED) Put after any Acerola shaders.";> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_End;
    }
}