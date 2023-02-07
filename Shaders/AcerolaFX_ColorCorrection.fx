#include "Includes/AcerolaFX_ColorCorrection.fxh"

#ifndef AFX_CORRECT_COUNT
 #define AFX_CORRECT_COUNT 0
#endif

uniform bool _HDR <
    ui_category = "Color Correct 1 Settings";
    ui_category_closed = true;
    ui_label = "HDR";
    ui_tooltip = "Enable HDR (Color values can exceed 1).";
> = true;

uniform float _Exposure <
    ui_category = "Color Correct 1 Settings";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Exposure";
    ui_type = "drag";
    ui_tooltip = "Adjust camera exposure.";
> = 1.0f;

uniform float _Temperature <
    ui_category = "Color Correct 1 Settings";
    ui_category_closed = true;
    ui_min = -1.0f; ui_max = 1.0f;
    ui_label = "Temperature";
    ui_type = "drag";
    ui_tooltip = "Adjust white balancing temperature.";
> = 0.0f;

uniform float _Tint <
    ui_category = "Color Correct 1 Settings";
    ui_category_closed = true;
    ui_min = -1.0f; ui_max = 1.0f;
    ui_label = "Tint";
    ui_type = "drag";
    ui_tooltip = "Adjust white balance color tint.";
> = 0.0f;

uniform float3 _Contrast <
    ui_category = "Color Correct 1 Settings";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Contrast";
    ui_type = "drag";
    ui_tooltip = "Adjust contrast.";
> = 1.0f;

uniform float3 _LinearMidPoint <
    ui_category = "Color Correct 1 Settings";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Linear Mid Point";
    ui_type = "drag";
    ui_tooltip = "Adjust the midpoint value between black and fully saturated for contrast.";
> = 0.5f;

uniform float3 _Brightness <
    ui_category = "Color Correct 1 Settings";
    ui_category_closed = true;
    ui_min = -5.0f; ui_max = 5.0f;
    ui_label = "Brightness";
    ui_type = "drag";
    ui_tooltip = "Adjust brightness of each color channel.";
> = float3(0.0, 0.0, 0.0);

uniform float3 _ColorFilter <
    ui_category = "Color Correct 1 Settings";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Color Filter";
    ui_type = "color";
    ui_tooltip = "Set color filter (white for no change).";
> = float3(1.0, 1.0, 1.0);

uniform float _FilterIntensity <
    ui_category = "Color Correct 1 Settings";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Color Filter Intensity (HDR)";
    ui_type = "drag";
    ui_tooltip = "Adjust the intensity of the color filter.";
> = 1.0f;

uniform float3 _Saturation <
    ui_category = "Color Correct 1 Settings";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Saturation";
    ui_type = "drag";
    ui_tooltip = "Adjust saturation.";
> = 1.0f;

float4 PS_ColorCorrect(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(Common::AcerolaBuffer, uv).rgba;
    float UIMask = 1.0f - col.a;

    float3 output = col.rgb;
    if (!_HDR)
        output = saturate(output);

    output *= _Exposure;
    if (!_HDR)
        output = saturate(output);

    output = Common::WhiteBalance(output.rgb, _Temperature, _Tint);
    output = _HDR ? max(0.0f, output) : saturate(output);

    output = _Contrast * (output - _LinearMidPoint) + _LinearMidPoint + _Brightness;
    output = _HDR ? max(0.0f, output) : saturate(output);

    output *= (_ColorFilter * _FilterIntensity);
    if (!_HDR)
        output = saturate(output);
    
    output = lerp(Common::Luminance(output), output, _Saturation);
    if (!_HDR)
        output = saturate(output);

    return float4(output, col.a);
}

