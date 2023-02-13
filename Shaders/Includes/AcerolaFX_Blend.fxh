#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

#ifndef AFX_TEXTURE_PATH
#define AFX_TEXTURE_PATH "watercolor.png"
#endif

#ifndef AFX_TEXTURE_WIDTH
#define AFX_TEXTURE_WIDTH 1024
#endif

#ifndef AFX_TEXTURE_HEIGHT
#define AFX_TEXTURE_HEIGHT 512
#endif

texture2D AFX_BlendTextureTex < source = AFX_TEXTURE_PATH; > { Width = AFX_TEXTURE_WIDTH; Height = AFX_TEXTURE_HEIGHT; };
sampler2D Image { Texture = AFX_BlendTextureTex; AddressU = REPEAT; AddressV = REPEAT; };
texture2D AFX_WatercolorTex < source = "watercolor.png"; > { Width = AFX_TEXTURE_WIDTH; Height = AFX_TEXTURE_HEIGHT; };
sampler2D Watercolor { Texture = AFX_WatercolorTex; AddressU = REPEAT; AddressV = REPEAT; };
texture2D AFX_PaperTex < source = "paper.png"; > { Width = AFX_TEXTURE_WIDTH; Height = AFX_TEXTURE_HEIGHT; };
sampler2D Paper { Texture = AFX_PaperTex; AddressU = REPEAT; AddressV = REPEAT; };

sampler2D Blend { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Blend, uv).rgba; }

float3 SampleBlendTex(int tex, float2 position) {
    float3 output = 0.0f;
    switch(tex) {
        case 0:
            output = tex2D(Paper, position / float2(1024, 512)).rgb;
        break;
        case 1:
            output = tex2D(Watercolor, position / float2(1024, 512)).rgb;
        break;
        case 2:
            output = tex2D(Image, position / float2(AFX_TEXTURE_WIDTH, AFX_TEXTURE_HEIGHT)).rgb;
        break;
    }

    return output;
}

#define AFX_BLEND_SHADOW_CLONE(AFX_TECHNIQUE_NAME, AFX_TECHNIQUE_LABEL, AFX_VARIABLE_CATEGORY, AFX_BLEND_MODE, AFX_BLEND_COLOR, AFX_COLOR_BLEND, AFX_BLEND_TEXTURE, AFX_TEXTURE_BLEND, AFX_TEXTURE_RES, AFX_BLEND_STRENGTH, AFX_BLEND_SAMPLE_SKY, AFX_SHADER_NAME) \
uniform int AFX_BLEND_MODE < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_type = "combo"; \
    ui_label = "Blend Mode"; \
    ui_tooltip = "Photoshop blend mode to use"; \
    ui_items = "No Blend\0" \
               "Add\0" \
               "Multiply\0" \
               "Screen\0" \
               "Overlay\0" \
               "Hard Light\0" \
               "Soft Light\0" \
               "Color Dodge\0" \
               "Color Burn\0" \
               "Vivid Light\0" \
               "Acerola Light\0"; \
> = 1; \
\
uniform float AFX_BLEND_STRENGTH < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_min = 0.0f; ui_max = 1.0f; \
    ui_label = "Blend Strength"; \
    ui_type = "slider"; \
    ui_tooltip = "Adjust how strong the blending is."; \
> = 0.5f; \
\
uniform bool AFX_BLEND_SAMPLE_SKY < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_label = "Blend Sky"; \
    ui_tooltip = "Include sky in blend."; \
> = true; \
\
uniform float3 AFX_BLEND_COLOR < \
    ui_spacing = 5.0f; \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_min = 0.0f; ui_max = 1.0f; \
    ui_label = "Blend Color"; \
    ui_type = "color"; \
    ui_tooltip = "Color to blend with screen (if enabled)."; \
> = 1.0f; \
 \
uniform bool AFX_COLOR_BLEND < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_label = "Use Color"; \
    ui_tooltip = "Use color defined above to blend instead of the render."; \
