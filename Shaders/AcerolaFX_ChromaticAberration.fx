#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

uniform bool _DebugMask <
    ui_label = "Debug Mask";
    ui_tooltip = "View the chromatic aberration intensity mask.";
> = false;

uniform float2 _FocalOffset <
    ui_min = -1.0f; ui_max = 1.0f;
    ui_label = "Focal Point Offset";
    ui_type = "drag";
    ui_tooltip = "Positional offset of the focal point from the center of the screen.";
> = 0.0f;

uniform float2 _Radius <
    ui_min = 0f; ui_max = 5.0f;
    ui_label = "Focus Radius";
    ui_type = "drag";
    ui_tooltip = "Adjust radius of focus from center of image.";
> = 1.0f;

uniform float _Hardness <
    ui_min = 0f; ui_max = 10.0f;
    ui_label = "Hardness";
    ui_type = "drag";
    ui_tooltip = "Adjust how smooth the intensity change is from the center of the screen.";
> = 1.0f;

uniform float _Intensity <
    ui_min = 0f; ui_max = 10.0f;
    ui_label = "Intensity";
    ui_type = "drag";
    ui_tooltip = "Adjust how intense the color offset is.";
> = 1.0f;

uniform float3 _ColorOffsets <
    ui_min = -1.0f; ui_max = 1.0f;
    ui_label = "Color Offsets";
    ui_type = "drag";
    ui_tooltip = "Adjust how much each color channel should be offset.";
> = 0.0f;

sampler2D ChromaticAberration { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(ChromaticAberration, uv).rgba; }

float4 PS_ChromaticAberration(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

    float2 pos = uv - 0.5f;
    pos -= _FocalOffset;
    pos *= _Radius;
    pos += 0.5f;

    float2 direction = pos - 0.5f;
    float intensity = saturate(pow(abs(length(pos - 0.5f)), _Hardness));
    intensity *= _Intensity;
    if (_DebugMask)
        return intensity;

    float4 col = 1.0f;
    float2 redUV = uv + (direction * _ColorOffsets.r) * intensity;
    float2 blueUV = uv + (direction * _ColorOffsets.b) * intensity;
    float2 greenUV = uv + (direction * _ColorOffsets.g) * intensity;

    col.r = tex2D(Common::AcerolaBufferLinear, redUV).r;
    col.g = tex2D(Common::AcerolaBufferLinear, blueUV).g;
    col.b = tex2D(Common::AcerolaBufferLinear, greenUV).b;

    return col;
}

technique AFX_ChromaticAberration < ui_label = "Chromatic Aberration"; ui_tooltip = "Simulate chromatic aberration by shifting color channel values around."; > {
    pass {
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_ChromaticAberration;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}