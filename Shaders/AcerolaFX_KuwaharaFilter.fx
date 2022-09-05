#include "AcerolaFX_Common.fxh"

uniform int _Filter <
    ui_type = "combo";
    ui_label = "Filter Type";
    ui_items = "Basic\0"
               "Generalized\0";
    ui_tooltip = "Which extension of the kuwahara filter?";
> = 0;

uniform int _KernelSize <
    ui_min = 0; ui_max = 20;
    ui_type = "slider";
    ui_label = "Radius";
    ui_tooltip = "Size of the kuwahara filter kernel";
> = 1;

texture2D KuwaharaFilterTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D KuwaharaFilter { Texture = KuwaharaFilterTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(KuwaharaFilter, uv).rgba; }

float4 SampleQuadrant(float2 uv, int x1, int x2, int y1, int y2, float n) {
    float luminanceSum = 0.0f;
    float luminanceSum2 = 0.0f;
    float3 colSum = 0.0f;

    for (int x = x1; x <= x2; ++x) {
        for (int y = y1; y <= y2; ++y) {
            float3 c = tex2D(Common::AcerolaBuffer, uv + float2(x, y) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).rgb;
            float l = Common::Luminance(c);
            luminanceSum += l;
            luminanceSum2 += l * l;
            colSum += c;
        }
    }

    float mean = luminanceSum / n;
    float stdev = abs(luminanceSum2 / n - mean * mean);

    return float4(colSum / n, stdev);
}

void Basic(in float2 uv, out float4 output) {
    float windowSize = 2.0f * _KernelSize + 1;
    int quadrantSize = int(ceil(windowSize / 2.0f));
    int numSamples = quadrantSize * quadrantSize;

    float4 q1 = SampleQuadrant(uv, -_KernelSize, 0, -_KernelSize, 0, numSamples);
    float4 q2 = SampleQuadrant(uv, 0, _KernelSize, -_KernelSize, 0, numSamples);
    float4 q3 = SampleQuadrant(uv, 0, _KernelSize, 0, _KernelSize, numSamples);
    float4 q4 = SampleQuadrant(uv, -_KernelSize, 0, 0, _KernelSize, numSamples);

    float minstd = min(q1.a, min(q2.a, min(q3.a, q4.a)));
    int4 q = float4(q1.a, q2.a, q3.a, q4.a) == minstd;

    if (dot(q, 1) > 1)
        output = float4((q1.rgb + q2.rgb + q3.rgb + q4.rgb) / 4.0f, 1.0f);
    else
        output = float4(q1.rgb * q.x + q2.rgb * q.y + q3.rgb * q.z + q4.rgb * q.w, 1.0f);
}

float4 PS_KuwaharaFilter(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 output = 0;
    
    if (_Filter == 0)
        Basic(uv, output);

    return output;
}

technique AFX_KuwaharaFilter < ui_label = "Kuwahara Filter"; ui_tooltip = "(LDR) Applies a Kuwahara filter to the screen."; > {
    pass {
        RenderTarget = KuwaharaFilterTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_KuwaharaFilter;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}