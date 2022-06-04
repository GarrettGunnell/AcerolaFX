#pragma once

#include "ReShade.fxh"

uniform bool _EnableFog <
    ui_category = "Fog";
    ui_label = "Enable Fog";
    ui_tooltip = "Enable fog (Fog is mainly for gpose, keep it off for gameplay).";
> = false;

uniform float3 _FogColor <
    ui_category = "Fog";
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Fog Color";
    ui_type = "drag";
    ui_tooltip = "Set fog color";
> = float3(1.0f, 1.0f, 1.0f);

uniform int _FogMode <
    ui_category = "Fog";
    ui_type = "combo";
    ui_label = "Fog factor mode";
    ui_tooltip = "Fog factor formula, Exp2 ramps up much faster than Exp.";
    ui_items = "Exp\0"
               "Exp2\0";
> = 1;

uniform float _Density <
    ui_category = "Fog";
    ui_min = 0.0f; ui_max = 0.01f;
    ui_label = "Fog Density";
    ui_type = "slider";
    ui_tooltip = "Adjust fog density";
> = 0.0f;

uniform float _Offset <
    ui_category = "Fog";
    ui_min = 0.0f; ui_max = 1000.0f;
    ui_label = "Fog Offset";
    ui_type = "slider";
    ui_tooltip = "Offset distance at which fog starts to appear";
> = 0.0f;

uniform float _ZProjection <
    ui_category = "Fog";
    ui_min = 0.0f; ui_max = 4096.0f;
    ui_label = "Camera Z Projection";
    ui_type = "drag";
    ui_tooltip = "Adjust Camera Z Projection (depth of the camera frustum)";
> = 1000.0f;

float4 PS_DistanceFog(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(ReShade::BackBuffer, uv).rgba;
    float UIMask = 1.0f - col.a;

    float depth = ReShade::GetLinearizedDepth(uv);
    float viewDistance = depth * _ZProjection;

    float fogFactor = 0.0f;
    
    if (_FogMode == 0) {
        fogFactor = (_Density / log(2)) * max(0.0f, viewDistance - _Offset);
        fogFactor = exp2(-fogFactor);
    } else {
        fogFactor = (_Density / sqrt(log(2))) * max(0.0f, viewDistance - _Offset);
        fogFactor = exp2(-fogFactor * fogFactor);
    }

    float3 fogOutput = lerp(_FogColor, col.rgb, saturate(fogFactor));

    return float4(lerp(col.rgb, fogOutput, UIMask * _EnableFog), col.a);
}