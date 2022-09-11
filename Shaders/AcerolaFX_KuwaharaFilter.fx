#include "AcerolaFX_Common.fxh"

uniform int _Filter <
    ui_type = "combo";
    ui_label = "Filter Type";
    ui_items = "Basic\0"
               "Generalized\0"
               "Anisotropic\0";
    ui_tooltip = "Which extension of the kuwahara filter?";
> = 0;

uniform uint _KernelSize <
    ui_min = 2; ui_max = 30;
    ui_type = "slider";
    ui_label = "Radius";
    ui_tooltip = "Size of the kuwahara filter kernel";
> = 1;

uniform float _Q <
    ui_min = 0; ui_max = 18;
    ui_type = "drag";
    ui_label = "Sharpness";
    ui_tooltip = "Adjusts sharpness of the color segments";
> = 8;

uniform float _Alpha <
   ui_min = 0.01f; ui_max = 2.0f;
   ui_category_closed = true;
   ui_category = "Anisotropic Settings";
   ui_type = "drag";
   ui_label = "Alpha";
   ui_tooltip = "How much sectors overlap at the edge"; 
> = 1.0f;

uniform float _ZeroCrossing <
   ui_min = 0.01f; ui_max = 2.0f;
   ui_category_closed = true;
   ui_category = "Anisotropic Settings";
   ui_type = "drag";
   ui_label = "Zero Crossing";
   ui_tooltip = "How much sectors overlap with each other"; 
> = 0.58f;

#ifndef AFX_SECTORS
# define AFX_SECTORS 8
#endif

texture2D KuwaharaFilterTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D KuwaharaFilter { Texture = KuwaharaFilterTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(KuwaharaFilter, uv).rgba; }

/* Basic Kuwahara Filter */
float4 SampleQuadrant(float2 uv, int x1, int x2, int y1, int y2, float n) {
    float luminanceSum = 0.0f;
    float luminanceSum2 = 0.0f;
    float3 colSum = 0.0f;

    for (int x = x1; x <= x2; ++x) {
        for (int y = y1; y <= y2; ++y) {
            float3 c = tex2D(Common::AcerolaBuffer, uv + float2(x, y) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).rgb;
            float l = Common::Luminance(c);
            luminanceSum += l;
            luminanceSum2 += l * l;
            colSum += c;
        }
    }

    float mean = luminanceSum / n;
    float stdev = abs(luminanceSum2 / n - mean * mean);

    return float4(colSum / n, stdev);
}

void Basic(in float2 uv, out float4 output) {
    int radius = _KernelSize / 2;
    float windowSize = 2.0f * radius + 1;
    int quadrantSize = int(ceil(windowSize / 2.0f));
    int numSamples = quadrantSize * quadrantSize;

    float4 q1 = SampleQuadrant(uv, -radius, 0, -radius, 0, numSamples);
    float4 q2 = SampleQuadrant(uv, 0, radius, -radius, 0, numSamples);
    float4 q3 = SampleQuadrant(uv, 0, radius, 0, radius, numSamples);
    float4 q4 = SampleQuadrant(uv, -radius, 0, 0, radius, numSamples);

    float minstd = min(q1.a, min(q2.a, min(q3.a, q4.a)));
    int4 q = float4(q1.a, q2.a, q3.a, q4.a) == minstd;

    if (dot(q, 1) > 1)
        output = float4((q1.rgb + q2.rgb + q3.rgb + q4.rgb) / 4.0f, 1.0f);
    else
        output = float4(q1.rgb * q.x + q2.rgb * q.y + q3.rgb * q.z + q4.rgb * q.w, 1.0f);
}

/* Generalized Kuwahara Filter */

float gaussian(float sigma, float2 pos) {
    return (1.0f / (2.0f * AFX_PI * sigma * sigma)) * exp(-((pos.x * pos.x + pos.y * pos.y) / (2.0f * sigma * sigma)));
}

