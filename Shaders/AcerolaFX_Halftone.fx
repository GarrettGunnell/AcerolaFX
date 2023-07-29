#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"
#include "Includes/AcerolaFX_TempTex2.fxh"

uniform bool _PrintCyan <
    ui_category_closed = true;
    ui_category = "Cyan";
    ui_label = "Print";
    ui_tooltip = "Draw cyan or not.";
> = true;

uniform float _CyanDotSize <
    ui_min = 0.0f; ui_max = 3.0f;
    ui_category_closed = true;
    ui_category = "Cyan";
    ui_type = "drag";
    ui_label = "Dot Size";
    ui_tooltip = "Size of cyan dots.";
> = 1.0f;

uniform float _CyanBias <
    ui_min = -2.0f; ui_max = 2.0f;
    ui_category_closed = true;
    ui_category = "Cyan";
    ui_type = "drag";
    ui_label = "Bias";
    ui_tooltip = "Additive modifier on cyan value.";
> = 0.0f;

uniform float _CyanExponent <
    ui_min = -10.0f; ui_max = 10.0f;
    ui_category_closed = true;
    ui_category = "Cyan";
    ui_type = "drag";
    ui_label = "Exponent";
    ui_tooltip = "Exponent on the value to bring darker values down.";
> = 1.0f;

uniform float2 _CyanOffset <
    ui_category_closed = true;
    ui_category = "Cyan";
    ui_type = "drag";
    ui_label = "Offset";
    ui_tooltip = "Offset the dots.";
> = 0.0f;

uniform bool _PrintMagenta <
    ui_category_closed = true;
    ui_category = "Magenta";
    ui_label = "Print";
    ui_tooltip = "Draw Magenta or not.";
> = true;

uniform float _MagentaDotSize <
    ui_min = 0.0f; ui_max = 3.0f;
    ui_category_closed = true;
    ui_category = "Magenta";
    ui_type = "drag";
    ui_label = "Dot Size";
    ui_tooltip = "Size of Magenta dots.";
> = 1.0f;

uniform float _MagentaBias <
    ui_min = -2.0f; ui_max = 2.0f;
    ui_category_closed = true;
    ui_category = "Magenta";
    ui_type = "drag";
    ui_label = "Bias";
    ui_tooltip = "Additive modifier on Magenta value.";
> = 0.0f;

uniform float _MagentaExponent <
    ui_min = -10.0f; ui_max = 10.0f;
    ui_category_closed = true;
    ui_category = "Magenta";
    ui_type = "drag";
    ui_label = "Exponent";
    ui_tooltip = "Exponent on the value to bring darker values down.";
> = 1.0f;

uniform float2 _MagentaOffset <
    ui_category_closed = true;
    ui_category = "Magenta";
    ui_type = "drag";
    ui_label = "Offset";
    ui_tooltip = "Offset the dots.";
> = 0.0f;

uniform bool _PrintYellow <
    ui_category_closed = true;
    ui_category = "Yellow";
    ui_label = "Print";
    ui_tooltip = "Draw Yellow or not.";
> = true;

uniform float _YellowDotSize <
    ui_min = 0.0f; ui_max = 3.0f;
    ui_category_closed = true;
    ui_category = "Yellow";
    ui_type = "drag";
    ui_label = "Dot Size";
    ui_tooltip = "Size of Yellow dots.";
> = 1.0f;

uniform float _YellowBias <
    ui_min = -2.0f; ui_max = 2.0f;
    ui_category_closed = true;
    ui_category = "Yellow";
    ui_type = "drag";
    ui_label = "Bias";
    ui_tooltip = "Additive modifier on Yellow value.";
> = 0.0f;

uniform float _YellowExponent <
    ui_min = -10.0f; ui_max = 10.0f;
    ui_category_closed = true;
    ui_category = "Yellow";
    ui_type = "drag";
    ui_label = "Exponent";
    ui_tooltip = "Exponent on the value to bring darker values down.";
> = 1.0f;

uniform float2 _YellowOffset <
    ui_category_closed = true;
    ui_category = "Yellow";
    ui_type = "drag";
    ui_label = "Offset";
    ui_tooltip = "Offset the dots.";
