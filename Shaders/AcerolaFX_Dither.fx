#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"
#include "Includes/AcerolaFX_Downscales.fxh"

#ifndef AFX_DITHER_DOWNSCALE
    #define AFX_DITHER_DOWNSCALE 1
#endif

#if AFX_DITHER_DOWNSCALE == 1
 #define AFX_DitherDownscaleTex DownScale::HalfTex
#elif AFX_DITHER_DOWNSCALE == 2
 #define AFX_DitherDownscaleTex DownScale::QuarterTex
#elif AFX_DITHER_DOWNSCALE == 3
 #define AFX_DitherDownscaleTex DownScale::EighthTex
#elif AFX_DITHER_DOWNSCALE == 4
 #define AFX_DitherDownscaleTex DownScale::SixteenthTex
#elif AFX_DITHER_DOWNSCALE == 5
 #define AFX_DitherDownscaleTex DownScale::ThirtySecondthTex
#elif AFX_DITHER_DOWNSCALE == 6
 #define AFX_DitherDownscaleTex DownScale::SixtyFourthTex
#elif AFX_DITHER_DOWNSCALE == 7
 #define AFX_DitherDownscaleTex DownScale::OneTwentyEighthTex
#elif AFX_DITHER_DOWNSCALE == 8
 #define AFX_DitherDownscaleTex DownScale::TwoFiftySixthTex
#else
 #define AFX_DitherDownscaleTex AFXTemp1::AFX_RenderTex1
#endif

uniform uint _NoiseMode <
    ui_type = "combo";
    ui_label = "Noise Mode";
    ui_tooltip = "What noise to offset with";
    ui_items = "Bayer\0"
               "Blue\0";
> = 0;

uniform int _BayerLevel <
    ui_min = 0; ui_max = 2;
    ui_label = "Bayer Level";
    ui_type = "slider";
    ui_tooltip = "Choose which bayer level to dither with.";
> = 1;

uniform int _BlueNoiseTexture <
    ui_min = 0; ui_max = 7;
    ui_label = "Blue Noise Texture";
    ui_type = "slider";
    ui_tooltip = "Adjusts allowed number of red colors.";
> = 0;

uniform bool _AnimateNoise <
    ui_spacing = 5.0f;
    ui_label = "Animate Noise";
    ui_tooltip = "Pick random texture every frame.";
> = false;
uniform float timer < source = "timer"; >;

uniform float _AnimationSpeed <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Animation Speed";
    ui_type = "drag";
    ui_tooltip = "Control how fast the animation is.";
> = 1.0f;

uniform float _Spread <
    ui_spacing = 5.0f;
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Spread";
    ui_type = "drag";
    ui_tooltip = "Controls how much the dither noise spreads the color value across the reduced color palette.";
> = 0.5f;

uniform uint _ColorSpace <
    ui_type = "combo";
    ui_label = "Color Space";
    ui_tooltip = "What space to quantize in";
    ui_items = "RGB\0"
               "HSL\0";
> = 0;

uniform int _RedColorCount <
    ui_min = 2; ui_max = 16;
    ui_label = "Channel One Count";
    ui_type = "slider";
> = 2;

uniform int _GreenColorCount <
    ui_min = 2; ui_max = 16;
    ui_label = "Channel Two Count";
    ui_type = "slider";
> = 2;

uniform int _BlueColorCount <
    ui_min = 2; ui_max = 16;
    ui_label = "Channel Three Count";
    ui_type = "slider";
> = 2;

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


texture2D AFX_BlueNoiseTex1 < source = "bluenoise1.png"; > { Width = 256; Height = 256; Format = R8; }; 
sampler2D BlueNoise1 { Texture = AFX_BlueNoiseTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; AddressU = REPEAT; AddressV = REPEAT; };
texture2D AFX_BlueNoiseTex2 < source = "bluenoise2.png"; > { Width = 256; Height = 256; Format = R8; }; 
sampler2D BlueNoise2 { Texture = AFX_BlueNoiseTex2; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; AddressU = REPEAT; AddressV = REPEAT; };
texture2D AFX_BlueNoiseTex3 < source = "bluenoise3.png"; > { Width = 256; Height = 256; Format = R8; }; 
sampler2D BlueNoise3 { Texture = AFX_BlueNoiseTex3; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; AddressU = REPEAT; AddressV = REPEAT; };
texture2D AFX_BlueNoiseTex4 < source = "bluenoise4.png"; > { Width = 256; Height = 256; Format = R8; }; 
sampler2D BlueNoise4 { Texture = AFX_BlueNoiseTex4; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; AddressU = REPEAT; AddressV = REPEAT; };
texture2D AFX_BlueNoiseTex5 < source = "bluenoise5.png"; > { Width = 256; Height = 256; Format = R8; }; 
sampler2D BlueNoise5 { Texture = AFX_BlueNoiseTex5; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; AddressU = REPEAT; AddressV = REPEAT; };
texture2D AFX_BlueNoiseTex6 < source = "bluenoise6.png"; > { Width = 256; Height = 256; Format = R8; }; 
sampler2D BlueNoise6 { Texture = AFX_BlueNoiseTex6; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; AddressU = REPEAT; AddressV = REPEAT; };
texture2D AFX_BlueNoiseTex7 < source = "bluenoise7.png"; > { Width = 256; Height = 256; Format = R8; }; 
sampler2D BlueNoise7 { Texture = AFX_BlueNoiseTex7; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; AddressU = REPEAT; AddressV = REPEAT; };
texture2D AFX_BlueNoiseTex8 < source = "bluenoise8.png"; > { Width = 256; Height = 256; Format = R8; }; 
sampler2D BlueNoise8 { Texture = AFX_BlueNoiseTex8; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; AddressU = REPEAT; AddressV = REPEAT; };