texture2D SectorsTex { Width = 32; Height = 32; Format = R16F; };
sampler2D Sectors { Texture = SectorsTex; };
texture2D WeightsTex { Width = 32; Height = 32; Format = R16F; };
sampler2D K0 { Texture = WeightsTex; };

float PS_CalculateSectors(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    int N = AFX_SECTORS;

    float2 pos = uv - 0.5f;
    float phi = atan2(pos.y, pos.x);
    int Xk = (-AFX_PI / N) < phi && phi <= (AFX_PI / N);

    return dot(pos, pos) <= 0.25f ? Xk : 0;
}

float PS_GaussianFilterSectors(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    // Standard deviation of gaussian kernel precomputed based on the resolution of the lookup table (32x32)
    // A resolution beyond 32x32 appears not to affect quality so it stays hard coded
    float sigmaR = 0.5f * 32.0f * 0.5f;
    float sigmaS = 0.33f * sigmaR;
    
    float weight = 0.0f;
    float kernelSum = 0.0f;
    for (int x = -floor(sigmaS); x <= floor(sigmaS); ++x) {
        for (int y = -floor(sigmaS); y <= floor(sigmaS); ++y) {
            float c = tex2D(Sectors, uv + float2(x, y) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).r;
            float gauss = gaussian(sigmaS, float2(x, y));

            weight += c * gauss;
            kernelSum += gauss;
        }
    }

    return (weight / kernelSum) * gaussian(sigmaR, (uv - 0.5f) * sigmaR * 5);
}

void Generalized(in float2 uv, out float4 output) {
    int k;
    float4 m[8];
    float3 s[8];
    int radius = _KernelSize / 2;

    int _N = AFX_SECTORS;

    for (k = 0; k < _N; ++k) {
        m[k] = 0.0f;
        s[k] = 0.0f;
    }

    float piN = 2.0f * AFX_PI / float(_N);
    float2x2 X = float2x2(
        float2(cos(piN), sin(piN)), 
        float2(-sin(piN), cos(piN))
    );

    for (int x = -radius; x <= radius; ++x) {
        for (int y = -radius; y <= radius; ++y) {
            float2 v = 0.5f * float2(x, y) / float(radius);
            float3 c = tex2D(Common::AcerolaBuffer, uv + float2(x, y) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).rgb;
            [unroll]
            for (k = 0; k < _N; ++k) {
                float w = tex2D(K0, 0.5f + v).x;

                m[k] += float4(c * w, w);
                s[k] += c * c * w;

                v = mul(X, v);
            }
        }
    }

    output = 0.0f;
    for (k = 0; k < _N; ++k) {
        m[k].rgb /= m[k].w;
        s[k] = abs(s[k] / m[k].w - m[k].rgb * m[k].rgb);

        float sigma2 = s[k].r + s[k].g + s[k].b;
        float w = 1.0f / (1.0f + pow(abs(1000.0f * sigma2), 0.5f * _Q));

        output += float4(m[k].rgb * w, w);
    }

    output = output / output.w;
}

/* Anisotropic Kuwahara Filter */

texture2D StructureTensorTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D StructureTensor { Texture = StructureTensorTex;};
texture2D TFMTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D TFM { Texture = TFMTex;};

float gaussian(float sigma, float pos) {
    return (1.0f / sqrt(2.0f * AFX_PI * sigma * sigma)) * exp(-(pos * pos) / (2.0f * sigma * sigma));
}

