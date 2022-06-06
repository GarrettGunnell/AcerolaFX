#include "ReShade.fxh"
#include "Common.fxh"

uniform float _Sharpness <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Sharpness";
    ui_type = "drag";
    ui_tooltip = "Adjust sharpening";
> = 1.0f;

float3 Sample(float2 uv, float deltaX, float deltaY) {
    return saturate(tex2D(Common::AcerolaBuffer, uv + float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) * float2(deltaX, deltaY)).rgb);
}

float GetMin(float x, float y, float z) {
    return min(x, min(y, z));
}

float GetMax(float x, float y, float z) {
    return max(x, max(y, z));
}

texture2D AdaptiveSharpnessTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D AdaptiveSharpness { Texture = AdaptiveSharpnessTex; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(AdaptiveSharpness, uv).rgba; }

float4 PS_AdaptiveSharpness(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = saturate(tex2D(Common::AcerolaBuffer, uv));

    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

    float sharpness = -(1.0f / lerp(8.0f, 5.0f, saturate(_Sharpness)));

    float3 a = Sample(uv, -1, -1);
    float3 b = Sample(uv,  0, -1);
    float3 c = Sample(uv,  1, -1);
    float3 d = Sample(uv, -1,  0);
    float3 e = Sample(uv,  0,  0);
    float3 f = Sample(uv,  1,  0);
    float3 g = Sample(uv, -1,  1);
    float3 h = Sample(uv,  0,  1);
    float3 i = Sample(uv,  1,  1);

    float minR = GetMin(GetMin(d.r, e.r, f.r), b.r, h.r);
    float minG = GetMin(GetMin(d.g, e.g, f.g), b.g, h.g);
    float minB = GetMin(GetMin(d.b, e.b, f.b), b.b, h.b);
    float3 minRGB = float3(minR, minG, minB);

    float minR2 = GetMin(GetMin(minR, a.r, c.r), g.r, i.r);
    float minG2 = GetMin(GetMin(minG, a.g, c.g), g.g, i.g);
    float minB2 = GetMin(GetMin(minB, a.b, c.b), g.b, i.b);
    float3 minRGB2 = float3(minR2, minG2, minB2);

    minRGB += minRGB2;

    float maxR = GetMax(GetMax(d.r, e.r, f.r), b.r, h.r);
    float maxG = GetMax(GetMax(d.g, e.g, f.g), b.g, h.g);
    float maxB = GetMax(GetMax(d.b, e.b, f.b), b.b, h.b);
    float3 maxRGB = float3(maxR, maxG, maxB);
    float maxR2 = GetMax(GetMax(maxR, a.r, c.r), g.r, i.r);
    float maxG2 = GetMax(GetMax(maxG, a.g, c.g), g.g, i.g);
    float maxB2 = GetMax(GetMax(maxB, a.b, c.b), g.b, i.b);
    float3 maxRGB2 = float3(maxR2, maxG2, maxB2);

    maxRGB += maxRGB2;

    float3 rcpM = 1.0f / maxRGB;
    float3 amp = saturate(min(minRGB, float3(2.0f, 2.0f, 2.0f) - maxRGB) * rcpM);
    amp = sqrt(amp);

    float3 w = amp * sharpness;
    float3 rcpW = 1.0f / (1.0f + 4.0f * w);

    float3 output = saturate((b * w + d * w + f * w + h * w + e) * rcpW);

    return float4(lerp(col.rgb, output.rgb, 1.0f - col.a), col.a);
}

technique AdaptiveSharpness <ui_tooltip = "(LDR)(HIGH PERFORMANCE COST) Adaptively increases the contrast between edges to create the illusion of high detail."; > {
    pass Sharpen {
        RenderTarget = AdaptiveSharpnessTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_AdaptiveSharpness;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}