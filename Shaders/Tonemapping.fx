#include "ReShade.fxh"
#include "Common.fxh"
uniform bool _DebugHDR <
    ui_label = "Debug HDR";
    ui_tooltip = "Check to see which colors are in high dynamic range (aka rgb clamped)";
> = false;

uniform int _Tonemapper <
    ui_type = "combo";
    ui_label = "Tonemapper";
    ui_items = "Hill ACES\0"
               "Narkowicz ACES\0";
> = 0;

static const float3x3 ACESInputMat = float3x3(
    float3(0.59719, 0.35458, 0.04823),
    float3(0.07600, 0.90834, 0.01566),
    float3(0.02840, 0.13383, 0.83777)
);

static const float3x3 ACESOutputMat = float3x3(
    float3( 1.60475, -0.53108, -0.07367),
    float3(-0.10208,  1.10813, -0.00605),
    float3(-0.00327, -0.07276,  1.07602)
);

float3 RRTAndODTFit(float3 v) {
    float3 a = v * (v + 0.0245786f) - 0.000090537f;
    float3 b = v * (0.983729f * v + 0.4329510f) + 0.238081f;
    return a / b;
}

float3 HillACES(float3 col) {
    col = mul(ACESInputMat, col);
    col = RRTAndODTFit(col);
    return mul(ACESOutputMat, col);
}

float3 NarkowiczACES(float3 col) {
    return (col * (2.51f * col + 0.03f)) / (col * (2.43f * col + 0.59f) + 0.14f);
}

texture2D ToneMapTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D ToneMap { Texture = ToneMapTex; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(ToneMap, uv).rgba; }

float4 PS_Tonemap(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(Common::AcerolaBuffer, uv).rgba;
    float UIMask = 1.0f - col.a;

    float3 output = col.rgb;

    if (_DebugHDR) {
        if (output.r > 1.0f || output.g > 1.0f || output.b > 1.0f) {
            return float4(output, 1.0f);
        }

        return 0.0f;
    }

    if (_Tonemapper == 0)
        output = HillACES(output);
    else if (_Tonemapper == 1)
        output = NarkowiczACES(output);

    return float4(lerp(col.rgb, output, UIMask), col.a);
}

technique Tonemapping  <ui_tooltip = "(HDR -> LDR) Converts all previous HDR passes into LDR."; >  {
    pass {
        RenderTarget = ToneMapTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Tonemap;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}