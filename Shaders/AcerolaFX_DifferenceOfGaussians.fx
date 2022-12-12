#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"
#include "Includes/AcerolaFX_TempTex2.fxh"
#include "Includes/AcerolaFX_TempTex3.fxh"
#include "Includes/AcerolaFX_TempTex4.fxh"

uniform bool _UseFlow <
    ui_category_closed = true;
    ui_category = "Edge Tangent Flow Settings";
    ui_label = "Use Flow";
    ui_tooltip = "Whether or not to use the flow difference of gaussians or not.";
> = true;

uniform float _SigmaC <
    ui_category_closed = true;
    ui_category = "Edge Tangent Flow Settings";
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Tangent Flow Deviation";
    ui_type = "slider";
    ui_tooltip = "Adjust standard deviation for blurring of the structure tensor.";
> = 2.0f;

uniform float _SigmaM <
    ui_category_closed = true;
    ui_category = "Edge Tangent Flow Settings";
    ui_min = 0.0f; ui_max = 20.0f;
    ui_label = "Line Integral Deviation";
    ui_type = "slider";
    ui_tooltip = "Adjust standard deviation for smoothing of the flow difference of gaussians.";
> = 2.0f;

uniform float2 _LineIntegralStepSize <
    ui_category_closed = true;
    ui_category = "Edge Tangent Flow Settings";
    ui_label = "Line Convolution Step Sizes";
    ui_type = "drag";
    ui_tooltip = "Increase distance between smoothing samples for more painterly visuals.";
> = 1.0f;

uniform bool _CalcDiffBeforeConvolving <
    ui_category_closed = true;
    ui_category = "Edge Tangent Flow Settings";
    ui_label = "Calculate Difference Before Smoothing";
> = true;

uniform float _SigmaE <
    ui_category_closed = true;
    ui_category = "Difference Of Gaussians Settings";
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Difference Of Gaussians Deviation";
    ui_type = "slider";
    ui_tooltip = "Adjust the deviation of the color buffer gaussian blurring.";
> = 2.0f;

uniform float _K <
    ui_category_closed = true;
    ui_category = "Difference Of Gaussians Settings";
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Deviation Scale";
    ui_type = "drag";
    ui_tooltip = "Adjust scale between gaussian blur passes for the color buffer.";
> = 1.6f;

uniform float _P <
    ui_category_closed = true;
    ui_category = "Difference Of Gaussians Settings";
    ui_min = 0.0f; ui_max = 100.0f;
    ui_label = "Sharpness";
    ui_type = "slider";
    ui_tooltip = "Adjust sharpness of the two gaussian blurs to bring out edge lines.";
> = 1.0f;

uniform bool _SmoothEdges <
    ui_category_closed = true;
    ui_category = "Anti Aliasing Settings";
    ui_label = "Smooth Edges";
    ui_tooltip = "Whether or not to apply anti aliasing to the edges of the image.";
> = true;

uniform float _SigmaA <
    ui_category_closed = true;
    ui_category = "Anti Aliasing Settings";
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Edge Smooth Deviation";
    ui_type = "slider";
    ui_tooltip = "Adjust standard deviation for gaussian blurring of edge lines.";
> = 2.0f;

uniform float2 _AntiAliasStepSize <
    ui_category_closed = true;
    ui_category = "Anti Aliasing Settings";
    ui_label = "Edge Smoothing Step Sizes";
    ui_type = "drag";
    ui_tooltip = "Increase distance between smoothing samples for more painterly visuals.";
> = 1.0f;


uniform int _Thresholding <
    ui_category_closed = true;
    ui_category = "Threshold Settings";
    ui_type = "combo";
    ui_label = "Threshold Mode";
    ui_items = "No Threshold\0"
               "Tanh\0"
               "Quantization\0"
               "Soft Quantization\0";
> = 0;

uniform int _Thresholds <
    ui_category_closed = true;
    ui_category = "Threshold Settings";
    ui_min = 1; ui_max = 16;
    ui_label = "Quantizer Step";
    ui_type = "slider";
    ui_tooltip = "Adjust number of allowed difference values.";
> = 1;

uniform float _Threshold <
    ui_category_closed = true;
    ui_category = "Threshold Settings";
    ui_min = 0.0f; ui_max = 100.0f;
    ui_label = "White Point";
    ui_type = "slider";
    ui_tooltip = "Adjust value at which difference is clamped to white.";
> = 20.0f;

