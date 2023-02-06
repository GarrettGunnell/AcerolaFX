#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

uniform float3 _VignetteColor <
    ui_type = "color";
    ui_label = "Vignette Color";
> = 0.0f;

uniform float2 _VignetteSize <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Vignette Size";
    ui_type = "drag";
    ui_tooltip = "Size of the vignette axes.";
> = 1.0f;

uniform float2 _VignetteOffset <
    ui_min = -1.0f; ui_max = 1.0f;
    ui_label = "Vignette Offset";
    ui_type = "drag";
    ui_tooltip = "Positional offset of the vignette from the center of the screen.";
> = 0.0f;

uniform float _Intensity <
    ui_min = 0f; ui_max = 5.0f;
    ui_label = "Intensity";
    ui_type = "slider";
    ui_tooltip = "Adjust how intense the offset is.";
> = 1.0f;

uniform float _Roundness <
    ui_min = 0f; ui_max = 10.0f;
    ui_label = "Roundness";
    ui_type = "slider";
    ui_tooltip = "Adjust how smooth the intensity change is from the center of the screen.";
> = 1.0f;

uniform float _Smoothness <
    ui_min = 0.01f; ui_max = 2.0f;
    ui_label = "Smoothness";
    ui_type = "slider";
    ui_tooltip = "Adjust how much each color channel should be offset.";
> = 1.0f;

sampler2D Vignette { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Vignette, uv).rgba; }

float4 PS_Vignette(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(Common::AcerolaBuffer, uv).rgba;
    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

    float2 pos = uv - 0.5f;
    pos *= _VignetteSize;
    pos += 0.5f;

    float2 d = abs(pos - (float2(0.5f, 0.5f) + _VignetteOffset)) * _Intensity;
    d = pow(saturate(d), _Roundness);
    float vfactor = pow(saturate(1.0f - dot(d, d)), _Smoothness);

    return float4(lerp(_VignetteColor, col.rgb, vfactor), 1.0f);
}

technique AFX_Vignette < ui_label = "Vignette"; ui_tooltip = "Apply a cinematic gradient border to the screen."; > {
    pass {
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_Vignette;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}