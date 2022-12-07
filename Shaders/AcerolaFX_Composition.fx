#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

uniform uint _Fraction <
	ui_type = "slider";
	ui_label = "Fraction";
    ui_tooltip = "Fraction to divide the screen into.";
	ui_min = 1; ui_max = 5;
> = 3;


sampler2D Composition { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Composition, uv).rgba; }

float4 PS_Composition(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = saturate(tex2D(Common::AcerolaBuffer, uv).rgba);

    float aspect = BUFFER_WIDTH / BUFFER_HEIGHT;
    float fractionX = BUFFER_WIDTH / _Fraction;
    float fractionY = BUFFER_HEIGHT / _Fraction;

    if ((position.x % fractionX < 1 || position.y % fractionY < 1) && all(position.xy > 1)) {
        col = 1 - col;
    }

    return col;
}

technique AFX_Composition < ui_label = "Composition"; ui_tooltip = "Overlay fraction lines to help with shot composition."; > {
    pass {
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_Composition;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}