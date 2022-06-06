#include "ReShade.fxh"
#include "Common.fxh"

uniform float _Sharpness <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Sharpness";
    ui_type = "drag";
    ui_tooltip = "Adjust sharpening";
> = 1.0f;

float4 Sample(float2 uv, float deltaX, float deltaY) {
    return saturate(tex2D(Common::AcerolaBuffer, uv + float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) * float2(deltaX, deltaY)));
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

    float4 a = Sample(uv, -1, -1);
    float4 b = Sample(uv,  0, -1);
    float4 c = Sample(uv,  1, -1);
    float4 d = Sample(uv, -1,  0);
    float4 e = Sample(uv,  0,  0);
    float4 f = Sample(uv,  1,  0);
    float4 g = Sample(uv, -1,  1);
    float4 h = Sample(uv,  0,  1);
    float4 i = Sample(uv,  1,  1);

    float minR = GetMin(GetMin(d.r, e.r, f.r), b.r, h.r);
    float minG = GetMin(GetMin(d.g, e.g, f.g), b.g, h.g);
    float minB = GetMin(GetMin(d.b, e.b, f.b), b.b, h.b);
    float minR2 = GetMin(GetMin(minR, a.r, c.r), g.r, i.r);
    float minG2 = GetMin(GetMin(minG, a.g, c.g), g.g, i.g);
    float minB2 = GetMin(GetMin(minB, a.b, c.b), g.b, i.b);

    minR = minR + minR2;
    minG = minG + minG2;
    minB = minB + minB2;

    float maxR = GetMax(GetMax(d.r, e.r, f.r), b.r, h.r);
    float maxG = GetMax(GetMax(d.g, e.g, f.g), b.g, h.g);
    float maxB = GetMax(GetMax(d.b, e.b, f.b), b.b, h.b);
    float maxR2 = GetMax(GetMax(maxR, a.r, c.r), g.r, i.r);
    float maxG2 = GetMax(GetMax(maxG, a.g, c.g), g.g, i.g);
    float maxB2 = GetMax(GetMax(maxB, a.b, c.b), g.b, i.b);

    maxR = maxR + maxR2;
    maxG = maxG + maxG2;
    maxB = maxB + maxB2;

    float rcpMR = 1.0f / maxR;
    float rcpMG = 1.0f / maxG;
    float rcpMB = 1.0f / maxB;

    float ampR = saturate(min(minR, 2.0f - maxR) * rcpMR);
    float ampG = saturate(min(minG, 2.0f - maxG) * rcpMG);
    float ampB = saturate(min(minB, 2.0f - maxB) * rcpMB);

    ampR = sqrt(ampR);
    ampG = sqrt(ampG);
    ampB = sqrt(ampB);

    float wR = ampR * sharpness;
    float wG = ampG * sharpness;
    float wB = ampB * sharpness;

    float rcpWeightR = 1.0f / (1.0f + 4.0f * wR);
    float rcpWeightG = 1.0f / (1.0f + 4.0f * wG);
    float rcpWeightB = 1.0f / (1.0f + 4.0f * wB);

    float3 output = 1.0f;
    output.r = saturate((b.r * wR + d.r * wR + f.r * wR + h.r * wR + e.r) * rcpWeightR);
    output.g = saturate((b.g * wG + d.g * wG + f.g * wG + h.g * wG + e.g) * rcpWeightG);
    output.b = saturate((b.b * wB + d.b * wB + f.b * wB + h.b * wB + e.b) * rcpWeightB);

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