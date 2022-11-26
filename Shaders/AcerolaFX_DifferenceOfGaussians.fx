#include "AcerolaFX_Common.fxh"

uniform float _SigmaE <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Difference Of Gaussians Deviation";
    ui_type = "slider";
    ui_tooltip = "Adjust the deviation of the color buffer gaussian blurring.";
> = 2.0f;

uniform float _K <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Deviation Scale";
    ui_type = "drag";
    ui_tooltip = "Adjust scale between gaussian blur passes for the color buffer.";
> = 1.6f;

uniform float _P <
    ui_min = 0.0f; ui_max = 100.0f;
    ui_label = "Sharpness";
    ui_type = "slider";
    ui_tooltip = "Adjust sharpness of the two gaussian blurs to bring out edge lines.";
> = 1.0f;

uniform int _Thresholding <
    ui_type = "combo";
    ui_label = "Threshold Mode";
    ui_items = "No Threshold\0"
               "Tanh\0"
               "Quantization\0"
               "Soft Quantization\0";
> = 0;

uniform int _Thresholds <
    ui_min = 1; ui_max = 16;
    ui_label = "Quantizer Step";
    ui_type = "slider";
    ui_tooltip = "Adjust number of allowed difference values.";
> = 1;

uniform float _Threshold <
    ui_min = 0.0f; ui_max = 100.0f;
    ui_label = "White Point";
    ui_type = "slider";
    ui_tooltip = "Adjust value at which difference is clamped to white.";
> = 20.0f;

uniform float _Phi <
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Soft Threshold";
    ui_type = "slider";
    ui_tooltip = "Adjust curve of hyperbolic tangent.";
> = 1.0f;

uniform float _TermStrength <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Term Strength";
    ui_type = "drag";
    ui_tooltip = "Adjust scale of difference of gaussians output.";
> = 1;

uniform int _BlendMode <
    ui_type = "combo";
    ui_label = "Blend Mode";
    ui_items = "No Blend\0"
               "Interpolate\0"
               "Two Point Interpolate\0";
> = 0;

uniform float3 _MinColor <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Min Color";
    ui_type = "color";
    ui_tooltip = "Set minimum color.";
> = 0.0f;

uniform float3 _MaxColor <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Max Color";
    ui_type = "color";
    ui_tooltip = "Set maximum color.";
> = 1.0f;

uniform float _BlendStrength <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Blend Strength";
    ui_type = "drag";
    ui_tooltip = "Adjust strength of color blending.";
> = 1;

texture2D AFX_HorizontalBlurTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D HorizontalBlur { Texture = AFX_HorizontalBlurTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
texture2D AFX_DifferenceOfGaussiansTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D DifferenceOfGaussians { Texture = AFX_DifferenceOfGaussiansTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
texture2D AFX_LabTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D Lab { Texture = AFX_LabTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
texture2D AFX_GaussiansBlendedTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler2D GaussiansBlended { Texture = AFX_GaussiansBlendedTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(GaussiansBlended, uv).rgba; }

float gaussian(float sigma, float pos) {
    return (1.0f / sqrt(2.0f * AFX_PI * sigma * sigma)) * exp(-(pos * pos) / (2.0f * sigma * sigma));
}

float4 PS_RGBtoLAB(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return float4(Common::rgb2lab(tex2D(Common::AcerolaBuffer, uv).rgb), 1.0f);
}

float4 PS_HorizontalBlur(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    int kernelRadius = _SigmaE * 2 > 1 ? _SigmaE * 2 : 1;

    float2 col = 0;
    float2 kernelSum = 0.0f;

    for (int x = -kernelRadius; x <= kernelRadius; ++x) {
        float c = tex2D(Lab, uv + float2(x, 0) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).r;
        float gauss1 = gaussian(_SigmaE, x);
        float gauss2 = gaussian(_SigmaE * _K, x);

        col.r += c * gauss1;
        kernelSum.r += gauss1;

        col.g += c * gauss2;
        kernelSum.g += gauss2;
    }

    return float4(col / kernelSum, 1.0f, 1.0f);
}

float4 PS_VerticalBlur(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    int kernelRadius = _SigmaE * 2 > 1 ? _SigmaE * 2 : 1;

    float2 col = 0;
    float2 kernelSum = 0.0f;

    for (int y = -kernelRadius; y <= kernelRadius; ++y) {
        float c = tex2D(HorizontalBlur, uv + float2(0, y) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).r;
        float gauss1 = gaussian(_SigmaE, y);
        float gauss2 = gaussian(_SigmaE * _K, y);

        col.r += c * gauss1;
        kernelSum.r += gauss1;
        
        col.g += c * gauss2;
        kernelSum.g += gauss2;
    }

    float D = (1 + _P) * (col.r * 100.0f) - _P * (col.g * 100.0f);

    float4 output = D;
    if (_Thresholding == 0)
        output /= 100.0f;
    if (_Thresholding == 1)
        output = (D >= _Threshold) ? 1 : 1 + tanh(_Phi * (D - _Threshold));
    if (_Thresholding == 2) {
        float a = 1.0f / _Thresholds;
        float b = _Threshold / 100.0f;
        float x = D / 100.0f;

        output = (x >= b) ? 1 : a * floor((pow(abs(x), _Phi) - (a * b / 2.0f)) / (a * b) + 0.5f);
    }
    if (_Thresholding == 3) {
        float x = D / 100.0f;
        float qn = floor(x * float(_Thresholds) + 0.5f) / float(_Thresholds);
        float qs = smoothstep(-2.0, 2.0, _Phi * (x - qn) * 10.0f) - 0.5f;
        
        output = qn + qs / float(_Thresholds);
    }

    return saturate(output);
}

float4 PS_ColorBlend(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(Common::AcerolaBuffer, uv);
    float D = tex2D(DifferenceOfGaussians, uv).r * _TermStrength;

    float4 output = 1.0f;
    if (_BlendMode == 0)
        output.rgb = lerp(_MinColor, _MaxColor, D);
    if (_BlendMode == 1)
        output.rgb = lerp(_MinColor, col.rgb, D);
    if (_BlendMode == 2) {
        if (D.r < 0.5f)
            output.rgb = lerp(_MinColor, col.rgb, D * 2.0f);
        else
            output.rgb = lerp(col.rgb, _MaxColor, (D - 0.5f) * 2.0f);
    }

    return saturate(lerp(col, output, _BlendStrength));
}

technique AFX_DifferenceOfGaussians < ui_label = "Difference Of Gaussians"; > {
    pass {
        RenderTarget = AFX_LabTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_RGBtoLAB;
    }

    pass {
        RenderTarget = AFX_HorizontalBlurTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_HorizontalBlur;
    }

    pass {
        RenderTarget = AFX_DifferenceOfGaussiansTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_VerticalBlur;
    }

    pass {
        RenderTarget = AFX_GaussiansBlendedTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_ColorBlend;
    }


    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}