> = 0.0f;

uniform bool _PrintBlack <
    ui_category_closed = true;
    ui_category = "Black";
    ui_label = "Print";
    ui_tooltip = "Draw Black or not.";
> = true;

uniform float _BlackDotSize <
    ui_min = 0.0f; ui_max = 3.0f;
    ui_category_closed = true;
    ui_category = "Black";
    ui_type = "drag";
    ui_label = "Dot Size";
    ui_tooltip = "Size of Black dots.";
> = 1.0f;

uniform float _BlackBias <
    ui_min = -2.0f; ui_max = 2.0f;
    ui_category_closed = true;
    ui_category = "Black";
    ui_type = "drag";
    ui_label = "Bias";
    ui_tooltip = "Additive modifier on Black value.";
> = 0.0f;

uniform float _BlackExponent <
    ui_min = -10.0f; ui_max = 10.0f;
    ui_category_closed = true;
    ui_category = "Black";
    ui_type = "drag";
    ui_label = "Exponent";
    ui_tooltip = "Exponent on the value to bring darker values down.";
> = 1.0f;

uniform float2 _BlackOffset <
    ui_category_closed = true;
    ui_category = "Black";
    ui_type = "drag";
    ui_label = "Offset";
    ui_tooltip = "Offset the dots.";
> = 0.0f;


sampler2D Offset { Texture = AFXTemp2::AFX_RenderTex2; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
sampler2D Halftone { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Offset, uv).rgba; }

float halftone(float2 uv, float v, float bias, float dotSize, float curve) {
    float halftone = (sin(uv.x * BUFFER_WIDTH * dotSize) + sin(uv.y * BUFFER_HEIGHT * dotSize)) / 2.0f;

    return halftone < pow(saturate(v + bias), curve);
}

float4 PS_Halftone(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = saturate(tex2D(Common::AcerolaBuffer, uv).rgba);
    float r = col.r;
    float g = col.g;
    float b = col.b;
    float k = min(1.0f - r, min(1.0f - g, 1.0f - b));
    float3 cmy = 0.0f;
    float invK = 1.0f - k;

    if (invK != 0.0f) {
        cmy.r = (1.0f - r - k) / invK;
        cmy.g = (1.0f - g - k) / invK;
        cmy.b = (1.0f - b - k) / invK;
    }

    // Cyan
    float2x2 R = float2x2(cos(0.261799), -sin(0.261799), sin(0.261799), cos(0.261799));
    cmy.r = halftone(mul(uv, R), cmy.r, _CyanBias, _CyanDotSize, _CyanExponent);

    // Magenta
    R = float2x2(cos(1.309), -sin(1.309), sin(1.309), cos(1.309));
    cmy.g = halftone(mul(uv, R), cmy.g, _MagentaBias, _MagentaDotSize, _MagentaExponent);

    // Yellow
    cmy.b = halftone(uv, cmy.b, _YellowBias, _YellowDotSize, _YellowExponent);

    // Black
    R = float2x2(cos(0.785398), -sin(0.785398), sin(0.785398), cos(0.785398));
    k = halftone(mul(uv, R), k, _BlackBias, _BlackDotSize, _BlackExponent);

    //return 1.0f;
    return float4(cmy, k);
}

float4 PS_Offset(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float c = tex2D(Halftone, uv + _CyanOffset * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).r;
    float m = tex2D(Halftone, uv + _MagentaOffset * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).g;
    float y = tex2D(Halftone, uv + _YellowOffset * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).b;
    float k = tex2D(Halftone, uv + _BlackOffset * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).a;

    float3 output = 1.0f;
    output.r -= c * _PrintCyan;
    output.g -= m * _PrintMagenta;
    output.b -= y * _PrintYellow;

    return float4(saturate(output - k * _PrintBlack), 1.0f);
}

technique AFX_Halftone < ui_label = "Halftone"; ui_tooltip = "(LDR) Adjusts the gamma correction of the screen."; > {
    pass {
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_Halftone;
    }

    pass {
        RenderTarget = AFXTemp2::AFX_RenderTex2;

        VertexShader = PostProcessVS;
        PixelShader = PS_Offset;
    }


    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}