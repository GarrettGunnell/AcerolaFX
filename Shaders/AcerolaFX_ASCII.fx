#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

uniform int _KernelSize <
    ui_min = 1; ui_max = 10;
    ui_type = "slider";
    ui_label = "Kernel Size";
    ui_tooltip = "Size of the blur kernel";
> = 2;

uniform float _Sigma <
    ui_min = 0.0; ui_max = 5.0f;
    ui_type = "slider";
    ui_label = "Blur Strength";
    ui_tooltip = "Sigma of the gaussian function (used for Gaussian blur)";
> = 2.0f;

uniform float _SigmaScale <
    ui_min = 0.0; ui_max = 5.0f;
    ui_type = "slider";
    ui_label = "Deviation Scale";
    ui_tooltip = "scale between the two gaussian blurs";
> = 1.6f;

uniform float _Tau <
    ui_min = 0.0; ui_max = 1.1f;
    ui_type = "slider";
    ui_label = "Detail";
> = 1.0f;

uniform float _Threshold <
    ui_min = 0.001; ui_max = 0.1f;
    ui_type = "slider";
    ui_label = "Threshold";
> = 0.005f;

float gaussian(float sigma, float pos) {
    return (1.0f / sqrt(2.0f * AFX_PI * sigma * sigma)) * exp(-(pos * pos) / (2.0f * sigma * sigma));
}

texture2D AFX_LuminanceAsciiTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F; };
storage2D s_Luminance { Texture = AFX_LuminanceAsciiTex; };
sampler2D Luminance { Texture = AFX_LuminanceAsciiTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};

texture2D AFX_AsciiPingTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
storage2D s_AsciiPing { Texture = AFX_AsciiPingTex; };
sampler2D AsciiPing { Texture = AFX_AsciiPingTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};

texture2D AFX_AsciiDogTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F; };
storage2D s_DoG { Texture = AFX_AsciiDogTex; };
sampler2D DoG { Texture = AFX_AsciiDogTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};

sampler2D ASCII { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(ASCII, uv).rgba; }

float PS_Luminance(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return Common::Luminance(saturate(tex2D(Common::AcerolaBuffer, uv).rgb));
}

float4 PS_HorizontalBlur(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

    float2 blur = 0;
    float2 kernelSum = 0;

    for (int x = -_KernelSize; x <= _KernelSize; ++x) {
        float2 luminance = tex2D(Luminance, uv + float2(x, 0) * texelSize).r;
        float2 gauss = float2(gaussian(_Sigma, x), gaussian(_Sigma * _SigmaScale, x));

        blur += luminance * gauss;
        kernelSum += gauss;
    }

    blur /= kernelSum;

    return float4(blur, 0, 0);
}

float PS_VerticalBlurAndDifference(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

    float2 blur = 0;
    float2 kernelSum = 0;

    for (int y = -_KernelSize; y <= _KernelSize; ++y) {
        float2 luminance = tex2D(AsciiPing, uv + float2(0, y) * texelSize).rg;
        float2 gauss = float2(gaussian(_Sigma, y), gaussian(_Sigma * _SigmaScale, y));

        blur += luminance * gauss;
        kernelSum += gauss;
    }

    blur /= kernelSum;

    float D = (blur.x - _Tau * blur.y);

    D = (D >= _Threshold) ? 1 : 0;

    return D;
}

float4 PS_ASCII(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return tex2D(DoG, uv).r;
}

technique AFX_ASCII < ui_label = "ASCII"; > {
    pass {
        RenderTarget = AFX_LuminanceAsciiTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Luminance;
    }
    
    pass {
        RenderTarget = AFX_AsciiPingTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_HorizontalBlur;
    }

    pass {
        RenderTarget = AFX_AsciiDogTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_VerticalBlurAndDifference;
    }
    
    pass {
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_ASCII;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}