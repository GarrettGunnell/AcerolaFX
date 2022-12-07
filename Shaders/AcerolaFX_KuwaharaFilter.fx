#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"
#include "Includes/AcerolaFX_TempTex2.fxh"

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

uniform uint _BlurRadius <
    ui_min = 1; ui_max = 6;
    ui_category_closed = true;
    ui_category = "Anisotropic Settings";
    ui_type = "slider";
    ui_label = "Blur Radius";
    ui_tooltip = "Size of the gaussian blur kernel for eigenvectors";
> = 2;

uniform float _Alpha <
    ui_min = 0.01f; ui_max = 2.0f;
    ui_category_closed = true;
    ui_category = "Anisotropic Settings";
    ui_type = "drag";
    ui_label = "Alpha";
    ui_tooltip = "How extreme the angle of the kernel is."; 
> = 1.0f;

uniform float _ZeroCrossing <
    ui_min = 0.01f; ui_max = 2.0f;
    ui_category_closed = true;
    ui_category = "Anisotropic Settings";
    ui_type = "drag";
    ui_label = "Zero Crossing";
    ui_tooltip = "How much sectors overlap with each other"; 
> = 0.58f;

uniform bool _DepthAware <
    ui_category = "Depth Settings";
    ui_category_closed = true;
    ui_label = "Depth Aware";
    ui_tooltip = "If enabled, change kuwahara filter radius based on depth.";
> = false;

uniform bool _SampleSky <
    ui_category = "Depth Settings";
    ui_category_closed = true;
    ui_label = "Sample Sky";
    ui_tooltip = "Apply kuwahara filter to skybox or not (disable to preserve stars).";
> = true;

uniform uint _MinKernelSize <
    ui_category = "Depth Settings";
    ui_category_closed = true;
    ui_min = 2; ui_max = 30;
    ui_label = "Min. Kernel Size";
    ui_type = "slider";
    ui_tooltip = "Kernel size for objects close to camera (if using depth filtering).";
> = 2;

uniform float _DepthCurve <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_category = "Depth Settings";
    ui_category_closed = true;
    ui_label = "Depth Curve";
    ui_type = "drag";
    ui_tooltip = "Change rate at which kernel sizes change between depths.";
> = 1.0f;

#ifndef AFX_SECTORS
# define AFX_SECTORS 8
#endif

