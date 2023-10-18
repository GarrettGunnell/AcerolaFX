#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

#ifndef AFX_ZOOM_COUNT
 #define AFX_ZOOM_COUNT 0
#endif

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
sampler2D Zoom { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
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
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_Zoom;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}

#define AFX_ZOOM_SHADOW_CLONE(AFX_TECHNIQUE_NAME, AFX_TECHNIQUE_LABEL, AFX_VARIABLE_CATEGORY, AFX_ZOOM, AFX_OFFSET, AFX_POINT_FILTER, AFX_SAMPLE_MODE, AFX_SHADER_NAME) \
uniform float AFX_ZOOM < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_min = 0.0f; ui_max = 5.0f; \
    ui_label = "Zoom"; \
    ui_type = "drag"; \
    ui_tooltip = "Decrease to zoom in, increase to zoom out."; \
> = 1.0f; \
\
uniform float2 AFX_OFFSET < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_min = -1.0f; ui_max = 1.0f; \
    ui_label = "Offset"; \
    ui_type = "drag"; \
    ui_tooltip = "Positional offset of the zoom from the center."; \
> = 0.0f; \
\
uniform bool AFX_POINT_FILTER < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_label = "Point Filter"; \
    ui_tooltip = "Do you want it blurry or crispy?"; \
> = true; \
\
uniform int AFX_SAMPLE_MODE < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_type = "combo"; \
    ui_label = "Sample Mode"; \
    ui_tooltip = "How to handle out of bounds positions (for zooming out)."; \
    ui_items = "Clamp\0" \
               "Mirror\0" \
               "Wrap\0" \
               "Repeat\0" \
               "Border\0"; \
> = 0; \
\
float4 AFX_SHADER_NAME(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { \
    float2 zoomUV = uv * 2 - 1; \
    zoomUV += float2(-AFX_OFFSET.x, AFX_OFFSET.y) * 2; \
    zoomUV *= AFX_ZOOM; \
    zoomUV = zoomUV / 2 + 0.5f; \
\
    if (AFX_SAMPLE_MODE == 0) { \
        if (AFX_POINT_FILTER) \
            return tex2D(Common::AcerolaBuffer, zoomUV); \
        else \
            return tex2D(Common::AcerolaBufferLinear, zoomUV); \
    } else if (AFX_SAMPLE_MODE == 1) { \
        if (AFX_POINT_FILTER) \
            return tex2D(Common::AcerolaBufferMirror, zoomUV); \
        else \
            return tex2D(Common::AcerolaBufferMirrorLinear, zoomUV); \
    } else if (AFX_SAMPLE_MODE == 2) { \
        if (AFX_POINT_FILTER) \
            return tex2D(Common::AcerolaBufferWrap, zoomUV); \
        else \
            return tex2D(Common::AcerolaBufferWrapLinear, zoomUV); \
    } else if (AFX_SAMPLE_MODE == 3) { \
        if (AFX_POINT_FILTER) \
            return tex2D(Common::AcerolaBufferRepeat, zoomUV); \
        else \
            return tex2D(Common::AcerolaBufferRepeatLinear, zoomUV); \
    } else { \
        if (AFX_POINT_FILTER) \
            return tex2D(Common::AcerolaBufferBorder, zoomUV); \
        else \
            return tex2D(Common::AcerolaBufferBorderLinear, zoomUV); \
\
    } \
} \
\
technique AFX_TECHNIQUE_NAME < ui_label = AFX_TECHNIQUE_LABEL; ui_tooltip = "(LDR) Adjusts the Zoom correction of the screen."; > { \
    pass { \
        RenderTarget = AFXTemp1::AFX_RenderTex1; \
\
        VertexShader = PostProcessVS; \
        PixelShader = AFX_SHADER_NAME; \
    } \
\
    pass EndPass { \
        RenderTarget = Common::AcerolaBufferTex; \
\
        VertexShader = PostProcessVS; \
        PixelShader = PS_EndPass; \
    } \
} \

#if AFX_ZOOM_COUNT > 0
    AFX_ZOOM_SHADOW_CLONE(AFX_Zoom2, "Zoom 2", "Zoom 2 Settings", _Zoom2, _ZoomOffset2, _ZoomPointFilter2, _ZoomSampleMode2, PS_Zoom2)
#endif

#if AFX_ZOOM_COUNT > 1
    AFX_ZOOM_SHADOW_CLONE(AFX_Zoom3, "Zoom 3", "Zoom 3 Settings", _Zoom3, _ZoomOffset3, _ZoomPointFilter3, _ZoomSampleMode3, PS_Zoom3)
#endif

#if AFX_ZOOM_COUNT > 2
    AFX_ZOOM_SHADOW_CLONE(AFX_Zoom4, "Zoom 4", "Zoom 4 Settings", _Zoom4, _ZoomOffset4, _ZoomPointFilter4, _ZoomSampleMode4, PS_Zoom4)
#endif

#if AFX_ZOOM_COUNT > 3
    AFX_ZOOM_SHADOW_CLONE(AFX_Zoom5, "Zoom 5", "Zoom 5 Settings", _Zoom5, _ZoomOffset5, _ZoomPointFilter5, _ZoomSampleMode5, PS_Zoom5)
#endif

#if AFX_ZOOM_COUNT > 4
    AFX_ZOOM_SHADOW_CLONE(AFX_Zoom6, "Zoom 6", "Zoom 6 Settings", _Zoom6, _ZoomOffset6, _ZoomPointFilter6, _ZoomSampleMode6, PS_Zoom6)
#endif

#if AFX_ZOOM_COUNT > 5
    AFX_ZOOM_SHADOW_CLONE(AFX_Zoom7, "Zoom 7", "Zoom 7 Settings", _Zoom7, _ZoomOffset7, _ZoomPointFilter7, _ZoomSampleMode7, PS_Zoom7)
#endif

#if AFX_ZOOM_COUNT > 6
    AFX_ZOOM_SHADOW_CLONE(AFX_Zoom8, "Zoom 8", "Zoom 8 Settings", _Zoom8, _ZoomOffset8, _ZoomPointFilter8, _ZoomSampleMode8, PS_Zoom8)
#endif