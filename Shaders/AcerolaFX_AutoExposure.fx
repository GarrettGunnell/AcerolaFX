#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_Downscales.fxh"

uniform float _MinLogLuminance <
    ui_min = -20.0f; ui_max = 20.0f;
    ui_label = "Min Log Luminance";
    ui_type = "drag";
    ui_tooltip = "Adjust the minimum log luminance allowed.";
> = -5.0f;

uniform float _MaxLogLuminance <
    ui_min = -20.0f; ui_max = 20.0f;
    ui_label = "Max Log Luminance";
    ui_type = "drag";
    ui_tooltip = "Adjust the maximum log luminance allowed.";
> = -2.5f;

uniform float _Tau <
    ui_category = "Advanced Settings";
    ui_category_closed = true;
    ui_min = 0.01f; ui_max = 10.0f;
    ui_label = "Tau";
    ui_type = "drag";
    ui_tooltip = "Adjust rate at which auto exposure adjusts.";
> = 5.0f;

uniform float _S1 <
    ui_category = "Advanced Settings";
    ui_category_closed = true;
    ui_min = 0.01f; ui_max = 200.0f;
    ui_label = "Sensitivity Constant 1";
    ui_type = "drag";
    ui_tooltip = "Adjust sensor sensitivity ratio 1.";
> = 100.0f;

uniform float _S2 <
    ui_category = "Advanced Settings";
    ui_category_closed = true;
    ui_min = 0.01f; ui_max = 200.0f;
    ui_label = "Sensitivity Constant 2";
    ui_type = "drag";
    ui_tooltip = "Adjust sensor sensitivity ratio 2.";
> = 100.0f;

uniform float _K <
    ui_category = "Advanced Settings";
    ui_category_closed = true;
    ui_min = 1.0f; ui_max = 100.0f;
    ui_label = "Calibration Constant";
    ui_type = "drag";
    ui_tooltip = "Adjust reflected-light meter calibration constant.";
> = 12.5f;

uniform float _q <
    ui_category = "Advanced Settings";
    ui_category_closed = true;
    ui_min = 0.01f; ui_max = 10.0f;
    ui_label = "Lens Attenuation";
    ui_type = "drag";
    ui_tooltip = "Adjust lens and vignetting attenuation.";
> = 0.65f;

uniform float _DeltaTime < source = "frametime"; >;

#define AFX_DIVIDE_ROUNDING_UP(n, d) uint(((n) + (d) - 1) / (d))
#define AFX_WIDTH  BUFFER_WIDTH / 2
#define AFX_HEIGHT BUFFER_HEIGHT / 2
#define AFX_DISPATCH_X AFX_DIVIDE_ROUNDING_UP(AFX_WIDTH, 16)
#define AFX_DISPATCH_Y AFX_DIVIDE_ROUNDING_UP(AFX_HEIGHT, 16)
#define AFX_TILE_COUNT (AFX_DISPATCH_X * AFX_DISPATCH_Y)

#if BUFFER_WIDTH <= 3440
    #define AFX_TILE_STRIDE 8
#else
    #define AFX_TILE_STRIDE 16
#endif

#define AFX_LOG_RANGE (_MaxLogLuminance - _MinLogLuminance)
#define AFX_LOG_RANGE_RCP 1.0f / AFX_LOG_RANGE

