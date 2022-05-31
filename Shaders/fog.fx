#include "ReShade.fxh"

uniform float _Density <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Fog Density";
    ui_type = "drag";
    ui_tooltip = "Adjust fog density";
> = 0.0f;

uniform float _Offset <
    ui_min = 0.0f; ui_max = 1000.0f;
    ui_label = "Fog Offset";
    ui_type = "drag";
    ui_tooltip = "Offset distance at which fog starts to appear";
> = 0.0f;

float4 PS_DistanceFog(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(ReShade::BackBuffer, uv).rgba;
    float UIMask = 1.0f - col.a;

    float depth = ReShade::GetLinearizedDepth(uv);
    float viewDistance = depth * 1000.0f;

    float fogFactor = (_Density / sqrt(log(2))) * max(0.0f, viewDistance - _Offset);
    fogFactor = exp2(-fogFactor * fogFactor);

    float3 fogOutput = lerp(float3(1.0f, 1.0f, 1.0f), col.rgb, saturate(fogFactor));

    return float4(lerp(col.rgb, fogOutput, UIMask), col.a);
}

technique Fog {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_DistanceFog;
    }
}