uniform float _Phi <
    ui_category_closed = true;
    ui_category = "Threshold Settings";
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Soft Threshold";
    ui_type = "slider";
    ui_tooltip = "Adjust curve of hyperbolic tangent.";
> = 1.0f;

uniform bool _EnableHatching <
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_label = "Use Hatching";
    ui_tooltip = "Whether or not to render cross hatching.";
> = false;

uniform int _HatchTexture <
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_type = "combo";
    ui_label = "Hatch Texture";
    ui_items = "No Texture\0"
               "Texture 1\0"
               "Texture 2\0"
               "Texture 3\0"
               "Texture 4\0"
               "Custom Texture\0";
> = 1;

uniform bool _ColoredPencilEnabled <
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_label = "Colored Pencil";
    ui_tooltip = "Color the hatch lines.";
> = false;

uniform float _BrightnessOffset <
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Brightness";
    ui_type = "drag";
    ui_tooltip = "Adjusts brightness of color pencil lines.";
> = 0.5f;

uniform float _Saturation <
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Saturation";
    ui_type = "drag";
    ui_tooltip = "Adjusts saturation of color pencil lines to bring out more color.";
> = 1.0f;

uniform float _HatchRes1 <
    ui_spacing = 5.0f;
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "First Hatch Resolution";
    ui_type = "drag";
    ui_tooltip = "Adjust the size of the first hatch layer texture resolution.";
> = 1.0f;

uniform float _HatchRotation1 <
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_min = -180.0f; ui_max = 180.0f;
    ui_label = "First Hatch Rotation";
    ui_type = "slider";
    ui_tooltip = "Adjust the rotation of the first hatch layer texture resolution.";
> = 1.0f;

uniform bool _UseLayer2 <
    ui_spacing = 5.0f;
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_label = "Layer 2";
> = false;

uniform float _Threshold2 <
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_min = 0.0f; ui_max = 100.0f;
    ui_label = "Second White Point";
    ui_type = "slider";
    ui_tooltip = "Adjust the white point of the second hatching layer.";
> = 1.0f;

uniform float _HatchRes2 <
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Second Hatch Resolution";
    ui_type = "drag";
    ui_tooltip = "Adjust the size of the second hatch layer texture resolution.";
> = 1.0f;

uniform float _HatchRotation2 <
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_min = -180.0f; ui_max = 180.0f;
    ui_label = "Second Hatch Rotation";
    ui_type = "slider";
    ui_tooltip = "Adjust the rotation of the second hatch layer texture resolution.";
> = 1.0f;

uniform bool _UseLayer3 <
    ui_spacing = 5.0f;
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_label = "Layer 3";
> = false;

uniform float _Threshold3 <
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_min = 0.0f; ui_max = 100.0f;
    ui_label = "Third White Point";
    ui_type = "slider";
    ui_tooltip = "Adjust the white point of the third hatching layer.";
> = 1.0f;

uniform float _HatchRes3 <
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Third Hatch Resolution";
    ui_type = "drag";
    ui_tooltip = "Adjust the size of the third hatch layer texture resolution.";
> = 1.0f;

uniform float _HatchRotation3 <
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_min = -180.0f; ui_max = 180.0f;
    ui_label = "Third Hatch Rotation";
    ui_type = "slider";
    ui_tooltip = "Adjust the rotation of the third hatch layer texture resolution.";
> = 1.0f;

uniform bool _UseLayer4 <
    ui_spacing = 5.0f;
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_label = "Layer 4";
> = false;

uniform float _Threshold4 <
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_min = 0.0f; ui_max = 100.0f;
    ui_label = "Fourth White Point";
    ui_type = "slider";
    ui_tooltip = "Adjust the white point of the fourth hatching layer.";
> = 1.0f;

uniform float _HatchRes4 <
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Fourth Hatch Resolution";
    ui_type = "drag";
    ui_tooltip = "Adjust the size of the fourth hatch layer texture resolution.";
> = 1.0f;

uniform float _HatchRotation4 <
    ui_category_closed = true;
    ui_category = "Cross Hatch Settings";
    ui_min = -180.0f; ui_max = 180.0f;
    ui_label = "Fourth Hatch Rotation";
    ui_type = "slider";
    ui_tooltip = "Adjust the rotation of the fourth hatch layer texture resolution.";
> = 1.0f;

uniform float _TermStrength <
    ui_category_closed = true;
    ui_category = "Blend Settings";
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Term Strength";
    ui_type = "drag";
    ui_tooltip = "Adjust scale of difference of gaussians output.";
