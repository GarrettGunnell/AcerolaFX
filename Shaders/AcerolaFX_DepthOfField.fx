#include "AcerolaFX_Common.fxh"
#include "AcerolaFX_BokehKernels.fxh"

uniform float _FocusDistance <
    ui_min = 0.01f; ui_max = 1.0f;
    ui_label = "Focus Distance";
    ui_type = "slider";
    ui_tooltip = "Adjust focusing plane.";
> = 10.0f;

uniform float _FocusRange <
    ui_min = 0.01f; ui_max = 10.0f;
    ui_label = "Focus Range";
    ui_type = "slider";
    ui_tooltip = "Adjust focusing range.";
> = 3.0f;

uniform int _BokehSize <
    ui_min = 0; ui_max = 4;
    ui_label = "Bokeh Size";
    ui_type = "slider";
    ui_tooltip = "Adjust bokeh kernel sample size (radius of blur).";
> = 4;

uniform int _SampleOffset <
    ui_min = 1; ui_max = 20;
    ui_label = "Bokeh Sample Offset";
    ui_type = "slider";
    ui_tooltip = "Adjust bokeh sample distance between pixels.";
> = 1;

texture2D DepthOfFieldTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D DepthOfField { Texture = DepthOfFieldTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(DepthOfField, uv).rgba; }

texture2D ConfusionTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R32F; }; 
sampler2D Confusion { Texture = ConfusionTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };

int GetSampleSize() {
    switch(_BokehSize) {
        case 1:
            return 16;
        case 2:
            return 22;
        case 3:
            return 43;
        case 4:
            return 71;
        default:
            return 1;
    }
}

float2 GetOffset(int i) {
    switch (_BokehSize) {
        case 1:
            return smallDiskKernel[i];
        case 2:
            return mediumDiskKernel[i];
        case 3:
            return largeDiskKernel[i];
        case 4:
            return veryLargeDiskKernel[i];
        default:
            return float2(0, 0);
    }
}


float PS_Confusion(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float depth = ReShade::GetLinearizedDepth(uv);

    return clamp((depth - _FocusDistance) / _FocusRange, -1, 1) * _SampleOffset;
}

float Weigh(float coc, float radius) {
    return saturate((coc - radius + 2) / 2);
}

float4 PS_Bokeh(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
    float coc = tex2D(Confusion, uv).r;

    float3 col = 0;
    float weight = 0;

    const int samples = GetSampleSize();
    for (int i = 0; i < samples; ++i) {
        float2 offset = GetOffset(i) * _SampleOffset;
        float radius = length(offset);
        offset *= texelSize;
        float coc = tex2D(Confusion, uv + offset).r;
        float sw = Weigh(abs(coc), radius);
        col += tex2D(Common::AcerolaBufferLinear, uv + offset).rgb * sw;
        weight += sw;
    }

    col *= 1.0f / weight;

    float4 originalCol = tex2D(Common::AcerolaBuffer, uv);

    return float4(lerp(originalCol.rgb, col, smoothstep(0.1, 1, abs(coc))), 1.0f);
}

technique AFX_DepthOfField < ui_label = "Depth Of Field"; ui_tooltip = "(HDR/LDR) Customize the focus of the screen."; > {
    pass {
        RenderTarget = ConfusionTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Confusion;
    }

    pass {
        RenderTarget = DepthOfFieldTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Bokeh;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}