sampler2D KuwaharaFilter { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
storage2D s_KuwaharaFilter { Texture = AFXTemp1::AFX_RenderTex1; };
void CS_EndPass(uint3 tid : SV_DISPATCHTHREADID) { tex2Dstore(Common::s_AcerolaBuffer, tid.xy, tex2Dfetch(KuwaharaFilter, tid.xy)); }

/* Basic Kuwahara Filter */
float4 SampleQuadrant(float2 uv, int x1, int x2, int y1, int y2, float n) {
    float luminanceSum = 0.0f;
    float luminanceSum2 = 0.0f;
    float3 colSum = 0.0f;

    for (int x = x1; x <= x2; ++x) {
        for (int y = y1; y <= y2; ++y) {
            float3 c = tex2Dfetch(Common::AcerolaBuffer, uv + float2(x, y)).rgb;
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

void Basic(in float2 uv, in float depth, out float4 output) {
    int radius = _KernelSize / 2;
    if (_DepthAware)
        radius = round(lerp(_MinKernelSize / 2.0f, _KernelSize / 2.0f, smoothstep(0.0f, 1.0f, depth)));

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

texture2D AFX_SectorsTex { Width = 32; Height = 32; Format = R16F; };
sampler2D Sectors { Texture = AFX_SectorsTex; };
texture2D AFX_WeightsTex { Width = 32; Height = 32; Format = R16F; };
sampler2D K0 { Texture = AFX_WeightsTex; };

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

void Generalized(in float2 uv, in float depth, out float4 output) {
    int k;
    float4 m[8];
    float3 s[8];
    int radius = _KernelSize / 2;
    if (_DepthAware)
        radius = round(lerp(_MinKernelSize / 2.0f, _KernelSize / 2.0f, smoothstep(0.0f, 1.0f, depth)));

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
            float3 c = tex2Dfetch(Common::AcerolaBuffer, uv + float2(x, y)).rgb;
            [unroll]
            for (k = 0; k < _N; ++k) {
                float w = tex2Dlod(K0, float4(0.5f + v, 0, 0)).x;

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

    output /= output.w;
}

/* Anisotropic Kuwahara Filter */

sampler2D StructureTensor { Texture = AFXTemp2::AFX_RenderTex2; };
storage2D s_StructureTensor { Texture = AFXTemp2::AFX_RenderTex2; };
sampler2D BlurredTensor { Texture = AFXTemp1::AFX_RenderTex1; };
storage2D s_BlurredTensor { Texture = AFXTemp1::AFX_RenderTex1; };
sampler2D TFM { Texture = AFXTemp2::AFX_RenderTex2; };
storage2D s_TFM { Texture = AFXTemp2::AFX_RenderTex2; };

float gaussian(float sigma, float pos) {
    return (1.0f / sqrt(2.0f * AFX_PI * sigma * sigma)) * exp(-(pos * pos) / (2.0f * sigma * sigma));
}

void CS_StructureTensor(uint3 tid : SV_DISPATCHTHREADID) {
    if (_Filter == 2) {
        float2 d = float2(1, 1);

        float3 Sx = (
             1.0f * tex2Dfetch(Common::AcerolaBuffer, tid.xy + float2(-d.x, -d.y)).rgb +
             2.0f * tex2Dfetch(Common::AcerolaBuffer, tid.xy + float2(-d.x,  0.0)).rgb +
             1.0f * tex2Dfetch(Common::AcerolaBuffer, tid.xy + float2(-d.x,  d.y)).rgb +
            -1.0f * tex2Dfetch(Common::AcerolaBuffer, tid.xy + float2(d.x, -d.y)).rgb +
            -2.0f * tex2Dfetch(Common::AcerolaBuffer, tid.xy + float2(d.x,  0.0)).rgb +
            -1.0f * tex2Dfetch(Common::AcerolaBuffer, tid.xy + float2(d.x,  d.y)).rgb
        ) / 4.0f;

        float3 Sy = (
             1.0f * tex2Dfetch(Common::AcerolaBuffer, tid.xy + float2(-d.x, -d.y)).rgb +
             2.0f * tex2Dfetch(Common::AcerolaBuffer, tid.xy + float2( 0.0, -d.y)).rgb +
             1.0f * tex2Dfetch(Common::AcerolaBuffer, tid.xy + float2( d.x, -d.y)).rgb +
            -1.0f * tex2Dfetch(Common::AcerolaBuffer, tid.xy + float2(-d.x, d.y)).rgb +
            -2.0f * tex2Dfetch(Common::AcerolaBuffer, tid.xy + float2( 0.0, d.y)).rgb +
            -1.0f * tex2Dfetch(Common::AcerolaBuffer, tid.xy + float2( d.x, d.y)).rgb
        ) / 4.0f;

        tex2Dstore(s_StructureTensor, tid.xy, float4(dot(Sx, Sx), dot(Sy, Sy), dot(Sx, Sy), 1.0f));
    }
}

void CS_HorizontalBlurPass(uint3 tid : SV_DISPATCHTHREADID) {
    if (_Filter == 2) {
        int kernelRadius = _BlurRadius;

        float4 col = 0;
        float kernelSum = 0.0f;

        for (int x = -kernelRadius; x <= kernelRadius; ++x) {
            float4 c = tex2Dfetch(StructureTensor, tid.xy + float2(x, 0));
            float gauss = gaussian(2.0f, x);

            col += c * gauss;
            kernelSum += gauss;
        }

        tex2Dstore(s_BlurredTensor, tid.xy, col / kernelSum);
    }
}

void CS_CalculateAnisotropy(uint3 tid : SV_DISPATCHTHREADID) {
    if (_Filter == 2) {
        int kernelRadius = _BlurRadius;

        float4 col = 0;
        float kernelSum = 0.0f;

        for (int y = -kernelRadius; y <= kernelRadius; ++y) {
            float4 c = tex2Dfetch(BlurredTensor, tid.xy + float2(0, y));
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
        
        tex2Dstore(s_TFM, tid.xy, float4(t, phi, A));
    }
}

void Anisotropic(in float2 uv, in float depth, out float4 output) {
    float alpha = _Alpha;
    float4 t = tex2Dfetch(TFM, uv);

    int _N = AFX_SECTORS;
    int radius = _KernelSize / 2;
    if (_DepthAware)
        radius = round(lerp(_MinKernelSize / 2.0f, _KernelSize / 2.0f, smoothstep(0.0f, 1.0f, depth)));

    float a = radius * clamp((alpha + t.w) / alpha, 0.1f, 2.0f);
    float b = radius * clamp(alpha / (alpha + t.w), 0.1f, 2.0f);
    
    float cos_phi = cos(t.z);
    float sin_phi = sin(t.z);

    float2x2 R = float2x2(
        float2(cos_phi, -sin_phi),
        float2(sin_phi, cos_phi)
    );

    float2x2 S = float2x2(
        float2(0.5f / a, 0.0f),
        float2(0.0f, 0.5f / b)
    );

    float2x2 SR = mul(S, R);

    int max_x = int(sqrt(a * a * cos_phi * cos_phi + b * b * sin_phi * sin_phi));
    int max_y = int(sqrt(a * a * sin_phi * sin_phi + b * b * cos_phi * cos_phi));

    float zeta = 2.0f / (_KernelSize / 2);

    float zeroCross = _ZeroCrossing;
    float sinZeroCross = sin(zeroCross);
    float eta = (zeta + cos(zeroCross)) / (sinZeroCross * sinZeroCross);
    int k;
    float4 m[8];
    float3 s[8];

    for (k = 0; k < _N; ++k) {
        m[k] = 0.0f;
        s[k] = 0.0f;
    }

    [loop]
    for (int y = -max_y; y <= max_y; ++y) {
        [loop]
        for (int x = -max_x; x <= max_x; ++x) {
            float2 v = mul(SR, float2(x, y));
            if (dot(v, v) <= 0.25f) {
                float3 c = tex2Dfetch(Common::AcerolaBuffer, uv + float2(x, y)).rgb;
                float sum = 0;
                float w[8];
                float z, vxx, vyy;
                
                /* Calculate Polynomial Weights */
                vxx = zeta - eta * v.x * v.x;
                vyy = zeta - eta * v.y * v.y;
                z = max(0, v.y + vxx); 
                w[0] = z * z;
                sum += w[0];
                z = max(0, -v.x + vyy); 
                w[2] = z * z;
                sum += w[2];
                z = max(0, -v.y + vxx); 
                w[4] = z * z;
                sum += w[4];
                z = max(0, v.x + vyy); 
                w[6] = z * z;
                sum += w[6];
                v = sqrt(2.0f) / 2.0f * float2(v.x - v.y, v.x + v.y);
                vxx = zeta - eta * v.x * v.x;
                vyy = zeta - eta * v.y * v.y;
                z = max(0, v.y + vxx); 
                w[1] = z * z;
                sum += w[1];
                z = max(0, -v.x + vyy); 
                w[3] = z * z;
                sum += w[3];
                z = max(0, -v.y + vxx); 
                w[5] = z * z;
                sum += w[5];
                z = max(0, v.x + vyy); 
                w[7] = z * z;
                sum += w[7];
                
                float g = exp(-3.125f * dot(v,v)) / sum;
                
                for (int k = 0; k < 8; ++k) {
                    float wk = w[k] * g;
                    m[k] += float4(c * wk, wk);
                    s[k] += c * c * wk;
                }
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

    output /= output.w;
}

void CS_KuwaharaFilter(uint3 tid : SV_DISPATCHTHREADID) {
    float4 output = 1.0f;
    float depth = ReShade::GetLinearizedDepth(tid.xy / float2(BUFFER_WIDTH, BUFFER_HEIGHT));
    bool sampleSky = _SampleSky ? true : depth < 0.98f;

    if (sampleSky) {
        depth = pow(abs(depth), _DepthCurve);
        if (_Filter == 0) Basic(tid.xy, depth, output);
        if (_Filter == 1) Generalized(tid.xy, depth, output);
        if (_Filter == 2) Anisotropic(tid.xy, depth, output);
    } else {
        output.rgb = tex2Dfetch(Common::AcerolaBuffer, tid.xy).rgb;
    }

    tex2Dstore(s_KuwaharaFilter, tid.xy, output);
}

technique AFX_SetupKuwahara < hidden = true; enabled = true; timeout = 1; > {
    pass GenerateSectors {
        RenderTarget = AFX_SectorsTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_CalculateSectors;
    }

    pass GaussianFilter {
        RenderTarget = AFX_WeightsTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_GaussianFilterSectors;
    }
}

technique AFX_KuwaharaFilter < ui_label = "Kuwahara Filter"; ui_tooltip = "(LDR)(VERY HIGH PERFORMANCE COST) Applies a Kuwahara filter to the screen."; > {
    pass {
        ComputeShader = CS_StructureTensor<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    pass {
        ComputeShader = CS_HorizontalBlurPass<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    pass {
        ComputeShader = CS_CalculateAnisotropy<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    pass {
        ComputeShader = CS_KuwaharaFilter<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    pass {
        ComputeShader = CS_EndPass<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }
}