#include "ReShadeUI.fxh"

uniform float3 _Brightness <
    ui_min = -1.0; ui_max = 1.0;
    ui_label = "Brightness";
    ui_tooltip = "Adjust brightness";
> = float3(0.0, 0.0, 0.0);

#include "ReShade.fxh"

float3 ps(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(ReShade::BackBuffer, uv).rgba;

    float UIMask = 1.0f - col.a;

    col.rgb += _Brightness * UIMask;

    return saturate(col.rgb);
}

technique AdjustBrightness {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = ps;
    }
}