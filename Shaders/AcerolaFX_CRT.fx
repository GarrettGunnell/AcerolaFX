#include "AcerolaFX_Common.fxh"

uniform float _Curvature <
    ui_min = 1.0f; ui_max = 10.0f;
    ui_label = "Curvature";
    ui_type = "drag";
    ui_tooltip = "Controls the curvature of the corners of the screen.";
> = 10.0f;

uniform float _VignetteWidth <
    ui_min = 1.0f; ui_max = 100.0f;
    ui_label = "Vignette Width";
    ui_type = "drag";
    ui_tooltip = "Adjust width of the vignette.";
> = 30.0f;

uniform int _LineSize <
    ui_min = 0; ui_max = 4;
    ui_label = "Line Size";
    ui_type = "slider";
    ui_tooltip = "Adjust width of CRT lines by 2 ^ x.";
> = 0;

uniform float _LineStrength <
    ui_min = 1.0f; ui_max = 5.0f;
    ui_label = "Line Strength";
    ui_type = "drag";
    ui_tooltip = "Modify strength of the CRT lines.";
> = 1.0f;

uniform float _BrightnessAdjust <
    ui_min = -1.0f; ui_max = 1.0f;
    ui_label = "Brightness Adjust";
    ui_type = "drag";
    ui_tooltip = "Adjust brightness of the crt lines.";
> = 0.0f;

uniform bool _MaskUI <
    ui_label = "Mask UI";
    ui_tooltip = "Mask UI from crt effect.";
> = true;

texture2D CRTTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D CRT { Texture = CRTTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(CRT, uv).rgba; }

float4 PS_CRT(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float2 crtUV = uv * 2.0f - 1.0f;
    float2 offset = crtUV.yx / _Curvature;
    crtUV = crtUV + crtUV * offset * offset;
    crtUV = crtUV * 0.5f + 0.5f;

    float4 col = tex2D(Common::AcerolaBuffer, crtUV);
    float4 UI = tex2D(ReShade::BackBuffer, crtUV);

    float3 output = saturate(col.rgb);

    if (crtUV.x <= 0.0f || 1.0f <= crtUV.x || crtUV.y <= 0.0f || 1.0f <= crtUV.y)
        output = 0;

    crtUV = crtUV * 2.0f - 1.0f;
    float2 vignette = _VignetteWidth / float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    vignette = smoothstep(0.0f, vignette, 1.0f - abs(crtUV));
    vignette = saturate(vignette);

    output.g *= (sin(uv.y * (BUFFER_HEIGHT / exp2(_LineSize)) * 2.0f) + 1.0f) * 0.15f * _LineStrength + 1.0f + _BrightnessAdjust;
    output.rb *= (cos(uv.y * (BUFFER_HEIGHT / exp2(_LineSize)) * 2.0f) + 1.0f) * 0.135f * _LineStrength + 1.0f + _BrightnessAdjust; 

    output = saturate(output) * vignette.x * vignette.y;

    return float4(lerp(output.rgb, UI.rgb, UI.a * _MaskUI), col.a);
}

technique AFX_CRT  <ui_label = "CRT"; ui_tooltip = "(LDR) Makes the screen look like a CRT television."; >  {
    pass {
        RenderTarget = CRTTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_CRT;
    }

    pass End {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}