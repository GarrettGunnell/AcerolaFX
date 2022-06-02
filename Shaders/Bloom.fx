#include "ReShade.fxh"

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

texture2D downOne {
    Width = BUFFER_WIDTH / 2;
    Height = BUFFER_HEIGHT / 2;

    Format = RGBA16F;
};

sampler2D downOneSampler {
    Texture = downOne;
};

float4 PS_Prefilter(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
    float UIMask = (tex2D(ReShade::BackBuffer, uv).a > 0.0f) ? 0.0f : 1.0f;
    float SkyMask = (ReShade::GetLinearizedDepth(uv) == 1.0f) ? 0.0f : 1.0f;

    float4 output = float4(Prefilter(pow(abs(SampleBox(ReShade::BackBuffer, uv, texelSize, 1.0f)), 2.2f).rgb) * UIMask * SkyMask, 1.0f);
    
    return output;
}

technique Bloom {
    pass Prefilter {
        RenderTarget = downOne;
        
        VertexShader = PostProcessVS;
        PixelShader = PS_Prefilter;
    }
}