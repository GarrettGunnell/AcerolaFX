#include "ReShade.fxh"
#include "Common.fxh"

uniform int _BlendMode <
    ui_type = "combo";
    ui_label = "Blend Mode";
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
               "Acerola Secret Sauce\0";
> = 0;

uniform float3 _BlendColor <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Blend Color";
    ui_type = "color";
    ui_tooltip = "Color to blend with screen (if enabled).";
> = 1.0f;

uniform bool _ColorBlend <
    ui_label = "Use Color";
    ui_tooltip = "Use color defined above to blend instead of the render";
> = false;

uniform float _Strength <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Blend Strength";
    ui_type = "slider";
    ui_tooltip = "Adjust how strong the blending is";
> = 0.0f;

texture2D BlendTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D Blend { Texture = BlendTex; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Blend, uv).rgba; }

float4 PS_Blend(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(Common::AcerolaBuffer, uv);
    float3 a = saturate(col.rgb);
    float3 b = _ColorBlend ? _BlendColor : saturate(col.rgb);

    float3 output = a; 
    if (_BlendMode == 1)
        output = a + b;
    else if (_BlendMode == 2)
        output = a * b;
    else if (_BlendMode == 3)
        output = 1.0f - (1.0f - a) * (1.0f - b);
    else if (_BlendMode == 4)
        output = (Common::Luminance(a) < 0.5) ? 2.0f * a * b : 1.0f - 2.0f * (1.0f - a) * (1.0f - b);
    else if (_BlendMode == 5)
        output = (Common::Luminance(b) < 0.5) ? 1.0f - 2.0f * (1.0f - a) * (1.0f - b) : 2.0f * a * b;
    else if (_BlendMode == 6)
        output = (Common::Luminance(b) < 0.5) ? 2.0f * a * b + (a * a) * (1.0f - 2.0f * b) : 2.0f * a * (1.0f - b) + sqrt(a) * (2.0f * b - 1.0f);
    else if (_BlendMode == 7)
        output = a / (1.0f - (b - 0.001f));
    else if (_BlendMode == 8)
        output = 1.0f - ((1.0f - a) / (b + 0.001));
    else if (_BlendMode == 9)
        output = (Common::Luminance(b) < 0.5) ? 1.0f - ((1.0f - a) / (2.0f * (b + 0.001f))) : a / (2.0f * (1.0f - (b - 0.001f)));
    else if (_BlendMode == 10)
        output = (Common::Luminance(b) < 0.5) ? 1.0f - ((1.0f - a) / (4.0f * (b + 0.001f))) - 0.25f : a / (4.0f * (1.0f - (b - 0.001f))) + 0.25;

    output = lerp(a, saturate(output), _Strength);

    return float4(lerp(output, col.rgb, col.a), col.a);
}

technique Blend <ui_tooltip = "(LDR) Blends either a flat color or the render with itself using photoshop blend mode formulas."; > {
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