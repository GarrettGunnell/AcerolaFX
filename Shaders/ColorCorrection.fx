#include "ReShade.fxh"

uniform float _Exposure <
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Exposure";
    ui_type = "drag";
    ui_tooltip = "Adjust camera exposure";
> = 1.0f;

uniform float _Temperature <
    ui_min = -1.0f; ui_max = 1.0f;
    ui_label = "Temperature";
    ui_type = "drag";
    ui_tooltip = "Adjust white balancing temperature";
> = 0.0f;

uniform float _Tint <
    ui_min = -1.0f; ui_max = 1.0f;
    ui_label = "Tint";
    ui_type = "drag";
    ui_tooltip = "Adjust white balance color tint";
> = 0.0f;

uniform float _Contrast <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Contrast";
    ui_type = "drag";
    ui_tooltip = "Adjust contrast";
> = 1.0f;

uniform float3 _Brightness <
    ui_min = -5.0f; ui_max = 5.0f;
    ui_label = "Brightness";
    ui_type = "drag";
    ui_tooltip = "Adjust brightness of each color channel";
> = float3(0.0, 0.0, 0.0);

uniform float3 _ColorFilter <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Color Filter";
    ui_type = "drag";
    ui_tooltip = "Set color filter (white for no change)";
> = float3(1.0, 1.0, 1.0);

uniform float _FilterIntensity <
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Color Filter Intensity (HDR)";
    ui_type = "drag";
    ui_tooltip = "Adjust the intensity of the color filter";
> = 1.0f;

uniform float _Saturation <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Saturation";
    ui_type = "drag";
    ui_tooltip = "Adjust saturation";
> = 1.0f;

float luminance(float3 color) {
    return dot(color, float3(0.299f, 0.587f, 0.114f));
}

//https://docs.unity3d.com/Packages/com.unity.shadergraph@6.9/manual/White-Balance-Node.html
float3 WhiteBalance(float3 col, float temp, float tint) {
    float t1 = temp * 10.0f / 6.0f;
    float t2 = tint * 10.0f / 6.0f;

    float x = 0.31271 - t1 * (t1 < 0 ? 0.1 : 0.05);
    float standardIlluminantY = 2.87 * x - 3 * x * x - 0.27509507;
    float y = standardIlluminantY + t2 * 0.05;

    float3 w1 = float3(0.949237, 1.03542, 1.08728);

    float Y = 1;
    float X = Y * x / y;
    float Z = Y * (1 - x - y) / y;
    float L = 0.7328 * X + 0.4296 * Y - 0.1624 * Z;
    float M = -0.7036 * X + 1.6975 * Y + 0.0061 * Z;
    float S = 0.0030 * X + 0.0136 * Y + 0.9834 * Z;
    float3 w2 = float3(L, M, S);

    float3 balance = float3(w1.x / w2.x, w1.y / w2.y, w1.z / w2.z);

    float3x3 LIN_2_LMS_MAT = float3x3(
        float3(3.90405e-1, 5.49941e-1, 8.92632e-3),
        float3(7.08416e-2, 9.63172e-1, 1.35775e-3),
        float3(2.31082e-2, 1.28021e-1, 9.36245e-1)
    );

    float3x3 LMS_2_LIN_MAT = float3x3(
        float3(2.85847e+0, -1.62879e+0, -2.48910e-2),
        float3(-2.10182e-1,  1.15820e+0,  3.24281e-4),
        float3(-4.18120e-2, -1.18169e-1,  1.06867e+0)
    );

    float3 lms = mul(LIN_2_LMS_MAT, col);
    lms *= balance;
    return mul(LMS_2_LIN_MAT, lms);
}

float4 PS_ColorCorrect(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(ReShade::BackBuffer, uv).rgba;
    float UIMask = 1.0f - col.a;

    float3 output = pow(abs(col.rgb), 1.0f / 2.2f);

    output *= _Exposure;

    output = WhiteBalance(output.rgb, _Temperature, _Tint);
    output = max(0.0f, output);

    output = _Contrast * (output - 0.5f) + 0.5f + _Brightness;
    output = max(0.0f, output);

    output *= (_ColorFilter * _FilterIntensity);

    output = lerp(luminance(output), output, _Saturation);

    output = pow(abs(output.rgb), 2.2f);

    return float4(lerp(col.rgb, output, UIMask), col.a);
}

technique ColorCorrection {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_ColorCorrect;
    }
}