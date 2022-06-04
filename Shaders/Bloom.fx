#include "ReShade.fxh"
#include "Common.fxh"
#include "Downscales.fxh"

uniform float _Threshold <
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Threshold";
    ui_type = "drag";
    ui_tooltip = "Controls how bright a color must be to trigger bloom";
> = 0.8f;

uniform float _SoftThreshold <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Soft Threshold";
    ui_type = "drag";
    ui_tooltip = "Adjusts the shoulder of the bloom threshold curve";
> = 0.75f;

uniform float _Intensity <
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Intensity";
    ui_type = "drag";
    ui_tooltip = "Adjust bloom intensity";
> = 1.0f;

uniform bool _SampleSky <
    ui_label = "Sky Mask";
    ui_tooltip = "Toggle whether or not the sky is included in bloom (looks nice on stars)";
> = false;

// Advanced

uniform float _DownSampleDelta <
    ui_category = "Advanced settings";
    ui_min = 0.01f; ui_max = 2.0f;
    ui_label = "Down Sample Delta";
    ui_tooltip = "Adjust sampling offset when downsampling the back buffer";
> = 1.0f;

uniform float _UpSampleDelta <
    ui_category = "Advanced settings";
    ui_min = 0.01f; ui_max = 2.0f;
    ui_label = "Up Sample Delta";
    ui_tooltip = "Adjust sampling offset when upsampling the downscaled back buffer";
> = 0.5f;

uniform int _BlendMode <
    ui_category = "Advanced settings";
    ui_type = "combo";
    ui_label = "Bloom blend mode";
    ui_tooltip = "Adjust how bloom texture blends into image.";
    ui_items = "Add\0"
               "Multiply\0"
               "Color Burn\0"
               "Screen\0"
               "Color Dodge\0"
               "Soft Light\0"
               "Hard Light\0";
> = 0;

uniform float _ExposureCorrect <
    ui_category = "Advanced settings";
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Exposure";
    ui_type = "drag";
    ui_tooltip = "Adjust camera exposure";
> = 1.0f;

uniform float _Temperature <
    ui_category = "Advanced settings";
    ui_min = -1.0f; ui_max = 1.0f;
    ui_label = "Temperature";
    ui_type = "drag";
    ui_tooltip = "Adjust white balancing temperature";
> = 0.0f;

uniform float _Tint <
    ui_category = "Advanced settings";
    ui_min = -1.0f; ui_max = 1.0f;
    ui_label = "Tint";
    ui_type = "drag";
    ui_tooltip = "Adjust white balance color tint";
> = 0.0f;

uniform float _Contrast <
    ui_category = "Advanced settings";
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Contrast";
    ui_type = "drag";
    ui_tooltip = "Adjust contrast";
> = 1.0f;

uniform float3 _Brightness <
    ui_category = "Advanced settings";
    ui_min = -5.0f; ui_max = 5.0f;
    ui_label = "Brightness";
    ui_type = "drag";
    ui_tooltip = "Adjust brightness of each color channel";
> = float3(0.0, 0.0, 0.0);

uniform float3 _ColorFilter <
    ui_category = "Advanced settings";
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Color Filter";
    ui_type = "drag";
    ui_tooltip = "Set color filter (white for no change)";
> = float3(1.0, 1.0, 1.0);

uniform float _FilterIntensity <
    ui_category = "Advanced settings";
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Color Filter Intensity (HDR)";
    ui_type = "drag";
    ui_tooltip = "Adjust the intensity of the color filter";
> = 1.0f;

uniform float _Saturation <
    ui_category = "Advanced settings";
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Saturation";
    ui_type = "drag";
    ui_tooltip = "Adjust saturation";
> = 1.0f;

float3 SampleBox(sampler2D texSampler, float2 uv, float2 texelSize, float delta) {
    float4 o = texelSize.xyxy * float2(-delta, delta).xxyy;
    float4 s = tex2D(texSampler, uv + o.xy) + tex2D(texSampler, uv + o.zy) + tex2D(texSampler, uv + o.xw) + tex2D(texSampler, uv + o.zw);

    return s.rgb * 0.25f;
}

float3 Prefilter(float3 col) {
    float brightness = Common::Luminance(col);
    float knee = _Threshold * _SoftThreshold;
    float soft = brightness - _Threshold + knee;
    soft = clamp(soft, 0, 2 * knee);
    soft = soft * soft / (4 * knee * 0.00001);
    float contribution = max(soft, brightness - _Threshold);
    contribution /= max(contribution, 0.00001);

    return col * contribution;
}

float4 PS_Prefilter(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
    float UIMask = (tex2D(ReShade::BackBuffer, uv).a > 0.0f) ? 0.0f : 1.0f;
    float SkyMask = (ReShade::GetLinearizedDepth(uv) == 1.0f) ? 0.0f : 1.0f;

    if (_SampleSky) {
        SkyMask = 1.0f;
    }

    float4 output = float4(Prefilter(pow(abs(SampleBox(ReShade::BackBuffer, uv, texelSize, 1.0f)), 2.2f).rgb) * UIMask * SkyMask, 1.0f);
    
    return output;
}

float4 Scale(float4 pos : SV_POSITION, float2 uv : TEXCOORD, sampler2D buffer, int sizeFactor, float sampleDelta) {
    float2 texelSize = float2(1.0f / (BUFFER_WIDTH / sizeFactor), 1.0f / (BUFFER_HEIGHT / sizeFactor));

    return float4(SampleBox(buffer, uv, texelSize, sampleDelta), 1.0f);
}

