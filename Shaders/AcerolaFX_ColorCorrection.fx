#include "AcerolaFX_Common.fxh"

uniform bool _HDR <
    ui_label = "HDR";
    ui_tooltip = "Enable HDR (Color values can exceed 1).";
> = true;

uniform float _Exposure <
    ui_category = "Color Correct";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Exposure";
    ui_type = "drag";
    ui_tooltip = "Adjust camera exposure.";
> = 1.0f;

uniform float _Temperature <
    ui_category = "Color Correct";
    ui_category_closed = true;
    ui_min = -1.0f; ui_max = 1.0f;
    ui_label = "Temperature";
    ui_type = "drag";
    ui_tooltip = "Adjust white balancing temperature.";
> = 0.0f;

uniform float _Tint <
    ui_category = "Color Correct";
    ui_category_closed = true;
    ui_min = -1.0f; ui_max = 1.0f;
    ui_label = "Tint";
    ui_type = "drag";
    ui_tooltip = "Adjust white balance color tint.";
> = 0.0f;

uniform float3 _Contrast <
    ui_category = "Color Correct";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Contrast";
    ui_type = "drag";
    ui_tooltip = "Adjust contrast.";
> = 1.0f;

uniform float3 _LinearMidPoint <
    ui_category = "Color Correct";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Linear Mid Point";
    ui_type = "drag";
    ui_tooltip = "Adjust the midpoint value between black and fully saturated for contrast.";
> = 0.5f;

uniform float3 _Brightness <
    ui_category = "Color Correct";
    ui_category_closed = true;
    ui_min = -5.0f; ui_max = 5.0f;
    ui_label = "Brightness";
    ui_type = "drag";
    ui_tooltip = "Adjust brightness of each color channel.";
> = float3(0.0, 0.0, 0.0);

uniform float3 _ColorFilter <
    ui_category = "Color Correct";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Color Filter";
    ui_type = "color";
    ui_tooltip = "Set color filter (white for no change).";
> = float3(1.0, 1.0, 1.0);

uniform float _FilterIntensity <
    ui_category = "Color Correct";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Color Filter Intensity (HDR)";
    ui_type = "drag";
    ui_tooltip = "Adjust the intensity of the color filter.";
> = 1.0f;

uniform float3 _Saturation <
    ui_category = "Color Correct";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Saturation";
    ui_type = "drag";
    ui_tooltip = "Adjust saturation.";
> = 1.0f;

texture2D ColorCorrectionTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D ColorCorrection { Texture = ColorCorrectionTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(ColorCorrection, uv).rgba; }

float4 PS_ColorCorrect(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(Common::AcerolaBuffer, uv).rgba;
    float UIMask = 1.0f - col.a;

    float3 output = col.rgb;
    if (!_HDR)
        output = saturate(output);

    output *= _Exposure;
    if (!_HDR)
        output = saturate(output);

    output = Common::WhiteBalance(output.rgb, _Temperature, _Tint);
    output = _HDR ? max(0.0f, output) : saturate(output);

    output = _Contrast * (output - _LinearMidPoint) + _LinearMidPoint + _Brightness;
    output = _HDR ? max(0.0f, output) : saturate(output);

    output *= (_ColorFilter * _FilterIntensity);
    if (!_HDR)
        output = saturate(output);
    
    output = lerp(Common::Luminance(output), output, _Saturation);
    if (!_HDR)
        output = saturate(output);

    return float4(output, col.a);
}

technique AFX_ColorCorrection  <ui_label = "Color Correct"; ui_tooltip = "(HDR/LDR) A suite of color correction effects."; >  {
    pass ColorCorrect {
        RenderTarget = ColorCorrectionTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_ColorCorrect;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}