#include "ReShade.fxh"

uniform float _Gamma <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Gamma";
    ui_type = "drag";
    ui_tooltip = "Adjust gamma correction";
> = 1.0f;


float4 PS_Gamma(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(ReShade::BackBuffer, uv).rgba;
    float UIMask = 1.0f - col.a;

    float3 output = pow(abs(col.rgb), _Gamma);

    return float4(lerp(col.rgb, output, UIMask), col.a);
}

technique Gamma {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_Gamma;
    }
}