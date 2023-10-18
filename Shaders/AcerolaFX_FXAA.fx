#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

#define AFX_EDGE_STEP_COUNT 10
#define AFX_EDGE_STEPS 1, 1.5, 2, 2, 2, 2, 2, 2, 2, 4
#define AFX_EDGE_GUESS 8

static const float edgeSteps[AFX_EDGE_STEP_COUNT] = { AFX_EDGE_STEPS };

uniform float _ContrastThreshold <
    ui_min = 0.0312f; ui_max = 0.0833f;
    ui_label = "Contrast Threshold";
    ui_type = "drag";
> = 0.0312f;

uniform float _RelativeThreshold <
    ui_min = 0.063f; ui_max = 0.333f;
    ui_label = "Relative Threshold";
    ui_type = "drag";
> = 0.063f;

uniform float _SubpixelBlending <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Subpixel Blending";
    ui_type = "drag";
> = 1.0f;

sampler2D FXAA { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR; };

texture2D AFX_FXAALuminanceTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; }; 
sampler2D Luminance { Texture = AFX_FXAALuminanceTex; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR; };

float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(FXAA, uv).rgba; }

float PS_Luminance(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return Common::Luminance(tex2D(Common::AcerolaBuffer, uv).g);
}

float4 PS_FXAA(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(Common::AcerolaBufferLinear, uv);

    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

    // Luminance Neighborhood
    float m = tex2D(Luminance, uv + float2(0, 0) * texelSize).r;
    
    float n = tex2D(Luminance, uv + float2(0, 1) * texelSize).r;
    float e = tex2D(Luminance, uv + float2(1, 0) * texelSize).r;
    float s = tex2D(Luminance, uv + float2(0, -1) * texelSize).r;
    float w = tex2D(Luminance, uv + float2(-1, 0) * texelSize).r;
    
    float ne = tex2D(Luminance, uv + float2(1, 1) * texelSize).r;
    float nw = tex2D(Luminance, uv + float2(-1, 1) * texelSize).r;
    float se = tex2D(Luminance, uv + float2(1, -1) * texelSize).r;
    float sw = tex2D(Luminance, uv + float2(-1, -1) * texelSize).r;

    // Apply Thresholding From Cardinals
    float maxL = max(max(max(max(m, n), e), s), w);
    float minL = min(min(min(min(m, n), e), s), w);
    float contrast = maxL - minL;
    
    if (contrast < max(_ContrastThreshold, _RelativeThreshold * maxL)) return col;

    // Determine Blend Factor
    float filter = 2 * (n + e + s + w) + ne + nw + se + sw;
    filter *= 1.0f / 12.0f;
    filter = abs(filter - m);
    filter = saturate(filter / contrast);

    float blendFactor = smoothstep(0, 1, filter);
    blendFactor *= blendFactor * _SubpixelBlending;

    // Edge Prediction
    float horizontal = abs(n + s - 2 * m) * 2 + abs(ne + se - 2 * e) + abs(nw + sw - 2 * w);
    float vertical = abs(e + w - 2 * m) * 2 + abs(ne + nw - 2 * n) + abs(se + sw - 2 * s);
    bool isHorizontal = horizontal >= vertical;

    float pLuminance = isHorizontal ? n : e;
    float nLuminance = isHorizontal ? s : w;
    float pGradient = abs(pLuminance - m);
    float nGradient = abs(nLuminance - m);

    float pixelStep = isHorizontal ? texelSize.y : texelSize.x;

    float oppositeLuminance = pLuminance;
    float gradient = pGradient;

    if (pGradient < nGradient) {
        pixelStep = -pixelStep;
        oppositeLuminance = nLuminance;
        gradient = nGradient;
    }

    float2 uvEdge = uv;
    float2 edgeStep;
    if (isHorizontal) {
        uvEdge.y += pixelStep * 0.5f;
        edgeStep = float2(texelSize.x, 0);
    } else {
        uvEdge.x += pixelStep * 0.5f;
        edgeStep = float2(0, texelSize.y);
    }

    float edgeLuminance = (m + oppositeLuminance) * 0.5f;
    float gradientThreshold = gradient * 0.25f;

    float2 puv = uvEdge + edgeStep * edgeSteps[0];
    float pLuminanceDelta = tex2D(Luminance, puv).r - edgeLuminance;
    bool pAtEnd = abs(pLuminanceDelta) >= gradientThreshold;

    [unroll]
    for (int j = 1; j < AFX_EDGE_STEP_COUNT && !pAtEnd; ++j) {
        puv += edgeStep * edgeSteps[j];
        pLuminanceDelta = tex2D(Luminance, puv).r - edgeLuminance;
        pAtEnd = abs(pLuminanceDelta) >= gradientThreshold;
    }

    if (!pAtEnd)
        puv += edgeStep * AFX_EDGE_GUESS;

    float2 nuv = uvEdge - edgeStep * edgeSteps[0];
    float nLuminanceDelta = tex2D(Luminance, nuv).r - edgeLuminance;
    bool nAtEnd = abs(nLuminanceDelta) >= gradientThreshold;

    [unroll]
    for (int k = 1; k < AFX_EDGE_STEP_COUNT && !nAtEnd; ++k) {
        nuv -= edgeStep * edgeSteps[k];
        nLuminanceDelta = tex2D(Luminance, nuv).r - edgeLuminance;
        nAtEnd = abs(nLuminanceDelta) >= gradientThreshold;
    }

    if (!nAtEnd)
        nuv -= edgeStep * AFX_EDGE_GUESS;


    float pDistance, nDistance;
    if (isHorizontal) {
        pDistance = puv.x - uv.x;
        nDistance = uv.x - nuv.x;
    } else {
        pDistance = puv.y - uv.y;
        nDistance = uv.y - nuv.y;
    }

    float shortestDistance = nDistance;
    bool deltaSign = nLuminanceDelta >= 0;

    if (pDistance <= nDistance) {
        shortestDistance = pDistance;
        deltaSign = pLuminanceDelta >= 0;
    }

    if (deltaSign == (m - edgeLuminance >= 0)) return col;

    float edgeBlendFactor = 0.5f - shortestDistance / (pDistance + nDistance);

    float finalBlendFactor = max(edgeBlendFactor, blendFactor);

    float2 newUV = uv;

    if (isHorizontal) 
        newUV.y += pixelStep * finalBlendFactor;
    else 
        newUV.x += pixelStep * finalBlendFactor;

    return tex2D(Common::AcerolaBufferLinear, newUV);
}

technique AFX_FXAA < ui_label = "FXAA"; > {
    pass {
        RenderTarget = AFX_FXAALuminanceTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Luminance;
    }
    pass {
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_FXAA;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}