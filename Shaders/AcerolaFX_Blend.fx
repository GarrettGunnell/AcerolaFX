#include "AcerolaFX_Common.fxh"

uniform int _BlendMode <
    ui_type = "combo";
    ui_label = "Blend Mode";
    ui_tooltip = "Photoshop blend mode to use";
    ui_items = "No Blend\0"
               "Add\0"
               "Multiply\0"
               "Screen\0"
               "Overlay\0"
               "Hard Light\0"
               "Soft Light\0"
               "Color Dodge\0"
               "Color Burn\0"
               "Vivid Light\0"
               "Acerola Light\0";
> = 0;

uniform float3 _BlendColor <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Blend Color";
    ui_type = "color";
    ui_tooltip = "Color to blend with screen (if enabled).";
> = 1.0f;

uniform bool _ColorBlend <
    ui_label = "Use Color";
    ui_tooltip = "Use color defined above to blend instead of the render.";
> = false;

uniform float _Strength <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Blend Strength";
    ui_type = "slider";
    ui_tooltip = "Adjust how strong the blending is.";
> = 0.0f;

uniform bool _SampleSky <
    ui_label = "Blend Sky";
    ui_tooltip = "Include sky in blend.";
> = true;

texture2D BlendTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D Blend { Texture = BlendTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Blend, uv).rgba; }

float4 PS_Blend(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(Common::AcerolaBuffer, uv);
    float3 a = saturate(col.rgb);
    float3 b = _ColorBlend ? _BlendColor : saturate(col.rgb);

    bool skyMask = true;

    if (!_SampleSky) {
        skyMask = ReShade::GetLinearizedDepth(uv) < 1.0f;
    }

    float3 output = a; 
    
    switch(_BlendMode) {
        case 1:
            output = a + b;
        break;
        case 2:
            output = a * b;
        break;
        case 3:
            output = 1.0f - (1.0f - a) * (1.0f - b);
        break;
        case 4:
            output = (Common::Luminance(a) < 0.5) ? 2.0f * a * b : 1.0f - 2.0f * (1.0f - a) * (1.0f - b);
        break;
        case 5:
            output = (Common::Luminance(b) < 0.5) ? 1.0f - 2.0f * (1.0f - a) * (1.0f - b) : 2.0f * a * b;
        break;
        case 6:
            output = (Common::Luminance(b) < 0.5) ? 2.0f * a * b + (a * a) * (1.0f - 2.0f * b) : 2.0f * a * (1.0f - b) + sqrt(a) * (2.0f * b - 1.0f);
        break;
        case 7:
            output = a / (1.0f - (b - 0.001f));
        break;
        case 8:
            output = 1.0f - ((1.0f - a) / (b + 0.001));
        break;
        case 9:
            output = (Common::Luminance(b) < 0.5) ? 1.0f - ((1.0f - a) / (2.0f * (b + 0.001f))) : a / (2.0f * (1.0f - (b - 0.001f)));
        break;
        case 10:
            output = (Common::Luminance(b) < 0.5) ? 1.0f - ((1.0f - a) / (4.0f * (b + 0.001f))) - 0.25f : a / (4.0f * (1.0f - (b - 0.001f))) + 0.25;
        break;
    }

    output = lerp(a, saturate(output), _Strength * skyMask);

    return float4(output, col.a);
}

technique AFX_Blend <ui_label = "Blend"; ui_tooltip = "(LDR) Blends either a flat color or the render with itself using photoshop blend mode formulas."; > {
    pass {
        RenderTarget = BlendTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Blend;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}