#include "ReShade.fxh"
#include "Common.fxh"

uniform float _MinLogLuminance <
    ui_min = -20.0f; ui_max = 20.0f;
    ui_label = "Min Log Luminance";
    ui_type = "drag";
    ui_tooltip = "Adjust the minimum log luminance.";
> = -10.0f;

uniform float _MaxLogLuminance <
    ui_min = -20.0f; ui_max = 20.0f;
    ui_label = "Max Log Luminance";
    ui_type = "drag";
    ui_tooltip = "Adjust the maximum log luminance.";
> = 2.0f;


#define DIVIDE_ROUNDING_UP(n, d) uint(((n) + (d) - 1) / (d))
#define DISPATCH_X DIVIDE_ROUNDING_UP(BUFFER_WIDTH, 16)
#define DISPATCH_Y DIVIDE_ROUNDING_UP(BUFFER_HEIGHT, 16)
#define TILE_COUNT (DISPATCH_X * DISPATCH_Y)

#define LOG_RANGE_RCP 1.0f / (_MaxLogLuminance - _MinLogLuminance)

texture2D HistogramTileTex {
    Width = TILE_COUNT; Height = 256; Format = R32F;
}; storage2D HistogramTileBuffer { Texture = HistogramTileTex; };
sampler2D HistogramTileSampler { Texture = HistogramTileTex; };

texture2D HistogramTex {
    Width = 256; Height = 1; Format = R32F;
}; storage2D HistogramBuffer { Texture = HistogramTex; };

uint ColorToHistogramBin(float3 col) {
    float luminance = Common::Luminance(col);
    
    if (luminance < 0.001f)
        return 0;

    float logLuminance = saturate((log2(luminance) - _MinLogLuminance) *  LOG_RANGE_RCP);

    return (uint)(logLuminance * 254.0f + 1.0f);
}

groupshared uint HistogramShared[256];
void ConstructHistogramTiles(uint groupIndex : SV_GROUPINDEX, uint3 tid : SV_DISPATCHTHREADID, uint3 gtid : SV_GROUPTHREADID) {
    HistogramShared[groupIndex] = 0;

    barrier();

    if (tid.x < BUFFER_WIDTH && tid.y < BUFFER_HEIGHT) {
        float4 col = tex2Dfetch(Common::AcerolaBuffer, tid.xy);
        if (col.a == 0.0f) {
            uint binIndex = ColorToHistogramBin(col.rgb);
            atomicAdd(HistogramShared[binIndex], 1);
        }
    }

    barrier();

    uint dispatchIndex = tid.x / 16 + (tid.y / 16) * DISPATCH_X;
    uint threadIndex = gtid.x + gtid.y * 16;
    tex2Dstore(HistogramTileBuffer, uint2(dispatchIndex, threadIndex), HistogramShared[groupIndex]);
}

groupshared uint mergedBin;
void MergeHistogramTiles(uint3 tid : SV_DISPATCHTHREADID, uint3 gtid : SV_GROUPTHREADID) {
    if (all(gtid.xy == 0))
        mergedBin = 0;

    barrier();

    float2 coord = float2(tid.x * 8, tid.y) + 0.5;
    uint histValues = 0;
    [unroll]
    for (int i = 0; i < 8; ++i)
        histValues += tex2Dfetch(HistogramTileSampler, coord + float2(i, 0)).r;

    atomicAdd(mergedBin, histValues);

    barrier();

    if (all(gtid.xy ==0))
        tex2Dstore(HistogramBuffer, uint2(tid.y, 0), mergedBin);
}

technique AutoExposure {
    pass HistogramTiles {
        ComputeShader = ConstructHistogramTiles<16, 16>;
        DispatchSizeX = DISPATCH_X;
        DispatchSizeY = DISPATCH_Y;
    }

    pass Histogram {
        ComputeShader = MergeHistogramTiles<DIVIDE_ROUNDING_UP(TILE_COUNT, 8), 1>;
        DispatchSizeX = 1;
        DispatchSizeY = 256;
    }
}