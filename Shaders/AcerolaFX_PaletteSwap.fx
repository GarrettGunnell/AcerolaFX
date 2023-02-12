#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

#ifndef AFX_PALETTE_COUNT
    #define AFX_PALETTE_COUNT 4
#endif

#if AFX_PALETTE_COUNT > 0
uniform float3 _Color1 <
    ui_label = "Color 1";
    ui_type = "color";
> = float3(1.0, 1.0, 1.0);
#endif

#if AFX_PALETTE_COUNT > 1
uniform float3 _Color2 <
    ui_label = "Color 2";
    ui_type = "color";
> = float3(1.0, 1.0, 1.0);
#endif

#if AFX_PALETTE_COUNT > 2
uniform float3 _Color3 <
    ui_label = "Color 3";
    ui_type = "color";
> = float3(1.0, 1.0, 1.0);
#endif

#if AFX_PALETTE_COUNT > 3
uniform float3 _Color4 <
    ui_label = "Color 4";
    ui_type = "color";
> = float3(1.0, 1.0, 1.0);
#endif

texture2D AFX_Palette1 < source = "palette1.png"; > { Width = 4; Height = 1; Format = RGBA8; }; 
sampler2D Palette1 { Texture = AFX_Palette1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
sampler2D PaletteSwap { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(PaletteSwap, uv).rgba; }

float4 PS_PaletteSwap(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float newUV = saturate(tex2D(Common::AcerolaBuffer, uv).r);

    int paletteIndex = floor(newUV * AFX_PALETTE_COUNT) + 1;
    if (newUV == 1)
        paletteIndex = AFX_PALETTE_COUNT;

    float3 color = 0;

    switch (paletteIndex) {
#if AFX_PALETTE_COUNT > 0
        case 1:
            color = _Color1;
        break;
#endif
#if AFX_PALETTE_COUNT > 1
        case 2:
            color = _Color2;
        break;
#endif
#if AFX_PALETTE_COUNT > 2
        case 3:
            color = _Color3;
        break;
#endif
#if AFX_PALETTE_COUNT > 3
        case 4:
            color = _Color4;
        break;
#endif
        default:
        break;
    }

    return float4(color, 1.0f);
}

technique AFX_PaletteSwap < ui_label = "PaletteSwap"; ui_tooltip = "."; > {
    pass {
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_PaletteSwap;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}