> = 1;

uniform int _BlendMode <
    ui_category_closed = true;
    ui_category = "Blend Settings";
    ui_type = "combo";
    ui_label = "Blend Mode";
    ui_items = "No Blend\0"
               "Interpolate\0"
               "Two Point Interpolate\0";
> = 0;

uniform float3 _MinColor <
    ui_category_closed = true;
    ui_category = "Blend Settings";
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Min Color";
    ui_type = "color";
    ui_tooltip = "Set minimum color.";
> = 0.0f;

uniform float3 _MaxColor <
    ui_category_closed = true;
    ui_category = "Blend Settings";
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Max Color";
    ui_type = "color";
    ui_tooltip = "Set maximum color.";
> = 1.0f;

uniform float _BlendStrength <
    ui_category_closed = true;
    ui_category = "Blend Settings";
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Blend Strength";
    ui_type = "drag";
    ui_tooltip = "Adjust strength of color blending.";
> = 1;

#ifndef AFX_HATCH_TEXTURE_PATH
#define AFX_HATCH_TEXTURE_PATH "paper.png"
#endif

#ifndef AFX_HATCH_TEXTURE_WIDTH
#define AFX_HATCH_TEXTURE_WIDTH 512
#endif

#ifndef AFX_HATCH_TEXTURE_HEIGHT
#define AFX_HATCH_TEXTURE_HEIGHT 512
#endif