technique AFX_ColorCorrection  <ui_label = "Color Correct"; ui_tooltip = "(HDR/LDR) A suite of color correction effects."; >  {
    pass ColorCorrect {
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_ColorCorrect;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}

#if AFX_CORRECT_COUNT > 0
    AFX_COLOR_CORRECT_SHADOW_CLONE(AFX_ColorCorrection2, "Color Correct 2", "Color Correct 2 Settings", _HDR2, _Exposure2, _Temperature2, _Tint2, _Contrast2, _LinearMidPoint2, _Brightness2, _ColorFilter2, _FilterIntensity2, _Saturation2, PS_ColorCorrect2)
#endif

#if AFX_CORRECT_COUNT > 1
    AFX_COLOR_CORRECT_SHADOW_CLONE(AFX_ColorCorrection3, "Color Correct 3", "Color Correct 3 Settings", _HDR3, _Exposure3, _Temperature3, _Tint3, _Contrast3, _LinearMidPoint3, _Brightness3, _ColorFilter3, _FilterIntensity3, _Saturation3, PS_ColorCorrect3)
#endif

#if AFX_CORRECT_COUNT > 2
    AFX_COLOR_CORRECT_SHADOW_CLONE(AFX_ColorCorrection4, "Color Correct 4", "Color Correct 4 Settings", _HDR4, _Exposure4, _Temperature4, _Tint4, _Contrast4, _LinearMidPoint4, _Brightness4, _ColorFilter4, _FilterIntensity4, _Saturation4, PS_ColorCorrect4)
#endif

#if AFX_CORRECT_COUNT > 3
    AFX_COLOR_CORRECT_SHADOW_CLONE(AFX_ColorCorrection5, "Color Correct 5", "Color Correct 5 Settings", _HDR5, _Exposure5, _Temperature5, _Tint5, _Contrast5, _LinearMidPoint5, _Brightness5, _ColorFilter5, _FilterIntensity5, _Saturation5, PS_ColorCorrect5)
#endif

#if AFX_CORRECT_COUNT > 4
    AFX_COLOR_CORRECT_SHADOW_CLONE(AFX_ColorCorrection6, "Color Correct 6", "Color Correct 6 Settings", _HDR6, _Exposure6, _Temperature6, _Tint6, _Contrast6, _LinearMidPoint6, _Brightness6, _ColorFilter6, _FilterIntensity6, _Saturation6, PS_ColorCorrect6)
#endif

#if AFX_CORRECT_COUNT > 5
    AFX_COLOR_CORRECT_SHADOW_CLONE(AFX_ColorCorrection7, "Color Correct 7", "Color Correct 7 Settings", _HDR7, _Exposure7, _Temperature7, _Tint7, _Contrast7, _LinearMidPoint7, _Brightness7, _ColorFilter7, _FilterIntensity7, _Saturation7, PS_ColorCorrect7)
#endif

#if AFX_CORRECT_COUNT > 6
    AFX_COLOR_CORRECT_SHADOW_CLONE(AFX_ColorCorrection8, "Color Correct 8", "Color Correct 8 Settings", _HDR8, _Exposure8, _Temperature8, _Tint8, _Contrast8, _LinearMidPoint8, _Brightness8, _ColorFilter8, _FilterIntensity8, _Saturation8, PS_ColorCorrect8)
#endif

#if AFX_CORRECT_COUNT > 7
    AFX_COLOR_CORRECT_SHADOW_CLONE(AFX_ColorCorrection9, "Color Correct 9", "Color Correct 9 Settings", _HDR9, _Exposure9, _Temperature9, _Tint9, _Contrast9, _LinearMidPoint9, _Brightness9, _ColorFilter9, _FilterIntensity9, _Saturation9, PS_ColorCorrect9)
#endif

#if AFX_CORRECT_COUNT > 8
    AFX_COLOR_CORRECT_SHADOW_CLONE(AFX_ColorCorrection10, "Color Correct 10", "Color Correct 10 Settings", _HDR10, _Exposure10, _Temperature10, _Tint10, _Contrast10, _LinearMidPoint10, _Brightness10, _ColorFilter10, _FilterIntensity10, _Saturation10, PS_ColorCorrect10)
#endif