sampler2D Dither { Texture = AFX_DitherDownscaleTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };

float GetBlueNoise(int textureID, float2 uv) {
    if (textureID == 0) return tex2D(BlueNoise1, uv).r;
    if (textureID == 1) return tex2D(BlueNoise2, uv).r;
    if (textureID == 2) return tex2D(BlueNoise3, uv).r;
    if (textureID == 3) return tex2D(BlueNoise4, uv).r;
    if (textureID == 4) return tex2D(BlueNoise5, uv).r;
    if (textureID == 5) return tex2D(BlueNoise6, uv).r;
    if (textureID == 6) return tex2D(BlueNoise7, uv).r;
    if (textureID == 7) return tex2D(BlueNoise8, uv).r;

    return 0.0f;
}

// https://www.chilliant.com/rgb2hsv.html
float3 RGBtoHCV(in float3 RGB) {
    float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0/3.0) : float4(RGB.gb, 0.0, -1.0/3.0);
    float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6 * C + 1e-10) + Q.z);

    return float3(H, C, Q.x);
}

float3 RGBtoHSL(in float3 RGB) {
    float3 HCV = RGBtoHCV(RGB);
    float L = HCV.z - HCV.y * 0.5;
    float S = HCV.y / (1 - abs(L * 2 - 1) + 1e-10);

    return float3(HCV.x, S, L);
}

float3 HUEtoRGB(in float H) {
    float R = abs(H * 6 - 3) - 1;
    float G = 2 - abs(H * 6 - 2);
    float B = 2 - abs(H * 6 - 4);
    
    return saturate(float3(R,G,B));
}

float3 HSLtoRGB(in float3 HSL) {
    float3 RGB = HUEtoRGB(HSL.x);
    float C = (1 - abs(2 * HSL.z - 1)) * HSL.y;

    return (RGB - 0.5) * C + HSL.z;
}

float4 PS_Downscale(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { 
    float4 col = tex2D(Common::AcerolaBuffer, uv);
    float4 UI = tex2D(ReShade::BackBuffer, uv);
    return lerp(col, UI, UI.a);
}

float4 PS_Dither(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { 
    float4 col = tex2D(Dither, uv);
    float4 UI = tex2D(ReShade::BackBuffer, uv);

    int pow2 = exp2(AFX_DITHER_DOWNSCALE);
    int width = BUFFER_WIDTH / pow2;
    int height = BUFFER_HEIGHT / pow2;

    int x = uv.x * width;
    int y = uv.y * height;

    float bayerValues[3] = { 0, 0, 0 };
    bayerValues[0] = GetBayer2(x, y);
    bayerValues[1] = GetBayer4(x, y);
    bayerValues[2] = GetBayer8(x, y);

    float noise = 0;

    int animatedBayerIndex = floor(timer / (1000 * (1.001f - _AnimationSpeed))) % 3;
    int animatedBlueIndex = floor(timer / (1000 * (1.001f - _AnimationSpeed))) % 7;
    
    if (_NoiseMode == 0) noise = bayerValues[_AnimateNoise ? animatedBayerIndex : _BayerLevel];
    else if (_NoiseMode == 1) noise = GetBlueNoise(_AnimateNoise ? animatedBlueIndex : _BlueNoiseTexture, position.xy / (256 * pow(2, AFX_DITHER_DOWNSCALE)));

    float4 output = saturate(col) + _Spread * noise;

    if (_ColorSpace == 1) {
        output.rgb = RGBtoHSL(output.rgb - _Spread * noise) + _Spread * noise;
    }

    output.r = floor((_RedColorCount - 1.0f) * output.r + 0.5) / (_RedColorCount - 1.0f);
    output.g = floor((_GreenColorCount - 1.0f) * output.g + 0.5) / (_GreenColorCount - 1.0f);
    output.b = floor((_BlueColorCount - 1.0f) * output.b + 0.5) / (_BlueColorCount - 1.0f);

    if (_ColorSpace == 1) {
        output.gb = saturate(output.gb);
        output.rgb = HSLtoRGB(output.rgb);
    }

   return float4(lerp(saturate(output.rgb), UI.rgb, UI.a * _MaskUI), UI.a);
}

technique AFX_Dither  <ui_label = "Dither"; ui_tooltip = "(LDR) Reduces the color palette of the image with ordered dithering."; >  {
    pass {
        RenderTarget = AFX_DitherDownscaleTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Downscale;
    }

    pass End {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Dither;
    }
}