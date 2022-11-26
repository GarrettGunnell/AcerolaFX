#include "AcerolaFX_Common.fxh"

uniform float _SigmaE <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Difference Of Gaussians Deviation";
    ui_type = "drag";
    ui_tooltip = "Adjust the deviation of the color buffer gaussian blurring.";
> = 2.0f;

uniform float _K <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Deviation Scale";
    ui_type = "drag";
    ui_tooltip = "Adjust scale between gaussian blur passes for the color buffer.";
> = 1.6f;

uniform float _P <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Sharpness";
    ui_type = "drag";
    ui_tooltip = "Adjust sharpness of the two gaussian blurs to bring out edge lines.";
> = 1.0f;

uniform float _Threshold <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "White Point";
    ui_type = "drag";
    ui_tooltip = "Adjust value at which difference is clamped to white.";
> = 0.1f;

uniform float _Phi <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Soft Threshold";
    ui_type = "drag";
    ui_tooltip = "Adjust curve of hyperbolic tangent.";
> = 1.0f;

texture2D AFX_DifferenceOfGaussiansTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D DifferenceOfGaussians { Texture = AFX_DifferenceOfGaussiansTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(DifferenceOfGaussians, uv).rgba; }

float gaussian(float sigma, float pos) {
    return (1.0f / sqrt(2.0f * AFX_PI * sigma * sigma)) * exp(-(pos * pos) / (2.0f * sigma * sigma));
}

float4 PS_HorizontalBlur(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    int kernelRadius = _SigmaE * 2 > 1 ? _SigmaE * 2 : 1;

    float2 col = 0;
    float2 kernelSum = 0.0f;

    for (int x = -kernelRadius; x <= kernelRadius; ++x) {
        float c = Common::Luminance(tex2D(Common::AcerolaBuffer, uv + float2(x, 0) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).rgb);
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
        float c = Common::Luminance(tex2D(Common::AcerolaBuffer, uv + float2(0, y) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).rgb);
        float gauss1 = gaussian(_SigmaE, y);
        float gauss2 = gaussian(_SigmaE * _K, y);

        col.r += c * gauss1;
        kernelSum.r += gauss1;
        
        col.g += c * gauss2;
        kernelSum.g += gauss2;
    }

    float D = (1 + _P) * col.r - _P * col.g;

    float4 output = 0.0f;

    output = (D >= _Threshold) ? 1 : 1 + tanh(_Phi * (D - _Threshold));

    return saturate(output);
}

technique AFX_DifferenceOfGaussians < ui_label = "Difference Of Gaussians"; > {
    pass {
        RenderTarget = AFX_DifferenceOfGaussiansTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_HorizontalBlur;
    }

    pass {
        RenderTarget = AFX_DifferenceOfGaussiansTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_VerticalBlur;
    }


    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}