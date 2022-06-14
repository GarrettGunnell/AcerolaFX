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

float4 GetMin(float4 x, float4 y, float4 z) {
    return min(x, min(y, z));
}

float4 GetMax(float4 x, float4 y, float4 z) {
    return max(x, max(y, z));
}

texture2D AdaptiveSharpnessTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; }; 
sampler2D AdaptiveSharpness { Texture = AdaptiveSharpnessTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
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

    float UIMask = saturate(1.0f - a.a - b.a - c.a - d.a - e.a - f.a - g.a - h.a - i.a);

    float4 minRGB = GetMin(GetMin(d, e, f), b, h);
    float4 minRGB2 = GetMin(GetMin(minRGB, a, c), g, i);

    minRGB += minRGB2;

    float4 maxRGB = GetMax(GetMax(d, e, f), b, h);
    float4 maxRGB2 = GetMax(GetMax(maxRGB, a, c), g, i);

    maxRGB += maxRGB2;

    float4 rcpM = 1.0f / maxRGB;
    float4 amp = saturate(min(minRGB, 2.0f - maxRGB) * rcpM);
    amp = sqrt(amp);

    float4 w = amp * sharpness;
    float4 rcpW = 1.0f / (1.0f + 4.0f * w);

    float4 output = saturate((b * w + d * w + f * w + h * w + e) * rcpW);

    return float4(lerp(col.rgb, output.rgb, UIMask), col.a);
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