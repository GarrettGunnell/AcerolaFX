#include "AcerolaFX_Common.fxh"

uniform float _Gamma <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Gamma";
    ui_type = "drag";
    ui_tooltip = "Adjust gamma correction.";
> = 1.0f;

texture2D AFX_FilmGrainTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D FilmGrain { Texture = AFX_FilmGrainTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(FilmGrain, uv).rgba; }

texture2D AFX_NoiseGrainTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R32F; }; 
sampler2D Noise { Texture = AFX_NoiseGrainTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
storage2D s_Noise { Texture = AFX_NoiseGrainTex; };

float hash(uint n) {
    // integer hash copied from Hugo Elias
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 0x789221U) + 0x1376312589U;
    return float( n & uint(0x7fffffffU))/float(0x7fffffff);
}


void CS_GenerateNoise(uint3 tid : SV_DISPATCHTHREADID) {
    uint seed = tid.x + BUFFER_WIDTH * tid.y + BUFFER_WIDTH * BUFFER_HEIGHT;
    tex2Dstore(s_Noise, tid.xy, hash(seed));
}

float4 PS_FilmGrain(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 c = tex2D(Common::AcerolaBuffer, uv);
    float noise = tex2D(Noise, uv).r;

    return c * noise;
}

technique AFX_FilmGrain < ui_label = "Film Grain"; ui_tooltip = "Applies film grain to the render."; > {
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