sampler2D Lab { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
sampler2D HorizontalBlur { Texture = AFXTemp3::AFX_RenderTex3; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
sampler2D DOGTFM { Texture = AFXTemp2::AFX_RenderTex2; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };

sampler2D DifferenceOfGaussians { Texture = AFXTemp4::AFX_RenderTex4; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
storage2D s_DifferenceOfGaussians { Texture = AFXTemp4::AFX_RenderTex4; };

texture2D AFX_HatchTex < source = "hatch.png"; > { Width = 512; Height = 512; };
sampler2D Hatch { Texture = AFX_HatchTex; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR; AddressU = REPEAT; AddressV = REPEAT; };
texture2D AFX_Hatch2Tex < source = "hatch 2.png"; > { Width = 512; Height = 512; };
sampler2D Hatch2 { Texture = AFX_Hatch2Tex; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR; AddressU = REPEAT; AddressV = REPEAT; };
texture2D AFX_Hatch3Tex < source = "hatch 3.png"; > { Width = 512; Height = 512; };
sampler2D Hatch3 { Texture = AFX_Hatch3Tex; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR; AddressU = REPEAT; AddressV = REPEAT; };
texture2D AFX_Hatch4Tex < source = "hatch 4.png"; > { Width = 512; Height = 512; };
sampler2D Hatch4 { Texture = AFX_Hatch4Tex; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR; AddressU = REPEAT; AddressV = REPEAT; };
texture2D AFX_CustomHatchTex < source = AFX_HATCH_TEXTURE_PATH; > { Width = AFX_HATCH_TEXTURE_WIDTH; Height = AFX_HATCH_TEXTURE_HEIGHT; };
sampler2D CustomHatch { Texture = AFX_CustomHatchTex; AddressU = REPEAT; AddressV = REPEAT; };

sampler2D GaussiansBlended { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
//float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return float4(tex2D(DOGTFM, uv).rg, 0.0f, 1.0f); }
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(GaussiansBlended, uv).rgba; }

float gaussian(float sigma, float pos) {
    return (1.0f / sqrt(2.0f * AFX_PI * sigma * sigma)) * exp(-(pos * pos) / (2.0f * sigma * sigma));
}

float4 PS_RGBtoLAB(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return float4(Common::rgb2lab(tex2D(Common::AcerolaBuffer, uv).rgb), 1.0f);
}

void CS_StructureTensor(uint3 tid : SV_DISPATCHTHREADID) {
    float2 d = float2(1, 1);

    float3 Sx = (
            1.0f * tex2Dfetch(Lab, tid.xy + float2(-d.x, -d.y)).rgb +
            2.0f * tex2Dfetch(Lab, tid.xy + float2(-d.x,  0.0)).rgb +
            1.0f * tex2Dfetch(Lab, tid.xy + float2(-d.x,  d.y)).rgb +
            -1.0f * tex2Dfetch(Lab, tid.xy + float2(d.x, -d.y)).rgb +
            -2.0f * tex2Dfetch(Lab, tid.xy + float2(d.x,  0.0)).rgb +
            -1.0f * tex2Dfetch(Lab, tid.xy + float2(d.x,  d.y)).rgb
    ) / 4.0f;

    float3 Sy = (
            1.0f * tex2Dfetch(Lab, tid.xy + float2(-d.x, -d.y)).rgb +
            2.0f * tex2Dfetch(Lab, tid.xy + float2( 0.0, -d.y)).rgb +
            1.0f * tex2Dfetch(Lab, tid.xy + float2( d.x, -d.y)).rgb +
            -1.0f * tex2Dfetch(Lab, tid.xy + float2(-d.x, d.y)).rgb +
            -2.0f * tex2Dfetch(Lab, tid.xy + float2( 0.0, d.y)).rgb +
            -1.0f * tex2Dfetch(Lab, tid.xy + float2( d.x, d.y)).rgb
    ) / 4.0f;

    tex2Dstore(s_DifferenceOfGaussians, tid.xy, float4(dot(Sx, Sx), dot(Sy, Sy), dot(Sx, Sy), 1.0f));
}

float4 PS_TFMHorizontalBlur(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    int kernelRadius = max(1.0f, floor(_SigmaC * 2.45f));

    float3 col = 0;
    float kernelSum = 0.0f;

    for (int x = -kernelRadius; x <= kernelRadius; ++x) {
        float3 c = tex2D(DifferenceOfGaussians, uv + float2(x, 0) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).rgb;
        float gauss = gaussian(_SigmaC, x);

        col += c * gauss;
        kernelSum += gauss;
    }

    return float4(col / kernelSum, 1.0f);
}

float4 PS_TFMVerticalBlur(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    int kernelRadius = max(1.0f, floor(_SigmaC * 2.45f));

    float3 col = 0;
    float kernelSum = 0.0f;

    for (int y = -kernelRadius; y <= kernelRadius; ++y) {
        float3 c = tex2D(HorizontalBlur, uv + float2(0, y) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).rgb;
        float gauss = gaussian(_SigmaC, y);

        col += c * gauss;
        kernelSum += gauss;
    }

    float3 g = col.rgb / kernelSum;

    float lambda1 = 0.5f * (g.y + g.x + sqrt(g.y * g.y - 2.0f * g.x * g.y + g.x * g.x + 4.0 * g.z * g.z));
    float2 d = float2(g.x - lambda1, g.z);
    if (d.x > 0) d.x = -d.x;

    return length(d) ? float4(normalize(d), sqrt(lambda1), 1.0f) : float4(0.0f, 1.0f, 0.0f, 1.0f);
}

float4 PS_HorizontalBlur(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    int kernelRadius = _SigmaE * 2 > 1 ? _SigmaE * 2 : 1;

    float2 col = 0;
    float2 kernelSum = 0.0f;

    float2 n = 0.0f;
    float ds = 0.0f;
    if (_UseFlow) {
        float2 t = tex2D(DOGTFM, uv).xy;
        n = float2(t.y, -t.x);
        float2 nabs = abs(n);
        ds = 1.0 / ((nabs.x > nabs.y) ? nabs.x : nabs.y);
        n *= float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

        col = tex2D(Lab, uv).xx;
        kernelSum = 1.0f;

        [loop]
        for (int x = ds; x <= kernelRadius; ++x) {
            float gauss1 = gaussian(_SigmaE, x);
            float gauss2 = gaussian(_SigmaE * _K, x);

            float c1 = tex2Dlod(Lab, float4(uv - x * n, 0, 0)).r;
            float c2 = tex2Dlod(Lab, float4(uv + x * n, 0, 0)).r;

            col.r += (c1 + c2) * gauss1;
            kernelSum.x += 2.0f * gauss1;

            col.g += (c1 + c2) * gauss2;
            kernelSum.y +=  2.0f * gauss2;
        }

        col /= kernelSum;

        return float4(col, (1 + _P) * (col.r * 100.0f) - _P * (col.g * 100.0f), 1.0f);
    } else { // Normal DoG Blur Pass
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
}

float4 PS_VerticalBlur(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    int kernelRadius = _SigmaE * 2 > 1 ? _SigmaE * 2 : 1;
    float D = 0.0f;
    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

    if (_UseFlow) {
        kernelRadius = _SigmaM * 2 > 1 ? _SigmaM * 2 : 1;

        float3 c = tex2D(HorizontalBlur, uv).rgb;
        float2 G = _CalcDiffBeforeConvolving ? float2(c.b, 0.0f) : c.rg;
        float2 w = 1.0f;

        float2 v = tex2D(DOGTFM, uv).xy * texelSize;
        float2 stepSize = _LineIntegralStepSize;

        float2 st0 = uv;
        float2 v0 = v;

        [loop]
        for (int d = 1; d <= kernelRadius; ++d) {
            st0 += v0 * stepSize.x;
            float3 c = tex2D(HorizontalBlur, st0).rgb;
            float gauss1 = gaussian(_SigmaM, d);


            if (_CalcDiffBeforeConvolving) {
                G.r += gauss1 * c.b;
                w.x += gauss1;
            } else {
                float gauss2 = gaussian(_SigmaM * _K, d);

                G.r += gauss1 * c.r;
                w.x += gauss1;

                G.g += gauss2 * c.g;
                w.y += gauss2;
            }

            v0 = tex2D(DOGTFM, st0).xy * texelSize;
        }

        float2 st1 = uv;
        float2 v1 = v;

        [loop]
        for (int d = 1; d <= kernelRadius; ++d) {
            st1 -= v1 * stepSize.y;
            float3 c = tex2D(HorizontalBlur, st1).rgb;
            float gauss1 = gaussian(_SigmaM, d);


            if (_CalcDiffBeforeConvolving) {
                G.r += gauss1 * c.b;
                w.x += gauss1;
            } else {
                float gauss2 = gaussian(_SigmaM * _K, d);

                G.r += gauss1 * c.r;
                w.x += gauss1;

                G.g += gauss2 * c.g;
                w.y += gauss2;
            }

            v1 = tex2D(DOGTFM, st1).xy * texelSize;
        }

        G /= max(1.0f, w);

        if (_CalcDiffBeforeConvolving) {
            D = G.x;
        } else {
            D = (1 + _P) * (G.r * 100.0f) - _P * (G.g * 100.0f);
        }
    } else {
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

        D = (1 + _P) * (col.r * 100.0f) - _P * (col.g * 100.0f);
    }
    D = max(0.0f, D);

    float4 output = D;
    if (_Thresholding == 0)
        output /= 100.0f;
    if (_Thresholding == 1 || _EnableHatching) {   
        output.r = (D >= _Threshold) ? 1 : 1 + tanh(_Phi * (D - _Threshold));
        output.g = (D >= _Threshold2) ? 1 : 1 + tanh(_Phi * (D - _Threshold2));
        output.b = (D >= _Threshold3) ? 1 : 1 + tanh(_Phi * (D - _Threshold3));
        output.a = (D >= _Threshold4) ? 1 : 1 + tanh(_Phi * (D - _Threshold4));
    }
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

float4 PS_AntiAlias(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    if (_SmoothEdges) {
        float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
        
        float kernelSize = _SigmaA * 2;

        float4 G = tex2D(DifferenceOfGaussians, uv);
        float w = 1.0f;

        float2 v = tex2D(DOGTFM, uv).xy * texelSize;
        float2 stepSize = _AntiAliasStepSize;

        float2 st0 = uv;
        float2 v0 = v;

        [loop]
        for (int d = 1; d <= kernelSize; ++d) {
            st0 += v0 * stepSize.x;
            float4 c = tex2D(DifferenceOfGaussians, st0);
            float gauss1 = gaussian(_SigmaA, d);

            G += gauss1 * c;
            w += gauss1;

            v0 = tex2D(DOGTFM, st0).xy * texelSize;
        }

        float2 st1 = uv;
        float2 v1 = v;

        [loop]
        for (int d = 1; d <= kernelSize; ++d) {
            st1 -= v1 * stepSize.y;
            float4 c = tex2D(DifferenceOfGaussians, st1);
            float gauss1 = gaussian(_SigmaA, d);

            G += gauss1 * c;
            w += gauss1;

            v1 = tex2D(DOGTFM, st1).xy * texelSize;
        }

        return G /= max(1.0f, w);
    } else {
        return tex2D(DifferenceOfGaussians, uv);
    }
}

float3 SampleHatch(int tex, float2 uv) {
    float3 output = 0.0f;
    switch(tex) {
        case 0:
            output = 0.0f;
        break;
        case 1:
            output = tex2D(Hatch, uv).rgb;
        break;
        case 2:
            output = tex2D(Hatch2, uv).rgb;
        break;
        case 3:
            output = tex2D(Hatch3, uv).rgb;
        break;
        case 4:
            output = tex2D(Hatch4, uv).rgb;
        break;
        case 5:
            output = tex2D(CustomHatch, uv).rgb;
        break;
    }

    return output;
}

float4 PS_ColorBlend(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(Common::AcerolaBuffer, uv);
    float4 D = tex2D(HorizontalBlur, uv) * _TermStrength;

    float4 output = D;

    if (_EnableHatching) {
        float2 hatchUV = (position.xy / ((_HatchTexture == 4) ? float2(AFX_HATCH_TEXTURE_WIDTH, AFX_HATCH_TEXTURE_HEIGHT) : 512.0f)) * 2 - 1;
        float radians = _HatchRotation1 * AFX_PI / 180.0f;
        float2x2 R = float2x2(
            cos(radians), -sin(radians),
            sin(radians), cos(radians)
        );
        float3 s1 = SampleHatch(_HatchTexture, mul(R, hatchUV * _HatchRes1) * 0.5f + 0.5f);

        output.rgb = lerp(s1, 1.0f, D.r);
        
        if (_UseLayer2) {
            radians = _HatchRotation2 * AFX_PI / 180.0f;
            float2x2 R2 = float2x2(
                cos(radians), -sin(radians),
                sin(radians), cos(radians)
            );
            float3 s2 = SampleHatch(_HatchTexture, mul(R2, hatchUV * _HatchRes2) * 0.5f + 0.5f);

            output.rgb *= lerp(s2, 1.0f, D.g);
        }

        if (_UseLayer3) {
            radians = _HatchRotation3 * AFX_PI / 180.0f;
            float2x2 R3 = float2x2(
                cos(radians), -sin(radians),
                sin(radians), cos(radians)
            );
            float3 s3 = SampleHatch(_HatchTexture, mul(R3, hatchUV * _HatchRes3) * 0.5f + 0.5f);

            output.rgb *= lerp(s3, 1.0f, D.b);
        }

        if (_UseLayer4) {
            radians = _HatchRotation4 * AFX_PI / 180.0f;
            float2x2 R4 = float2x2(
                cos(radians), -sin(radians),
                sin(radians), cos(radians)
            );
            float3 s4 = SampleHatch(_HatchTexture, mul(R4, hatchUV * _HatchRes4) * 0.5f + 0.5f);

            output.rgb *= lerp(s4, 1.0f, D.a);
        }
        if (_ColoredPencilEnabled) {
            float3 coloredPencil = col.rgb + _BrightnessOffset;
            coloredPencil = lerp(Common::Luminance(coloredPencil), coloredPencil, _Saturation);
            coloredPencil = lerp(coloredPencil, _MaxColor, output.rgb);

            return float4(lerp(col.rgb, coloredPencil, _BlendStrength), 1.0f);
        }
    }

    if (_EnableHatching)
        D = Common::Luminance(output.rgb);
    if (_BlendMode == 0)
        output.rgb = lerp(_MinColor, _MaxColor, D.r);
    if (_BlendMode == 1)
        output.rgb = lerp(_MinColor, col.rgb, D.r);
    if (_BlendMode == 2) {
        if (D.r < 0.5f)
            output.rgb = lerp(_MinColor, col.rgb, D.r * 2.0f);
        else
            output.rgb = lerp(col.rgb, _MaxColor, (D.r - 0.5f) * 2.0f);
    }

    return saturate(lerp(col, output, _BlendStrength));
}

technique AFX_DifferenceOfGaussians < ui_label = "Difference Of Gaussians"; > {
    pass {
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_RGBtoLAB;
    }

    pass {
        ComputeShader = CS_StructureTensor<8, 8>;

        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    pass {
        RenderTarget = AFXTemp3::AFX_RenderTex3;

        VertexShader = PostProcessVS;
        PixelShader = PS_TFMHorizontalBlur;
    }

    pass {
        RenderTarget = AFXTemp2::AFX_RenderTex2;

        VertexShader = PostProcessVS;
        PixelShader = PS_TFMVerticalBlur;
    }

    pass {
        RenderTarget = AFXTemp3::AFX_RenderTex3;

        VertexShader = PostProcessVS;
        PixelShader = PS_HorizontalBlur;
    }

    pass {
        RenderTarget = AFXTemp4::AFX_RenderTex4;

        VertexShader = PostProcessVS;
        PixelShader = PS_VerticalBlur;
    }

    pass {
        RenderTarget = AFXTemp3::AFX_RenderTex3;

        VertexShader = PostProcessVS;
        PixelShader = PS_AntiAlias;
    }

    pass {
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_ColorBlend;
    }


    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}