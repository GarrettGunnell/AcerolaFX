#include "ReShade.fxh"
#include "Common.fxh"

uniform float _Sharpness <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Sharpness";
    ui_type = "drag";
    ui_tooltip = "Adjust sharpnening";
> = 1.0f;

texture2D SharpnessTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D Sharpness { Texture = SharpnessTex; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Sharpness, uv).rgba; }

float4 PS_Sharpness(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(Common::AcerolaBuffer, uv);
    float UIMask = 1.0f - col.a;

    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
    float neighbor = _Sharpness * -1;
    float center = _Sharpness * 4 + 1;

    float4 n = tex2D(Common::AcerolaBuffer, uv + texelSize * float2(0, 1));
    float4 e = tex2D(Common::AcerolaBuffer, uv + texelSize * float2(1, 0));
    float4 s = tex2D(Common::AcerolaBuffer, uv + texelSize * float2(0, -1));
    float4 w = tex2D(Common::AcerolaBuffer, uv + texelSize * float2(-1, 0));

    float4 output = n * neighbor + e * neighbor + col * center + s * neighbor + w * neighbor;

    UIMask = max(0.0f, 1.0f - col.a - output.a);

    return float4(lerp(col.rgb, output.rgb, UIMask), col.a);
}

technique Sharpness {
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