texture2D AFX_AutoExposureTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D AutoExposure { Texture = AFX_AutoExposureTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
storage2D s_AutoExposure { Texture = AFX_AutoExposureTex; };
void CS_EndPass(uint3 tid : SV_DISPATCHTHREADID) { tex2Dstore(Common::s_AcerolaBuffer, tid.xy, tex2Dfetch(AutoExposure, tid.xy)); }

texture2D AFX_HistogramTileTex {
    Width = AFX_TILE_COUNT; Height = 256; Format = R32F;
}; storage2D HistogramTileBuffer { Texture = AFX_HistogramTileTex; };
sampler2D HistogramTileSampler { Texture = AFX_HistogramTileTex; };

texture2D AFX_HistogramTex {
    Width = 256; Height = 1; Format = R32F;
}; storage2D HistogramBuffer { Texture = AFX_HistogramTex; };
sampler2D HistogramSampler { Texture = AFX_HistogramTex; };

texture2D AFX_HistogramAverageTex { Format = R32F; };
storage2D HistogramAverageBuffer { Texture = AFX_HistogramAverageTex; };
sampler2D HistogramAverage { Texture = AFX_HistogramAverageTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };

uint ColorToHistogramBin(float3 col) {
    float luminance = Common::Luminance(col);
    
    if (luminance < 0.001f)
        return 0;

    float logLuminance = saturate((log2(luminance) - _MinLogLuminance) *  AFX_LOG_RANGE_RCP);

    return (uint)(logLuminance * 254.0f + 1.0f);
}

groupshared uint HistogramShared[256];
void ConstructHistogramTiles(uint groupIndex : SV_GROUPINDEX, uint3 tid : SV_DISPATCHTHREADID, uint3 gtid : SV_GROUPTHREADID) {
    HistogramShared[groupIndex] = 0;

    barrier();

    if (tid.x < AFX_WIDTH && tid.y < AFX_HEIGHT) {
        float4 col = tex2Dfetch(DownScale::Half, tid.xy);
        uint binIndex = ColorToHistogramBin(col.rgb);
        atomicAdd(HistogramShared[binIndex], 1);
    }

    barrier();

    uint dispatchIndex = tid.x / 16 + (tid.y / 16) * AFX_DISPATCH_X;
    uint threadIndex = gtid.x + gtid.y * 16;
    tex2Dstore(HistogramTileBuffer, uint2(dispatchIndex, threadIndex), HistogramShared[groupIndex]);
}

groupshared uint mergedBin;
void MergeHistogramTiles(uint3 tid : SV_DISPATCHTHREADID, uint3 gtid : SV_GROUPTHREADID) {
    if (all(gtid.xy == 0))
        mergedBin = 0;

    barrier();

    float2 coord = float2(tid.x * AFX_TILE_STRIDE, tid.y) + 0.5;
    uint histValues = 0;
    [unroll]
    for (int i = 0; i < AFX_TILE_STRIDE; ++i)
        histValues += tex2Dfetch(HistogramTileSampler, coord + float2(i, 0)).r;

    atomicAdd(mergedBin, histValues);

    barrier();

    if (all(gtid.xy ==0))
        tex2Dstore(HistogramBuffer, uint2(tid.y, 0), mergedBin);
}

groupshared float HistogramAvgShared[256];
void CalculateHistogramAverage(uint3 tid : SV_DISPATCHTHREADID) {
    float countForThisBin = (float)tex2Dfetch(HistogramSampler, tid.xy).r;

    HistogramAvgShared[tid.x] = countForThisBin * (float)tid.x;

    barrier();

    [unroll]
    for (uint histogramSampleIndex = (256 >> 1); histogramSampleIndex > 0; histogramSampleIndex >>= 1) {
        if (tid.x < histogramSampleIndex) {
            HistogramAvgShared[tid.x] += HistogramAvgShared[tid.x + histogramSampleIndex];
        }

        barrier();
    }

    if (tid.x == 0) {
        float weightedLogAverage = (HistogramAvgShared[0] / max((float)(AFX_WIDTH * AFX_HEIGHT) - countForThisBin, 1.0f)) - 1.0f;
        float weightedAverageLuminance = exp2(((weightedLogAverage / 254.0f) * AFX_LOG_RANGE) + _MinLogLuminance);
        float luminanceLastFrame = tex2Dfetch(HistogramAverage, uint2(0, 0)).r;
        float adaptedLuminance = luminanceLastFrame + (weightedAverageLuminance - luminanceLastFrame) * (1 - exp(-_DeltaTime * _Tau));
        tex2Dstore(HistogramAverageBuffer, uint2(0, 0), adaptedLuminance);
    }
}

void CS_Downscale(uint3 tid : SV_DISPATCHTHREADID) {
    float4 col = tex2Dfetch(Common::AcerolaBufferLinear, tid.xy);
    
    tex2Dstore(DownScale::s_Half, tid.xy, float4(lerp(col.rgb, 0.5f, col.a), col.a));
}

void CS_AutoExposure(uint3 tid : SV_DISPATCHTHREADID) {
    float4 col = tex2Dfetch(Common::AcerolaBuffer, tid.xy);
    float avgLuminance = tex2Dfetch(HistogramAverage, 0).r;

    float luminanceScale = (78.0f / (_q * _S1)) * (_S2 / _K) * avgLuminance;

    float3 yxy = Common::convertRGB2Yxy(col.rgb);
    yxy.x /= luminanceScale;
    col.rgb = Common::convertYxy2RGB(yxy);

    tex2Dstore(s_AutoExposure, tid.xy, col);
}



technique AFX_AutoExposure <ui_label = "Auto Exposure"; ui_tooltip = "(HDR) Automatically adjusts exposure based on average luminance of the screen. Generally goes right before tone mapping."; > {
    pass {
        ComputeShader = CS_Downscale<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    pass HistogramTiles {
        ComputeShader = ConstructHistogramTiles<16, 16>;
        DispatchSizeX = AFX_DISPATCH_X;
        DispatchSizeY = AFX_DISPATCH_Y;
    }

    pass Histogram {
        ComputeShader = MergeHistogramTiles<AFX_DIVIDE_ROUNDING_UP(AFX_TILE_COUNT, AFX_TILE_STRIDE), 1>;
        DispatchSizeX = 1;
        DispatchSizeY = 256;
    }

    pass AverageHistogram {
        ComputeShader = CalculateHistogramAverage<256, 1>;
        DispatchSizeX = 1;
        DispatchSizeY = 1;
    }

    pass {
        ComputeShader = CS_AutoExposure<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    pass {
        ComputeShader = CS_EndPass<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }
}