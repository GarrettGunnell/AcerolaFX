#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"
#include "Includes/AcerolaFX_Downscales.fxh"

uniform bool _Point <
    ui_label = "Point Filter";
> = false;

#ifndef AFX_DOWNSCALE_FACTOR
    #define AFX_DOWNSCALE_FACTOR 0
#endif

#if AFX_DOWNSCALE_FACTOR == 1
 #define AFX_DownscaleTex DownScale::HalfTex
#elif AFX_DOWNSCALE_FACTOR == 2
 #define AFX_DownscaleTex DownScale::QuarterTex
#elif AFX_DOWNSCALE_FACTOR == 3
 #define AFX_DownscaleTex DownScale::EighthTex
#elif AFX_DOWNSCALE_FACTOR == 4
 #define AFX_DownscaleTex DownScale::SixteenthTex
#elif AFX_DOWNSCALE_FACTOR == 5
 #define AFX_DownscaleTex DownScale::ThirtySecondthTex
#elif AFX_DOWNSCALE_FACTOR == 6
 #define AFX_DownscaleTex DownScale::SixtyFourthTex
#elif AFX_DOWNSCALE_FACTOR == 7
 #define AFX_DownscaleTex DownScale::OneTwentyEighthTex
#elif AFX_DOWNSCALE_FACTOR == 8
 #define AFX_DownscaleTex DownScale::TwoFiftySixthTex
#else
 #define AFX_DownscaleTex AFXTemp1::AFX_RenderTex1
#endif

texture2D AFX_RenderTex1 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler2D DownscalePoint { Texture = AFX_DownscaleTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
sampler2D Downscale { Texture = AFX_DownscaleTex; };
float4 PS_Downscale(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Common::AcerolaBuffer, uv); }
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { 
    if (_Point) return tex2D(DownscalePoint, uv);
    
    return tex2D(Downscale, uv);
}

technique AFX_Downscaler < ui_label = "Downscaler"; ui_tooltip = "(HDR) Downscale the render."; > {
    pass {
        RenderTarget = AFX_DownscaleTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Downscale;
    }

    pass End {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}