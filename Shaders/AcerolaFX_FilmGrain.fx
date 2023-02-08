#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

uniform float _Intensity <
    ui_min = 0.0f; ui_max = 2.0f;
    ui_label = "Grain Intensity";
    ui_type = "drag";
    ui_tooltip = "Adjust strength of the grain.";
> = 0.15f;

uniform float _Response <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Luminance Response";
    ui_type = "drag";
    ui_tooltip = "Adjust strength of the grain.";
> = 0.15f;

uniform bool _AnimateNoise <
    ui_label = "Animate";
    ui_type = "drag";
    ui_tooltip = "Animate the noise.";
> = false;

uniform uint _KernelSize <
    ui_min = 0; ui_max = 5;
    ui_category_closed = true;
    ui_category = "Blur Settings";
    ui_type = "slider";
    ui_label = "Gaussian Kernel Size";
    ui_tooltip = "Size of the gaussian kernel";
> = 0;

uniform float _Sigma <
    ui_min = 0.0; ui_max = 5.0f;
    ui_category_closed = true;
    ui_category = "Blur Settings";
    ui_type = "drag";
    ui_label = "Blur Strength";
    ui_tooltip = "Sigma of the gaussian function";
> = 2.0f;

uniform float deltaTime < source = "frametime"; >;
uniform int frameCount < source = "framecount"; >;

#ifndef AFX_NOISE_DOWNSCALE_FACTOR
    #define AFX_NOISE_DOWNSCALE_FACTOR 0
#endif

#define PWRTWO(EXP) (1 << (EXP))
#define AFX_NOISETEX_WIDTH BUFFER_WIDTH / PWRTWO(AFX_NOISE_DOWNSCALE_FACTOR)
#define AFX_NOISETEX_HEIGHT BUFFER_HEIGHT / PWRTWO(AFX_NOISE_DOWNSCALE_FACTOR)


sampler2D FilmGrain { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(FilmGrain, uv).rgba; }

texture2D AFX_NoiseGrainTex { Width = AFX_NOISETEX_WIDTH; Height = AFX_NOISETEX_HEIGHT; Format = R32F; }; 
sampler2D Noise { Texture = AFX_NoiseGrainTex; };
storage2D s_Noise { Texture = AFX_NoiseGrainTex; };

texture2D AFX_NoiseGrainBlurTex { Width = AFX_NOISETEX_WIDTH; Height = AFX_NOISETEX_HEIGHT; Format = R32F; }; 
sampler2D BlurredNoise { Texture = AFX_NoiseGrainBlurTex; };
storage2D s_BlurredNoise { Texture = AFX_NoiseGrainBlurTex; };

float hash(uint n) {
    // integer hash copied from Hugo Elias
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 0x789221U) + 0x1376312589U;
    return float(n & uint(0x7fffffffU)) / float(0x7fffffff);
}

void CS_GenerateNoise(uint3 tid : SV_DISPATCHTHREADID) {
    uint seed = tid.x + AFX_NOISETEX_WIDTH * tid.y + AFX_NOISETEX_WIDTH * AFX_NOISETEX_HEIGHT + frameCount * deltaTime * 0.1f * _AnimateNoise;
    tex2Dstore(s_Noise, tid.xy, hash(seed));
}

float gaussian(float sigma, float pos) {
    return (1.0f / sqrt(2.0f * AFX_PI * sigma * sigma)) * exp(-(pos * pos) / (2.0f * sigma * sigma));
}

void CS_FirstBlurPass(uint3 tid : SV_DISPATCHTHREADID) {
    if (_KernelSize > 0) {
        int kernelRadius = _KernelSize;

        float noise = 0;
        float kernelSum = 0.0f;

        for (int x = -kernelRadius; x <= kernelRadius; ++x) {
            float n = tex2Dfetch(Noise, tid.xy + float2(x, 0)).r;
            float gauss = gaussian(_Sigma, x);

            noise += n * gauss;
            kernelSum += gauss;
        }

        tex2Dstore(s_BlurredNoise, tid.xy, noise / kernelSum);
    }
}

void CS_SecondBlurPass(uint3 tid : SV_DISPATCHTHREADID) {
    if (_KernelSize > 0) {
        int kernelRadius = _KernelSize;

        float noise = 0;
        float kernelSum = 0.0f;

        for (int y = -kernelRadius; y <= kernelRadius; ++y) {
            float n = tex2Dfetch(BlurredNoise, tid.xy + float2(0, y)).r;
            float gauss = gaussian(_Sigma, y);

            noise += n * gauss;
            kernelSum += gauss;
        }

        tex2Dstore(s_Noise, tid.xy, noise / kernelSum);
    }
}

float4 PS_FilmGrain(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 c = tex2D(Common::AcerolaBuffer, uv);
    float noise = tex2D(Noise, uv).r;

    noise = 2 * noise - 1;
    float weight = 1.0f - sqrt(Common::Luminance(c.rgb));
    weight = lerp(1.0f, weight, _Response);

    return float4(c.rgb + c.rgb * noise * _Intensity * weight, 1.0f);
}

technique AFX_FilmGrain < ui_label = "Film Grain"; ui_tooltip = "(HDR/LDR) Applies film grain to the render."; > {
    pass {
        ComputeShader = CS_GenerateNoise<8, 8>;
        DispatchSizeX = (AFX_NOISETEX_WIDTH + 7) / 8;
        DispatchSizeY = (AFX_NOISETEX_HEIGHT + 7) / 8;
    }

    pass {
        ComputeShader = CS_FirstBlurPass<8, 8>;
        DispatchSizeX = (AFX_NOISETEX_WIDTH + 7) / 8;
        DispatchSizeY = (AFX_NOISETEX_HEIGHT + 7) / 8;
    }

    pass {
        ComputeShader = CS_SecondBlurPass<8, 8>;
        DispatchSizeX = (AFX_NOISETEX_WIDTH + 7) / 8;
        DispatchSizeY = (AFX_NOISETEX_HEIGHT + 7) / 8;
    }

    pass {
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_FilmGrain;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}