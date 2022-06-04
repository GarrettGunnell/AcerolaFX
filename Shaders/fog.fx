#include "ReShade.fxh"
#include "Common.fxh"

uniform float3 _FogColor <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Fog Color";
    ui_type = "drag";
    ui_tooltip = "Set fog color";
> = float3(1.0f, 1.0f, 1.0f);

uniform int _FogMode <
    ui_type = "combo";
    ui_label = "Fog factor mode";
    ui_items = "Exp\0"
                "Exp2\0";
> = 1;

uniform float _Density <
    ui_min = 0.0f; ui_max = 0.01f;
    ui_label = "Fog Density";
    ui_type = "slider";
    ui_tooltip = "Adjust fog density";
> = 0.0f;

uniform float _Offset <
    ui_min = 0.0f; ui_max = 1000.0f;
    ui_label = "Fog Offset";
    ui_type = "slider";
    ui_tooltip = "Offset distance at which fog starts to appear";
> = 0.0f;

uniform float _ZProjection <
    ui_category = "Advanced settings";
    ui_min = 0.0f; ui_max = 4096.0f;
    ui_label = "Camera Z Projection";
    ui_type = "slider";
    ui_tooltip = "Adjust Camera Z Projection (depth of the camera frustum)";
> = 1000.0f;

texture2D FogTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D Fog { Texture = FogTex; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Fog, uv).rgba; }

float4 PS_DistanceFog(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(Common::AcerolaBuffer, uv).rgba;
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

    return float4(lerp(col.rgb, fogOutput, UIMask), col.a);
}

technique Fog {
    pass {
        RenderTarget = FogTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_DistanceFog;
    }

    pass End {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}