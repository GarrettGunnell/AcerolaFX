#include "ReShade.fxh"
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

float3 SampleBox(sampler2D texSampler, float2 uv, float2 texelSize, float delta) {
    float4 o = texelSize.xyxy * float2(-delta, delta).xxyy;
    float4 s = tex2D(texSampler, uv + o.xy) + tex2D(texSampler, uv + o.zy) + tex2D(texSampler, uv + o.xw) + tex2D(texSampler, uv + o.zw);

    return s.rgb * 0.25f;
}

float luminance(float3 color) {
    return dot(color, float3(0.299f, 0.587f, 0.114f));
}

float3 Prefilter(float3 col) {
    float brightness = luminance(col);
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

float4 PS_Blend(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(ReShade::BackBuffer, uv);
    float UIMask = 1.0f - col.a;

    float2 texelSize = float2(1.0f / (BUFFER_WIDTH / 2), 1.0f / (BUFFER_HEIGHT / 2));
    float3 output = col.rgb + _Intensity * pow(abs(SampleBox(DownScale::Half, uv, texelSize, _UpSampleDelta)), 1.0f / 2.2f);

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