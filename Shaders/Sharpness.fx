#include "ReShade.fxh"
#include "Common.fxh"

uniform float _Sharpness <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Sharpness";
    ui_type = "drag";
    ui_tooltip = "Adjust sharpening";
> = 3.0f;

uniform float _SharpnessFalloff <
    ui_min = 0.0f; ui_max = 0.01f;
    ui_label = "Fog Density";
    ui_type = "slider";
    ui_tooltip = "Adjust sharpness fall off. (0 is no falloff)";
> = 0.009f;

uniform float _Offset <
    ui_min = 0.0f; ui_max = 1000.0f;
    ui_label = "Fog Offset";
    ui_type = "slider";
    ui_tooltip = "Offset distance at which sharpness falloff occurs";
> = 200.0f;

texture2D SharpnessTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D Sharpness { Texture = SharpnessTex; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Sharpness, uv).rgba; }

float4 PS_Sharpness(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = saturate(tex2D(Common::AcerolaBuffer, uv));

    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
    float neighbor = _Sharpness * -1;
    float center = _Sharpness * 4 + 1;

    float4 n = saturate(tex2D(Common::AcerolaBuffer, uv + texelSize * float2(0, 1)));
    float4 e = saturate(tex2D(Common::AcerolaBuffer, uv + texelSize * float2(1, 0)));
    float4 s = saturate(tex2D(Common::AcerolaBuffer, uv + texelSize * float2(0, -1)));
    float4 w = saturate(tex2D(Common::AcerolaBuffer, uv + texelSize * float2(-1, 0)));

    float4 output = n * neighbor + e * neighbor + col * center + s * neighbor + w * neighbor;

    float depth = ReShade::GetLinearizedDepth(uv);
    float viewDistance = depth * 1000.0f;

    float fallOffFactor = (_SharpnessFalloff / log(2)) * max(0.0f, viewDistance - _Offset);
    fallOffFactor = exp2(-fallOffFactor);

    output = saturate(lerp(col, output, saturate(fallOffFactor)));

    float UIMask = max(0.0f, 1.0f - col.a - output.a);

    return float4(lerp(col.rgb, output.rgb, UIMask), col.a);
}

technique Sharpness <ui_tooltip = "(LDR) Increases the contrast between edges to create the illusion of high detail."; > {
    pass {
        RenderTarget = SharpnessTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Sharpness;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}