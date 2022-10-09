#include "AcerolaFX_Common.fxh"

uniform float _Zoom <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Zoom";
    ui_type = "drag";
    ui_tooltip = "Decrease to zoom in, increase to zoom out.";
> = 1.0f;

uniform float2 _Offset <
    ui_min = -1.0f; ui_max = 1.0f;
    ui_label = "Offset";
    ui_type = "drag";
    ui_tooltip = "Positional offset of the zoom from the center.";
> = 0.0f;

uniform bool _PointFilter <
    ui_label = "Point Filter";
    ui_tooltip = "Do you want it blurry or crispy?";
> = true;

uniform int _SampleMode <
    ui_type = "combo";
    ui_label = "Sample Mode";
    ui_tooltip = "How to handle out of bounds positions (for zooming out).";
    ui_items = "Clamp\0"
               "Mirror\0"
               "Wrap\0"
               "Repeat\0"
               "Border\0";
> = 0;

texture2D AFX_ZoomTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D Zoom { Texture = AFX_ZoomTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Zoom, uv).rgba; }


float4 PS_Zoom(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float2 zoomUV = uv * 2 - 1;
    zoomUV += float2(-_Offset.x, _Offset.y) * 2;
    zoomUV *= _Zoom;
    zoomUV = zoomUV / 2 + 0.5f;
    
    if (_SampleMode == 0) {
        if (_PointFilter)
            return tex2D(Common::AcerolaBuffer, zoomUV);
        else
            return tex2D(Common::AcerolaBufferLinear, zoomUV);
    } else if (_SampleMode == 1) {
        if (_PointFilter)
            return tex2D(Common::AcerolaBufferMirror, zoomUV);
        else
            return tex2D(Common::AcerolaBufferMirrorLinear, zoomUV);
    } else if (_SampleMode == 2) {
        if (_PointFilter)
            return tex2D(Common::AcerolaBufferWrap, zoomUV);
        else
            return tex2D(Common::AcerolaBufferWrapLinear, zoomUV);
    } else if (_SampleMode == 3) {
        if (_PointFilter)
            return tex2D(Common::AcerolaBufferRepeat, zoomUV);
        else
            return tex2D(Common::AcerolaBufferRepeatLinear, zoomUV);
    } else {
        if (_PointFilter)
            return tex2D(Common::AcerolaBufferBorder, zoomUV);
        else
            return tex2D(Common::AcerolaBufferBorderLinear, zoomUV);

    }
}

technique AFX_Zoom < ui_label = "Zoom"; ui_tooltip = "(LDR) Adjusts the Zoom correction of the screen."; > {
    pass {
        RenderTarget = AFX_ZoomTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Zoom;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}