float4 PS_StructureTensor(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    if (_Filter == 2) {
        float2 d = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

        float3 Sx = (
             1.0f * tex2D(Common::AcerolaBuffer, uv + float2(-d.x, -d.y)).rgb +
             2.0f * tex2D(Common::AcerolaBuffer, uv + float2(-d.x,  0.0)).rgb +
             1.0f * tex2D(Common::AcerolaBuffer, uv + float2(-d.x,  d.y)).rgb +
            -1.0f * tex2D(Common::AcerolaBuffer, uv + float2(d.x, -d.y)).rgb +
            -2.0f * tex2D(Common::AcerolaBuffer, uv + float2(d.x,  0.0)).rgb +
            -1.0f * tex2D(Common::AcerolaBuffer, uv + float2(d.x,  d.y)).rgb
        ) / 4.0f;

        float3 Sy = (
             1.0f * tex2D(Common::AcerolaBuffer, uv + float2(-d.x, -d.y)).rgb +
             2.0f * tex2D(Common::AcerolaBuffer, uv + float2( 0.0, -d.y)).rgb +
             1.0f * tex2D(Common::AcerolaBuffer, uv + float2( d.x, -d.y)).rgb +
            -1.0f * tex2D(Common::AcerolaBuffer, uv + float2(-d.x, d.y)).rgb +
            -2.0f * tex2D(Common::AcerolaBuffer, uv + float2( 0.0, d.y)).rgb +
            -1.0f * tex2D(Common::AcerolaBuffer, uv + float2( d.x, d.y)).rgb
        ) / 4.0f;

        
        return float4(dot(Sx, Sx), dot(Sy, Sy), dot(Sx, Sy), 1.0f);
    } else return 0;
}

float4 PS_CalculateAnisotropy(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    if (_Filter == 2) {
        int kernelRadius = 1;

        float4 col = 0;
        float kernelSum = 0.0f;

        for (int x = -kernelRadius; x <= kernelRadius; ++x) {
            float4 c = tex2D(StructureTensor, uv + float2(x, 0) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT));
            float gauss = gaussian(2.0f, x);

            col += c * gauss;
            kernelSum += gauss;
        }

        for (int y = -kernelRadius; y <= kernelRadius; ++y) {
            float4 c = tex2D(StructureTensor, uv + float2(0, y) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT));
            float gauss = gaussian(2.0f, y);

            col += c * gauss;
            kernelSum += gauss;
        }

        float3 g = col.rgb / kernelSum;

        float lambda1 = 0.5f * (g.y + g.x + sqrt(g.y * g.y - 2.0f * g.x * g.y + g.x * g.x + 4.0f * g.z * g.z));
        float lambda2 = 0.5f * (g.y + g.x - sqrt(g.y * g.y - 2.0f * g.x * g.y + g.x * g.x + 4.0f * g.z * g.z));

        float2 v = float2(lambda1 - g.x, -g.z);
        float2 t = length(v) > 0.0 ? normalize(v) : float2(0.0f, 1.0f);
        float phi = -atan2(t.y, t.x);

        float A = (lambda1 + lambda2 > 0.0f) ? (lambda1 - lambda2) / (lambda1 + lambda2) : 0.0f;
        
        return float4(t, phi, A);
    } else return 0;
}

void Anisotropic(in float2 uv, out float4 output) {
    output = 1;
}

float4 PS_KuwaharaFilter(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 output = 0;

    if (_Filter == 0) Basic(uv, output);
    if (_Filter == 1) Generalized(uv, output);
    if (_Filter == 2) Anisotropic(uv, output);

    return output;
}

technique AFX_SetupKuwahara < hidden = true; enabled = true; timeout = 1; > {
    pass GenerateSectors {
        RenderTarget = SectorsTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_CalculateSectors;
    }

    pass GaussianFilter {
        RenderTarget = WeightsTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_GaussianFilterSectors;
    }
}

technique AFX_KuwaharaFilter < ui_label = "Kuwahara Filter"; ui_tooltip = "(LDR)(VERY HIGH PERFORMANCE COST) Applies a Kuwahara filter to the screen."; > {
    pass {
        RenderTarget = StructureTensorTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_StructureTensor;
    }
    
    pass {
        RenderTarget = TFMTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_CalculateAnisotropy;
    }
    
    pass {
        RenderTarget = KuwaharaFilterTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_KuwaharaFilter;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}