float4 PS_Down1(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_TARGET { return Scale(position, uv, DownScale::Half, 2, _DownSampleDelta); }
float4 PS_Down2(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_TARGET { return Scale(position, uv, DownScale::Quarter, 4, _DownSampleDelta); }
float4 PS_Down3(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_TARGET { return Scale(position, uv, DownScale::Eighth, 8, _DownSampleDelta); }
float4 PS_Down4(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_TARGET { return Scale(position, uv, DownScale::Sixteenth, 16, _DownSampleDelta); }
float4 PS_Down5(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_TARGET { return Scale(position, uv, DownScale::ThirtySecondth, 32, _DownSampleDelta); }
float4 PS_Up1(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_TARGET { return Scale(position, uv, DownScale::SixtyFourth, 64, _UpSampleDelta); }
float4 PS_Up2(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_TARGET { return Scale(position, uv, DownScale::ThirtySecondth, 32, _UpSampleDelta); }
float4 PS_Up3(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_TARGET { return Scale(position, uv, DownScale::Sixteenth, 16, _UpSampleDelta); }
float4 PS_Up4(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_TARGET { return Scale(position, uv, DownScale::Eighth, 8, _UpSampleDelta); }
float4 PS_Up5(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_TARGET { return Scale(position, uv, DownScale::Quarter, 4, _UpSampleDelta); }

float3 ColorCorrect(float3 col) : SV_TARGET {
    col *= _ExposureCorrect;

    col = Common::WhiteBalance(col.rgb, _Temperature, _Tint);
    col = max(0.0f, col);

    col = _Contrast * (col - 0.5f) + 0.5f + _Brightness;
    col = max(0.0f, col);

    col *= (_ColorFilter * _FilterIntensity);

    return lerp(Common::Luminance(col), col, _Saturation);
}

float4 PS_Blend(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(ReShade::BackBuffer, uv);
    float UIMask = 1.0f - col.a;

    float2 texelSize = float2(1.0f / (BUFFER_WIDTH / 2), 1.0f / (BUFFER_HEIGHT / 2));
    float3 bloom = _Intensity * pow(abs(ColorCorrect(SampleBox(DownScale::Half, uv, texelSize, _UpSampleDelta))), 1.0f / 2.2f);
    
    float3 output = col.rgb;
    
    // Add (Default)
    if (_BlendMode == 0) { 
        output += bloom;
    }
    // Multiply
    else if (_BlendMode == 1) {
        output *= (1.0f + bloom);
    }
    // Color Burn
    else if (_BlendMode == 2) {
        output = 1.0f - (1.0f - output) / (1.0f + bloom);
    }
    // Screen
    else if (_BlendMode == 3) {
        output = 1.0f - (1.0f - output) * (1.0f - bloom);
    }
    // Color Dodge
    else if (_BlendMode == 4) {
        output = output / (1.0f - bloom);
    }
    // Soft Light
    else if (_BlendMode == 5) {
        output = (bloom > 0.5f) * (1.0f - (1.0f - output) * (1.0f - (bloom - 0.5f))) + (bloom <= 0.5f) * (output * (bloom + 0.5f));
    }
    // Hard Light
    else if (_BlendMode == 6) {
        output = (bloom > 0.5f) * (1.0f - (1.0f - output) * (1.0f - 2.0f * (bloom - 0.5f))) + (bloom <= 0.5f) * (output * (2.0f * bloom));
    }

    return float4(lerp(col.rgb, output, UIMask), col.a);
}

technique Bloom {
    pass Prefilter {
        RenderTarget = DownScale::HalfTex;
        VertexShader = PostProcessVS;
        PixelShader = PS_Prefilter;
    }

    pass Down1 {
        RenderTarget = DownScale::QuarterTex;
        VertexShader = PostProcessVS;
        PixelShader = PS_Down1;
    }

    pass Down2 {
        RenderTarget = DownScale::EighthTex;
        VertexShader = PostProcessVS;
        PixelShader = PS_Down2;
    }

    pass Down3 {
        RenderTarget = DownScale::SixteenthTex;
        VertexShader = PostProcessVS;
        PixelShader = PS_Down3;
    }

    pass Down4 {
        RenderTarget = DownScale::ThirtySecondthTex;
        VertexShader = PostProcessVS;
        PixelShader = PS_Down4;
    }

    pass Down5 {
        RenderTarget = DownScale::SixtyFourthTex;
        VertexShader = PostProcessVS;
        PixelShader = PS_Down5;
    }
    
    pass Up1 {
        RenderTarget = DownScale::ThirtySecondthTex;
        BlendEnable = true;
        DestBlend = ONE;
        VertexShader = PostProcessVS;
        PixelShader = PS_Up1;
    }

    pass Up2 {
        RenderTarget = DownScale::SixteenthTex;
        BlendEnable = true;
        DestBlend = ONE;
        VertexShader = PostProcessVS;
        PixelShader = PS_Up2;
    }

    pass Up3 {
        RenderTarget = DownScale::EighthTex;
        BlendEnable = true;
        DestBlend = ONE;
        VertexShader = PostProcessVS;
        PixelShader = PS_Up3;
    }

    pass Up4 {
        RenderTarget = DownScale::QuarterTex;
        BlendEnable = true;
        DestBlend = ONE;
        VertexShader = PostProcessVS;
        PixelShader = PS_Up4;
    }

    pass Up5 {
        RenderTarget = DownScale::HalfTex;
        BlendEnable = true;
        DestBlend = ONE;
        VertexShader = PostProcessVS;
        PixelShader = PS_Up5;
    }

    pass Blend {
        VertexShader = PostProcessVS;
        PixelShader = PS_Blend;
    }
}