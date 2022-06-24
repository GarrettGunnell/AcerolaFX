#include "AcerolaFX_Common.fxh"

float4 PS_Start(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return tex2D(ReShade::BackBuffer, uv);
}

technique AcerolaFXStart <ui_tooltip = "(REQUIRED) Put before all AcerolaFX shaders.";> {
    pass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Start;
    }
}