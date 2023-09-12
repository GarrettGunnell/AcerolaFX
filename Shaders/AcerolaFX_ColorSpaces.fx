#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

uniform uint _ColorSpace <
    ui_type = "combo";
    ui_label = "Color Space";
    ui_tooltip = "What color space to use for adjustments (probably OKLCH).";
    ui_items = "HSL\0"
               "HSV\0"
               "HCY\0"
               "OKLAB\0"
               "OKLCH\0";
> = 0;

uniform float _HAAdd <
    ui_label = "H/A Add";
    ui_type = "drag";
    ui_tooltip = "Additively adjust the hue or A coord of LAB.";
> = 0.0f;

uniform float _HAMultiply <
    ui_label = "H/A Multiply";
    ui_type = "drag";
    ui_tooltip = "Scale the hue or A coord of LAB.";
> = 1.0f;

uniform float _SCBAdd <
    ui_label = "S/C/B Add";
    ui_type = "drag";
    ui_type = "Additively adjust the saturation, chroma, or B coord of LAB.";
> = 0.0f;

uniform float _SCBMultiply <
    ui_label = "S/C/B Multiply";
    ui_type = "drag";
    ui_tooltip = "Scale the saturation, chroma, or B coord of LAB.";
> = 1.0f;

uniform float _LVYAdd <
    ui_label = "L/V/Y Add";
    ui_type = "drag";
    ui_type = "Additively adjust the brightness of the image (um ackshually it's the luminance/lightness/vibrance/white point).";
> = 0.0f;

uniform float _LVYMultiply <
    ui_label = "L/V/Y Multiply";
    ui_type = "drag";
    ui_tooltip = "Scale the brightness of the image (um ackshually it's the luminance/lightness/vibrance/white point).";
> = 1.0f;

sampler2D ColorSpaceAdjust { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(ColorSpaceAdjust, uv).rgba; }

float3 HUEtoRGB(in float H) {
    float R = abs(H * 6 - 3) - 1;
    float G = 2 - abs(H * 6 - 2);
    float B = 2 - abs(H * 6 - 4);
    
    return saturate(float3(R,G,B));
}

// OKLAB matrices
static const float3x3 lrgb2cone = float3x3(
    0.412165612, 0.211859107, 0.0883097947,
    0.536275208, 0.6807189584, 0.2818474174,
    0.0514575653, 0.107406579, 0.6302613616);

static const float3x3 cone2lab = float3x3(
    +0.2104542553, +1.9779984951, +0.0259040371,
    +0.7936177850, -2.4285922050, +0.7827717662,
    +0.0040720468, +0.4505937099, -0.8086757660);

static const float3x3 lab2cone = float3x3(
    +4.0767416621, -1.2684380046, -0.0041960863,
    -3.3077115913, +2.6097574011, -0.7034186147,
    +0.2309699292, -0.3413193965, +1.7076147010);

static const float3x3 cone2lrgb = float3x3(
    1, 1, 1,
    +0.3963377774f, -0.1055613458f, -0.0894841775f,
    +0.2158037573f, -0.0638541728f, -1.2914855480f);

/* RGB to X */

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

float3 RGBtoHSV(in float3 RGB) {
    float3 HCV = RGBtoHCV(RGB);
    float S = HCV.y / (HCV.z + 1e-10);
    return float3(HCV.x, S, HCV.z);
}

float RGBCVtoHUE(in float3 RGB, in float C, in float V) {
    float3 Delta = (V - RGB) / C;
    Delta.rgb -= Delta.brg;
    Delta.rgb += float3(2.0f, 4.0f, 6.0f);
    Delta.brg = step(V, RGB) * Delta.brg;
    float H = max(Delta.r, max(Delta.g, Delta.b));

    return frac(H / 6.0f);
}

