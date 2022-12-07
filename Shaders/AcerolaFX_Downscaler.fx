#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_Downscales.fxh"

uniform bool _Point <
    ui_label = "Point Filter";
> = false;

#if AFX_NUM_DOWNSCALES == 2
 #define AFX_DownscaleTex DownScale::QuarterTex
#elif AFX_NUM_DOWNSCALES == 3
 #define AFX_DownscaleTex DownScale::EighthTex
#elif AFX_NUM_DOWNSCALES == 4
 #define AFX_DownscaleTex DownScale::SixteenthTex
#elif AFX_NUM_DOWNSCALES == 5
 #define AFX_DownscaleTex DownScale::ThirtySecondthTex
#elif AFX_NUM_DOWNSCALES == 6
 #define AFX_DownscaleTex DownScale::SixtyFourthTex
#elif AFX_NUM_DOWNSCALES == 7
 #define AFX_DownscaleTex DownScale::OneTwentyEighthTex
#elif AFX_NUM_DOWNSCALES == 8
 #define AFX_DownscaleTex DownScale::TwoFiftySixthTex
#else
 #define AFX_DownscaleTex DownScale::HalfTex
#endif

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