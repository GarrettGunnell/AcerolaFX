#include "AcerolaFX_Common.fxh"

uniform float _Sharpness <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Sharpness";
    ui_type = "drag";
    ui_tooltip = "Adjust sharpening strength.";
> = 1.0f;

uniform float _SharpnessFalloff <
    ui_category = "Advanced Settings";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 0.01f;
    ui_label = "Sharpness Falloff";
    ui_type = "slider";
    ui_tooltip = "Adjust rate at which sharpness falls off at a distance.";
> = 0.0f;

uniform float _Offset <
    ui_category = "Advanced Settings";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 1000.0f;
    ui_label = "Falloff Offset";
    ui_type = "slider";
    ui_tooltip = "Offset distance at which sharpness starts to falloff..";
> = 0.0f;

float3 Sample(float2 uv, float deltaX, float deltaY) {
    return saturate(tex2D(Common::AcerolaBuffer, uv + float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) * float2(deltaX, deltaY)).rgb);
}

float3 GetMin(float3 x, float3 y, float3 z) {
    return min(x, min(y, z));
}

float3 GetMax(float3 x, float3 y, float3 z) {
    return max(x, max(y, z));
}

texture2D AdaptiveSharpnessTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D AdaptiveSharpness { Texture = AdaptiveSharpnessTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(AdaptiveSharpness, uv).rgba; }

float4 PS_AdaptiveSharpness(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = saturate(tex2D(Common::AcerolaBuffer, uv));

    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
    float sharpness = -(1.0f / lerp(10.0f, 7.0f, saturate(_Sharpness)));

    float3 a = Sample(uv, -1, -1);
    float3 b = Sample(uv,  0, -1);
    float3 c = Sample(uv,  1, -1);
    float3 d = Sample(uv, -1,  0);
    float3 e = Sample(uv,  0,  0);
    float3 f = Sample(uv,  1,  0);
    float3 g = Sample(uv, -1,  1);
    float3 h = Sample(uv,  0,  1);
    float3 i = Sample(uv,  1,  1);

    float3 minRGB = GetMin(GetMin(d, e, f), b, h);
    float3 minRGB2 = GetMin(GetMin(minRGB, a, c), g, i);

    minRGB += minRGB2;

    float3 maxRGB = GetMax(GetMax(d, e, f), b, h);
    float3 maxRGB2 = GetMax(GetMax(maxRGB, a, c), g, i);

    maxRGB += maxRGB2;

    float3 rcpM = 1.0f / maxRGB;
    float3 amp = saturate(min(minRGB, 2.0f - maxRGB) * rcpM);
    amp = sqrt(amp);

    float3 w = amp * sharpness;
    float3 rcpW = 1.0f / (1.0f + 4.0f * w);

    float3 output = saturate((b * w + d * w + f * w + h * w + e) * rcpW);

    if (_SharpnessFalloff > 0.0f) {
        float depth = ReShade::GetLinearizedDepth(uv);
        float viewDistance = depth * 1000;

        float falloffFactor = 0.0f;

        falloffFactor = (_SharpnessFalloff / log(2)) * max(0.0f, viewDistance - _Offset);
        falloffFactor = exp2(-falloffFactor);

        output = lerp(col.rgb, output, saturate(falloffFactor));
    }

    return float4(output, col.a);
}

technique AFX_AdaptiveSharpness <ui_label = "Sharpness"; ui_tooltip = "(LDR) Adaptively increases the contrast between edges to create the illusion of high detail."; > {
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