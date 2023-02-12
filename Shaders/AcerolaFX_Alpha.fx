#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

uniform float _Alpha <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Alpha";
    ui_type = "slider";
    ui_tooltip = "Value to set global alpha to.";
> = 0.0f;

sampler2D Alpha { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Alpha, uv).rgba; }

float4 PS_Alpha(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return float4(tex2D(ReShade::BackBuffer, uv).rgb, _Alpha);
}

technique AFX_Alpha < ui_label = "Alpha"; ui_tooltip = "Sets the global alpha channel in the back buffer to get around ui masking."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_Alpha;
    }
}