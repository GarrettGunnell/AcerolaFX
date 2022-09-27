#include "AcerolaFX_Common.fxh"

uniform uint _BlurMode <
    ui_type = "combo";
    ui_label = "Blur Mode";
    ui_tooltip = "How to blur the render";
    ui_items = "Box\0"
               "Gaussian\0";
> = 0;

uniform uint _KernelSize <
    ui_min = 1; ui_max = 10;
    ui_category_closed = true;
    ui_category = "Blur Settings";
    ui_type = "slider";
    ui_label = "Kernel Size";
    ui_tooltip = "Size of the blur kernel";
> = 3;

uniform float _Sigma <
    ui_min = 0.0; ui_max = 5.0f;
    ui_category_closed = true;
    ui_category = "Blur Settings";
    ui_type = "drag";
    ui_label = "Blur Strength";
    ui_tooltip = "Sigma of the gaussian function (used for Gaussian blur)";
> = 2.0f;

#ifndef AFX_BLUR_PASSES
    #define AFX_BLUR_PASSES 1
#endif

texture2D AFX_BlurPingTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D BlurPing { Texture = AFX_BlurPingTex; };
storage2D s_BlurPing { Texture = AFX_BlurPingTex; };

float gaussian(float sigma, float pos) {
    return (1.0f / sqrt(2.0f * AFX_PI * sigma * sigma)) * exp(-(pos * pos) / (2.0f * sigma * sigma));
}

void CS_FirstBlurPass(uint3 tid : SV_DISPATCHTHREADID) {
    int kernelRadius = _KernelSize;

    float4 col = 0;
    float kernelSum = 0.0f;

    for (int x = -kernelRadius; x <= kernelRadius; ++x) {
        float4 c = tex2Dfetch(Common::AcerolaBuffer, tid.xy + float2(x, 0));
        float gauss = (_BlurMode == 0) ? 1.0f : gaussian(_Sigma, x);

        col += c * gauss;
        kernelSum += gauss;
    }

    tex2Dstore(s_BlurPing, tid.xy, col / kernelSum);
}

void CS_SecondBlurPass(uint3 tid : SV_DISPATCHTHREADID) {
    int kernelRadius = _KernelSize;

    float4 col = 0;
    float kernelSum = 0.0f;

    for (int y = -kernelRadius; y <= kernelRadius; ++y) {
        float4 c = tex2Dfetch(BlurPing, tid.xy + float2(0, y));
        float gauss = (_BlurMode == 0) ? 1.0f : gaussian(_Sigma, y);

        col += c * gauss;
        kernelSum += gauss;
    }

    tex2Dstore(Common::s_AcerolaBuffer, tid.xy, col / kernelSum);
}

technique AFX_Blur < ui_label = "Blur"; ui_tooltip = "(HDR/LDR) Blurs the image."; > {
    pass {
        ComputeShader = CS_FirstBlurPass<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    pass {
        ComputeShader = CS_SecondBlurPass<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    #if AFX_BLUR_PASSES > 1
    pass {
        ComputeShader = CS_FirstBlurPass<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    pass {
        ComputeShader = CS_SecondBlurPass<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }
    #endif

    #if AFX_BLUR_PASSES > 2
    pass {
        ComputeShader = CS_FirstBlurPass<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    pass {
        ComputeShader = CS_SecondBlurPass<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }
    #endif

    #if AFX_BLUR_PASSES > 3
    pass {
        ComputeShader = CS_FirstBlurPass<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    pass {
        ComputeShader = CS_SecondBlurPass<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }
    #endif

    #if AFX_BLUR_PASSES > 4
    pass {
        ComputeShader = CS_FirstBlurPass<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    pass {
        ComputeShader = CS_SecondBlurPass<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }
    #endif

    #if AFX_BLUR_PASSES > 5
    pass {
        ComputeShader = CS_FirstBlurPass<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    pass {
        ComputeShader = CS_SecondBlurPass<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }
    #endif
}