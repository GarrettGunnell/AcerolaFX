#include "AcerolaFX_Common.fxh"

#ifndef AFX_DOWNSCALE_FACTOR
    #define AFX_DOWNSCALE_FACTOR 1
#endif

uniform float _Spread <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Spread";
    ui_type = "drag";
    ui_tooltip = "Controls how much the dither noise spreads the color value across the reduced color palette.";
> = 0.5f;

uniform int _RedColorCount <
    ui_min = 2; ui_max = 16;
    ui_label = "Red Color Count";
    ui_type = "slider";
    ui_tooltip = "Adjusts allowed number of red colors.";
> = 2;

uniform int _GreenColorCount <
    ui_min = 2; ui_max = 16;
    ui_label = "Green Color Count";
    ui_type = "slider";
    ui_tooltip = "Adjusts allowed number of green colors.";
> = 2;

uniform int _BlueColorCount <
    ui_min = 2; ui_max = 16;
    ui_label = "Blue Color Count";
    ui_type = "slider";
    ui_tooltip = "Adjusts allowed number of blue colors.";
> = 2;

uniform int _BayerLevel <
    ui_min = 0; ui_max = 2;
    ui_label = "Bayer Level";
    ui_type = "slider";
    ui_tooltip = "Choose which bayer level to dither with.";
> = 1;

uniform bool _MaskUI <
    ui_label = "Mask UI";
    ui_tooltip = "Mask UI from dithering.";
> = true;

static const int bayer2[2 * 2] = {
    0, 2,
    3, 1
};

static const int bayer4[4 * 4] = {
    0, 8, 2, 10,
    12, 4, 14, 6,
    3, 11, 1, 9,
    15, 7, 13, 5
};

static const int bayer8[8 * 8] = {
    0, 32, 8, 40, 2, 34, 10, 42,
    48, 16, 56, 24, 50, 18, 58, 26,  
    12, 44,  4, 36, 14, 46,  6, 38, 
    60, 28, 52, 20, 62, 30, 54, 22,  
    3, 35, 11, 43,  1, 33,  9, 41,  
    51, 19, 59, 27, 49, 17, 57, 25, 
    15, 47,  7, 39, 13, 45,  5, 37, 
    63, 31, 55, 23, 61, 29, 53, 21
};

float GetBayer2(int x, int y) {
    return float(bayer2[(x % uint(2)) + (y % uint(2)) * 2]) * (1.0f / 4.0f) - 0.5f;
}

float GetBayer4(int x, int y) {
    return float(bayer4[(x % uint(4)) + (y % uint(4)) * 4]) * (1.0f / 16.0f) - 0.5f;
}

float GetBayer8(int x, int y) {
    return float(bayer8[(x % uint(8)) + (y % uint(8)) * 8]) * (1.0f / 64.0f) - 0.5f;
}

#define PWRTWO(EXP) (1 << (EXP))
#define AFX_WIDTH BUFFER_WIDTH / PWRTWO(AFX_DOWNSCALE_FACTOR)
#define AFX_HEIGHT BUFFER_HEIGHT / PWRTWO(AFX_DOWNSCALE_FACTOR)

texture2D DitherTex < pooled = true; > { Width = AFX_WIDTH; Height = AFX_HEIGHT; Format = RGBA16F; }; 
sampler2D Dither { Texture = DitherTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_Downscale(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { 
    float4 col = tex2D(Common::AcerolaBuffer, uv);
    float4 UI = tex2D(ReShade::BackBuffer, uv);
    return lerp(col, UI, UI.a);
}

float4 PS_Dither(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { 
    float4 col = tex2D(Dither, uv);
    float4 UI = tex2D(ReShade::BackBuffer, uv);

    int x = uv.x * AFX_WIDTH;
    int y = uv.y * AFX_HEIGHT;

    float bayerValues[3] = { 0, 0, 0 };
    bayerValues[0] = GetBayer2(x, y);
    bayerValues[1] = GetBayer4(x, y);
    bayerValues[2] = GetBayer8(x, y);

    float4 output = saturate(col) + _Spread * bayerValues[_BayerLevel];

    output.r = floor((_RedColorCount - 1.0f) * output.r + 0.5) / (_RedColorCount - 1.0f);
    output.g = floor((_GreenColorCount - 1.0f) * output.g + 0.5) / (_GreenColorCount - 1.0f);
    output.b = floor((_BlueColorCount - 1.0f) * output.b + 0.5) / (_BlueColorCount - 1.0f);

   return float4(lerp(output.rgb, UI.rgb, UI.a * _MaskUI), UI.a);
}

technique AFX_Dither  <ui_label = "Dither"; ui_tooltip = "(LDR) Reduces the color palette of the image with ordered dithering."; >  {
    pass {
        RenderTarget = DitherTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Downscale;
    }

    pass End {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Dither;
    }
}