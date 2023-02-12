#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

float3 Sample(float2 uv, float deltaX, float deltaY) {
    return saturate(tex2D(Common::AcerolaBuffer, uv + float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) * float2(deltaX, deltaY)).rgb);
}

float3 GetMin(float3 x, float3 y, float3 z) {
    return min(x, min(y, z));
}

float3 GetMax(float3 x, float3 y, float3 z) {
    return max(x, max(y, z));
}

sampler2D AdaptiveSharpness { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(AdaptiveSharpness, uv).rgba; }

void Basic(float2 uv, float sharpnessStrength, out float3 output) {
    float3 col = Sample(uv, 0, 0);

    float neighbor = sharpnessStrength * -1;
    float center = sharpnessStrength * 4 + 1;

    float3 n = Sample(uv, 0, 1);
    float3 e = Sample(uv, 1, 0);
    float3 s = Sample(uv, 0, -1);
    float3 w = Sample(uv, -1, 0);

    output = n * neighbor + e * neighbor + col * center + s * neighbor + w * neighbor;
}

void Adaptive(float2 uv, float sharpnessStrength, out float3 output) {
    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
    float sharpness = -(1.0f / lerp(10.0f, 7.0f, saturate(sharpnessStrength)));

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

    output = saturate((b * w + d * w + f * w + h * w + e) * rcpW);
}

#define AFX_SHARPNESS_SHADOW_CLONE(AFX_TECHNIQUE_NAME, AFX_TECHNIQUE_LABEL, AFX_VARIABLE_CATEGORY, AFX_SHARPNESS_FILTER, AFX_SHARPNESS_STRENGTH, AFX_SHARPNESS_FALLOFF, AFX_SHARPNESS_OFFSET, AFX_SHADER_NAME) \
uniform int AFX_SHARPNESS_FILTER < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_type = "combo"; \
    ui_label = "Filter Type"; \
    ui_items = "Basic\0" \
               "Adaptive\0"; \
    ui_tooltip = "Which sharpness filter to use."; \
> = 0; \
uniform float AFX_SHARPNESS_STRENGTH < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_min = -1.0f; ui_max = 1.0f; \
    ui_label = "Sharpness"; \
    ui_type = "drag"; \
    ui_tooltip = "Adjust sharpening strength."; \
> = 0.0f; \
uniform float AFX_SHARPNESS_FALLOFF < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_min = 0.0f; ui_max = 0.01f; \
    ui_label = "Sharpness Falloff"; \
    ui_type = "slider"; \
    ui_tooltip = "Adjust rate at which sharpness falls off at a distance."; \
> = 0.0f; \
uniform float AFX_SHARPNESS_OFFSET < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_min = 0.0f; ui_max = 1000.0f; \
    ui_label = "Falloff Offset"; \
    ui_type = "slider"; \
    ui_tooltip = "Offset distance at which sharpness starts to falloff."; \
> = 0.0f; \
float4 AFX_SHADER_NAME(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { \
    float4 col = saturate(tex2D(Common::AcerolaBuffer, uv)); \
    float3 output = 0; \
    if (AFX_SHARPNESS_FILTER == 0) Basic(uv, AFX_SHARPNESS_STRENGTH, output); \
    if (AFX_SHARPNESS_FILTER == 1) Adaptive(uv, AFX_SHARPNESS_STRENGTH, output); \
    if (AFX_SHARPNESS_FALLOFF > 0.0f) { \
        float depth = ReShade::GetLinearizedDepth(uv); \
        float viewDistance = depth * 1000; \
        float falloffFactor = 0.0f; \
        falloffFactor = (AFX_SHARPNESS_FALLOFF / log(2)) * max(0.0f, viewDistance - AFX_SHARPNESS_OFFSET); \
        falloffFactor = exp2(-falloffFactor); \
        output = lerp(col.rgb, output, saturate(falloffFactor)); \
    } \
    return float4(output, col.a); \
} \
technique AFX_TECHNIQUE_NAME <ui_label = AFX_TECHNIQUE_LABEL; ui_tooltip = "(LDR) Increases the contrast between edges to create the illusion of high detail."; > { \
    pass Sharpen { \
        RenderTarget = AFXTemp1::AFX_RenderTex1; \
        VertexShader = PostProcessVS; \
        PixelShader = AFX_SHADER_NAME; \
    } \
    pass EndPass { \
        RenderTarget = Common::AcerolaBufferTex; \
        VertexShader = PostProcessVS; \
        PixelShader = PS_EndPass; \
    } \
} \