float3 RGBtoHCY(in float3 RGB) {
    float3 HCV = RGBtoHCV(RGB);
    float Y = dot(RGB, float3(0.299, 0.587, 0.114));
    float Z = dot(HUEtoRGB(HCV.x), float3(0.299, 0.587, 0.114));

    if (Y < Z)
        HCV.y *= Z / (1e-10 + Y);
    else
        HCV.y *= (1 - Z) / (1e-10 + 1 - Y);
        
    return float3(HCV.x, HCV.y, Y);
}

float3 RGBtoOKLAB(float3 col) {    
    col = mul(col, lrgb2cone);
    col = pow(col, 1.0 / 3.0);
    col = mul(col, cone2lab);
    return col;
}

float3 RGBtoOKLCH(float3 col) {
    col = RGBtoOKLAB(col);

    float3 lch = 0.0f;
    lch.r = col.x;
    lch.g = sqrt(col.g * col.g + col.b * col.b);
    lch.b = atan2(col.b, col.g);

    return lch;
}

/* X to RGB */

float3 HSLtoRGB(in float3 HSL) {
    float3 RGB = HUEtoRGB(HSL.x);
    float C = (1 - abs(2 * HSL.z - 1)) * HSL.y;

    return (RGB - 0.5) * C + HSL.z;
}

float3 HSVtoRGB(in float3 HSV) {
    float3 RGB = HUEtoRGB(HSV.x);

    return ((RGB - 1) * HSV.y + 1) * HSV.z;
}

float3 HCYtoRGB(in float3 HCY) {
    float3 RGB = HUEtoRGB(HCY.x);
    float Z = dot(RGB, float3(0.299, 0.587, 0.114));

    if (HCY.z < Z)
        HCY.y *= HCY.z / Z;
    else if (Z < 1) 
        HCY.y *= (1 - HCY.z) / (1 - Z);

    return (RGB - Z) * HCY.y + HCY.z;
}

float3 OKLABtoRGB(float3 col) {
    col = mul(col, cone2lrgb);
    col = col * col * col;
    col = mul(col, lab2cone);
    return col;
}

float3 OKLCHtoRGB(float3 col) {
    float3 oklab = 0.0f;
    oklab.r = col.r;
    oklab.g = col.g * cos(col.b);
    oklab.b = col.g * sin(col.b);

    return OKLABtoRGB(oklab);
}

float4 PS_ColorSpaceAdjust(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = saturate(tex2D(Common::AcerolaBuffer, uv).rgba);

    float3 convert = 0.0f;

    if (_ColorSpace == 0)
        convert = RGBtoHSL(col.rgb);
    else if (_ColorSpace == 1)
        convert = RGBtoHSV(col.rgb);
    else if (_ColorSpace == 2)
        convert = RGBtoHCY(col.rgb);
    else if (_ColorSpace == 3)
        convert = RGBtoOKLAB(col.rgb);
    else if (_ColorSpace == 4)
        convert = RGBtoOKLCH(col.rgb);

    float3 hsla = float3(_HAAdd, _SCBAdd, _LVYAdd);
    float3 hslm = float3(_HAMultiply, _SCBMultiply, _LVYMultiply);

    if (_ColorSpace >= 3) {
        hsla.rgb = hsla.bgr;
        hslm.rgb = hslm.bgr;
    }

    convert += hsla;
    convert *= hslm;

    float3 rgb = 0.0f;
    if (_ColorSpace == 0)
        rgb = HSLtoRGB(convert);
    else if (_ColorSpace == 1)
        rgb = HSVtoRGB(convert);
    else if (_ColorSpace == 2)
        rgb = HCYtoRGB(convert);
    else if (_ColorSpace == 3)
        rgb = OKLABtoRGB(convert);
    else if (_ColorSpace == 4)
        rgb = OKLCHtoRGB(convert);

    return float4(saturate(rgb), 1.0f);
}

technique AFX_ColorSpaceAdjust < ui_label = "Color Space Adjust"; ui_tooltip = "(LDR) Make use of several color spaces to make specific adjustments to the render."; > {
    pass {
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_ColorSpaceAdjust;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}