#include "AcerolaFX_Common.fxh"

uniform float _GrainIntensity <
    ui_min = 0.0f; ui_max = 2.0f;
    ui_label = "Grain Intensity";
    ui_type = "drag";
    ui_tooltip = "Adjust strength of the grain.";
> = 0.15f;

uniform uint _BlendMode <
    ui_type = "combo";
    ui_label = "Blend Mode";
    ui_tooltip = "How to blend the noise";
    ui_items = "Add\0"
               "Subtract\0"
               "Multiply\0"
               "Screen\0"
               "Color Dodge\0"
               "Color Burn\0";
> = 2;

uniform bool _AnimateNoise <
    ui_label = "Animate";
    ui_type = "drag";
    ui_tooltip = "Animate the noise.";
> = false;

uniform float deltaTime < source = "frametime"; >;
uniform int frameCount < source = "framecount"; >;

#ifndef AFX_NOISE_DOWNSCALE_FACTOR
    #define AFX_NOISE_DOWNSCALE_FACTOR 0
#endif

#define PWRTWO(EXP) (1 << (EXP))
#define AFX_NOISETEX_WIDTH BUFFER_WIDTH / PWRTWO(AFX_NOISE_DOWNSCALE_FACTOR)
#define AFX_NOISETEX_HEIGHT BUFFER_HEIGHT / PWRTWO(AFX_NOISE_DOWNSCALE_FACTOR)


texture2D AFX_FilmGrainTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D FilmGrain { Texture = AFX_FilmGrainTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(FilmGrain, uv).rgba; }

texture2D AFX_NoiseGrainTex { Width = AFX_NOISETEX_WIDTH; Height = AFX_NOISETEX_HEIGHT; Format = R32F; }; 
sampler2D Noise { Texture = AFX_NoiseGrainTex; };
storage2D s_Noise { Texture = AFX_NoiseGrainTex; };

float hash(uint n) {
    // integer hash copied from Hugo Elias
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 0x789221U) + 0x1376312589U;
    return float(n & uint(0x7fffffffU)) / float(0x7fffffff);
}

void CS_GenerateNoise(uint3 tid : SV_DISPATCHTHREADID) {
    uint seed = tid.x + BUFFER_WIDTH * tid.y + BUFFER_WIDTH * BUFFER_HEIGHT + frameCount * deltaTime * _AnimateNoise;
    tex2Dstore(s_Noise, tid.xy, hash(seed));
}

float4 BlendNoise(float4 a, float b) {
    if (_BlendMode == 0) return a + b;
    if (_BlendMode == 1) return a - b;
    if (_BlendMode == 2) return a * b;
    if (_BlendMode == 3) return 1.0f - (1.0f - a) * (1.0f - b);
    if (_BlendMode == 4) return a / (1.0f - (b - 0.001f));
    return 1.0f - ((1.0f - a) / (b + 0.001));
}

float4 PS_FilmGrain(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 c = tex2D(Common::AcerolaBuffer, uv);
    float noise = tex2D(Noise, uv).r;

    return lerp(c, BlendNoise(c, noise), _GrainIntensity);
}

technique AFX_FilmGrain < ui_label = "Film Grain"; ui_tooltip = "(HDR/LDR) Applies film grain to the render."; > {
    pass {
        ComputeShader = CS_GenerateNoise<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    pass {
        RenderTarget = AFX_FilmGrainTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_FilmGrain;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}