> = false; \
 \
uniform int AFX_BLEND_TEXTURE < \
    ui_spacing = 5.0f; \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_type = "combo"; \
    ui_label = "Blend Texture"; \
    ui_items = "Paper\0" \
               "Watercolor\0" \
               "Custom Texture\0"; \
> = 1; \
\
uniform float AFX_TEXTURE_RES < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_min = 0.0f; ui_max = 5.0f; \
    ui_label = "Texture Resolution"; \
    ui_type = "drag"; \
    ui_tooltip = "Scaling of the blended texture."; \
> = 1.0f; \
\
uniform bool AFX_TEXTURE_BLEND < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_label = "Use Texture"; \
    ui_tooltip = "Use the texture to blend on to."; \
> = false; \
\
float4 AFX_SHADER_NAME(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { \
    float4 col = tex2D(Common::AcerolaBuffer, uv); \
    float3 a = saturate(col.rgb); \
    float3 b = AFX_COLOR_BLEND ? AFX_BLEND_COLOR : saturate(col.rgb); \
    bool skyMask = true; \
    float3 output = a; \
\
    if (AFX_COLOR_BLEND) \
        b = AFX_BLEND_COLOR; \
    if (AFX_TEXTURE_BLEND) \
        b = SampleBlendTex(AFX_BLEND_TEXTURE, position.xy * AFX_TEXTURE_RES); \
\
\
    if (!AFX_BLEND_SAMPLE_SKY) { \
        skyMask = ReShade::GetLinearizedDepth(uv) < 1.0f; \
    } \
\
    switch(AFX_BLEND_MODE) { \
        case 1: \
            output = a + b; \
        break; \
        case 2: \
            output = a * b; \
        break; \
        case 3: \
            output = 1.0f - (1.0f - a) * (1.0f - b); \
        break; \
        case 4: \
            output = (Common::Luminance(a) < 0.5) ? 2.0f * a * b : 1.0f - 2.0f * (1.0f - a) * (1.0f - b); \
        break; \
        case 5: \
            output = (Common::Luminance(b) < 0.5) ? 1.0f - 2.0f * (1.0f - a) * (1.0f - b) : 2.0f * a * b; \
        break; \
        case 6: \
            output = (Common::Luminance(b) < 0.5) ? 2.0f * a * b + (a * a) * (1.0f - 2.0f * b) : 2.0f * a * (1.0f - b) + sqrt(a) * (2.0f * b - 1.0f); \
        break; \
        case 7: \
            output = a / (1.0f - (b - 0.001f)); \
        break; \
        case 8: \
            output = 1.0f - ((1.0f - a) / (b + 0.001)); \
        break; \
        case 9: \
            output = (Common::Luminance(b) < 0.5) ? 1.0f - ((1.0f - a) / (2.0f * (b + 0.001f))) : a / (2.0f * (1.0f - (b - 0.001f))); \
        break; \
        case 10: \
            output = (Common::Luminance(b) < 0.5) ? 1.0f - ((1.0f - a) / (4.0f * (b + 0.001f))) - 0.25f : a / (4.0f * (1.0f - (b - 0.001f))) + 0.25; \
        break; \
    } \
\
    output = lerp(a, saturate(output), AFX_BLEND_STRENGTH * skyMask); \
\
    return float4(output, col.a); \
} \
\
technique AFX_TECHNIQUE_NAME <ui_label = AFX_TECHNIQUE_LABEL; ui_tooltip = "(LDR) Blends either a flat color or the render with itself using photoshop blend mode formulas."; > { \
    pass { \
        RenderTarget = AFXTemp1::AFX_RenderTex1; \
\
        VertexShader = PostProcessVS; \
        PixelShader = AFX_SHADER_NAME; \
    } \
\
    pass EndPass { \
        RenderTarget = Common::AcerolaBufferTex; \
\
        VertexShader = PostProcessVS; \
        PixelShader = PS_EndPass; \
    } \
} \
