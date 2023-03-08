#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

#ifndef AFX_DEBUG_MASK
 #define AFX_DEBUG_MASK 0
#endif

#ifndef AFX_DEBUG_SPANS
 #define AFX_DEBUG_SPANS 0
#endif

#ifndef AFX_HORIZONTAL_SORT
 #define AFX_HORIZONTAL_SORT 0
#endif

uniform float _LowThreshold <
    ui_category_closed = true;
    ui_category = "Mask Settings";
    ui_min = 0.0f; ui_max = 0.5f;
    ui_label = "Low Threshold";
    ui_type = "slider";
    ui_tooltip = "Adjust the threshold at which dark pixels are omitted from the mask.";
> = 0.4f;

uniform float _HighThreshold <
    ui_category_closed = true;
    ui_category = "Mask Settings";
    ui_min = 0.5f; ui_max = 1.0f;
    ui_label = "High Threshold";
    ui_type = "slider";
    ui_tooltip = "Adjust the threshold at which bright pixels are omitted from the mask.";
> = 0.72f;

uniform bool _InvertMask <
    ui_category_closed = true;
    ui_category = "Mask Settings";
    ui_label = "Invert Mask";
    ui_tooltip = "Invert sorting mask.";
> = false;

uniform float _MaskRandomOffset <
    ui_category_closed = true;
    ui_category = "Mask Settings";
    ui_min = -0.01f; ui_max = 0.01f;
    ui_label = "Random Offset";
    ui_type = "drag";
    ui_tooltip = "Adjust the random offset of each segment to reduce uniformity.";
> = 0.0f;

uniform float _AnimationSpeed <
    ui_category_closed = true;
    ui_category = "Mask Settings";
    ui_min = 0f; ui_max = 30f;
    ui_label = "Offset Animation Speed";
    ui_type = "slider";
    ui_tooltip = "Animate the random offset.";
> = 0.0f;

uniform int _SpanLimit <
    ui_category_closed = true;
    ui_category = "Span Settings";
    ui_min = 0; 
    ui_max = 256;
    ui_label = "Length Limit";
    ui_type = "slider";
    ui_tooltip = "Adjust the max length of sorted spans. This will heavily impact performance.";
> = 64;

uniform int _MaxRandomOffset <
    ui_category_closed = true;
    ui_category = "Span Settings";
    ui_min = 1; ui_max = 64;
    ui_label = "Random Offset";
    ui_type = "slider";
    ui_tooltip = "Adjust the random length offset of limited spans to reduce uniformity.";
> = 1;

uniform int _SortBy <
    ui_category = "Sort Settings";
    ui_category_closed = true;
    ui_type = "combo";
    ui_label = "Sort By";
    ui_tooltip = "What color information to sort by.";
    ui_items = "Luminance\0"
               "Saturation\0"
               "Hue\0";
> = 0;

uniform bool _ReverseSorting <
    ui_category_closed = true;
    ui_category = "Sort Settings";
    ui_label = "Reverse Sorting";
> = false;

uniform float _SortedGamma <
    ui_category_closed = true;
    ui_category = "Sort Settings";
    ui_min = 0.1f; ui_max = 5.0f;
    ui_label = "Gamma";
    ui_type = "drag";
    ui_tooltip = "Adjust gamma of sorted pixels to accentuate them.";
> = 1.0f;

uniform float _FrameTime < source = "frametime"; >;

texture2D AFX_PixelSortMaskTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; }; 
sampler2D Mask { Texture = AFX_PixelSortMaskTex; };
storage2D s_Mask { Texture = AFX_PixelSortMaskTex; };

texture2D AFX_SortValueTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; }; 
sampler2D SortValue { Texture = AFX_SortValueTex; };
storage2D s_SortValue { Texture = AFX_SortValueTex; };

texture2D AFX_SpanLengthsTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F; }; 
sampler2D SpanLengths { Texture = AFX_SpanLengthsTex; };
storage2D s_SpanLengths { Texture = AFX_SpanLengthsTex; };

sampler2D PixelSort { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(PixelSort, uv).rgba; }
float4 PS_DebugMask(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Mask, uv).r; }

float hash(uint n) {
    // integer hash copied from Hugo Elias
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 0x789221U) + 0x1376312589U;
    return float(n & uint(0x7fffffffU)) / float(0x7fffffff);
}

void CS_CreateMask(uint3 id : SV_DISPATCHTHREADID) {
    float2 pixelSize = float2(BUFFER_RCP_HEIGHT, BUFFER_RCP_WIDTH);

#if AFX_HORIZONTAL_SORT == 0
    uint seed = id.x * BUFFER_WIDTH;
#else
    uint seed = id.y * BUFFER_HEIGHT;
#endif

    float rand = hash(seed + (_FrameTime * _AnimationSpeed)) * _MaskRandomOffset;

    float2 uv = id.xy / float2(BUFFER_WIDTH, BUFFER_HEIGHT);

#if AFX_HORIZONTAL_SORT == 0
    uv.y += rand;
#else
    uv.x += rand;
#endif

    float4 col = saturate(tex2Dlod(Common::AcerolaBuffer, float4(uv, 0, 0)));

    float l = Common::Luminance(col.rgb);

    int result = 1;
    if (l < _LowThreshold || _HighThreshold < l)
        result = 0;
    
    tex2Dstore(s_Mask, id.xy, _InvertMask ? 1 - result : result);
}

void CS_CreateSortValues(uint3 id : SV_DISPATCHTHREADID) {
    float4 col = tex2Dfetch(Common::AcerolaBuffer, id.xy);

    float3 hsl = Common::RGBtoHSL(col.rgb);

    float output = 0.0f;

    if (_SortBy == 0)
        output = hsl.b;
    else if (_SortBy == 1)
        output = hsl.g;
    else
        output = hsl.r;

    tex2Dstore(s_SortValue, id.xy, output);
}

void CS_ClearBuffers(uint3 id : SV_DISPATCHTHREADID) {
    tex2Dstore(s_SpanLengths, id.xy, 0);
    tex2Dstore(AFXTemp1::s_RenderTex, id.xy, 0);
}

void CS_IdentifySpans(uint3 id : SV_DISPATCHTHREADID) {
    uint seed = id.x + BUFFER_WIDTH * id.y + BUFFER_WIDTH * BUFFER_HEIGHT;
    uint2 idx = 0;
    uint pos = 0;
    uint spanStartIndex = 0;
    uint spanLength = 0;

#if AFX_HORIZONTAL_SORT == 0
    uint screenLimit = BUFFER_HEIGHT;
#else
    uint screenLimit = BUFFER_WIDTH;
#endif

    uint spanLimit = _SpanLimit - (hash(seed) * _MaxRandomOffset);

    while (pos < screenLimit) {
#if AFX_HORIZONTAL_SORT == 0
        idx = uint2(id.x, pos);
#else
        idx = uint2(pos, id.y);
#endif

        int mask = tex2Dfetch(Mask, idx).r;
        pos++;

        if (mask == 0 || spanLength >= spanLimit) {
#if AFX_HORIZONTAL_SORT == 0
            idx = uint2(id.x, spanStartIndex);
#else
            idx = uint2(spanStartIndex, id.y);
#endif
            tex2Dstore(s_SpanLengths, idx, mask == 1 ? spanLength + 1 : spanLength);
            spanStartIndex = pos;
            spanLength = 0;
        } else {
            spanLength++;
        }
    }

    if (spanLength != 0) {
#if AFX_HORIZONTAL_SORT == 0
        idx = uint2(id.x, spanStartIndex);
#else
        idx = uint2(spanStartIndex, id.y);
#endif
        tex2Dstore(s_SpanLengths, idx, spanLength);
    }
}

void CS_VisualizeSpans(uint3 id : SV_DISPATCHTHREADID) {
    int spanLength = tex2Dfetch(SpanLengths, id.xy).r;

    if (spanLength >= 1) {
        uint seed = id.x + BUFFER_WIDTH * id.y + BUFFER_WIDTH * BUFFER_HEIGHT;
        float4 c = float4(hash(seed), hash(seed * 2), hash(seed * 3), 1.0f);

        for (int i = 0; i < spanLength; ++i) {
#if AFX_HORIZONTAL_SORT == 0
            uint2 idx = uint2(id.x, id.y + i);
#else
            uint2 idx = uint2(id.x + i, id.y);
#endif

            tex2Dstore(AFXTemp1::s_RenderTex, idx, c);
        }
    }
}


groupshared float gs_PixelSortCache[256];

void CS_PixelSort(uint3 id : SV_DISPATCHTHREADID) {
    const uint spanLength = tex2Dfetch(SpanLengths, id.xy).r;

    if (spanLength >= 1) {
        uint2 idx;
#if AFX_HORIZONTAL_SORT == 0
        const uint2 direction = uint2(0, 1);
#else
        const uint2 direction = uint2(1, 0);
#endif

        for (int k = 0; k < spanLength; ++k) {
            idx = id.xy + k * direction;
            gs_PixelSortCache[k] = tex2Dfetch(SortValue, idx).r;
        }

        float minValue = gs_PixelSortCache[0];
        float maxValue = gs_PixelSortCache[0];
        uint minIndex = 0;
        uint maxIndex = 0;

        for (uint i = 0; i < (spanLength / 2) + 1; ++i) {
            for (uint j = 1; j < spanLength; ++j) {
                float v = gs_PixelSortCache[j];

                if (v == saturate(v)) {
                    if (v < minValue) {
                        minValue = v;
                        minIndex = j;
                    }

                    if (maxValue < v) {
                        maxValue = v;
                        maxIndex = j;
                    }
                }
            }

            uint2 minIdx = 0;
            uint2 maxIdx = 0;

            if (_ReverseSorting) {
                minIdx = id.xy + i * direction;
                maxIdx = id.xy + (spanLength - i - 1) * direction;
            } else {
                minIdx = id.xy + (spanLength - i - 1) * direction;
                maxIdx = id.xy + i * direction;
            }
            
            const uint2 minColorIdx = id.xy + minIndex * direction;
            const uint2 maxColorIdx = id.xy + maxIndex * direction;
            

            tex2Dstore(AFXTemp1::s_RenderTex, minIdx, pow(abs(tex2Dfetch(Common::AcerolaBuffer, minColorIdx)), _SortedGamma));
            tex2Dstore(AFXTemp1::s_RenderTex, maxIdx, pow(abs(tex2Dfetch(Common::AcerolaBuffer, maxColorIdx)), _SortedGamma));
            gs_PixelSortCache[minIndex] = 2;
            gs_PixelSortCache[maxIndex] = -2;
            minValue = 1;
            maxValue = -1;
        }
    }
}

void CS_Composite(uint3 id : SV_DISPATCHTHREADID) {
    if (tex2Dfetch(Mask, id.xy).r == 0) {
        tex2Dstore(AFXTemp1::s_RenderTex, id.xy, tex2Dfetch(Common::AcerolaBuffer, id.xy));
    }
}

technique AFX_PixelSort < ui_label = "Pixel Sort"; ui_tooltip = "(EXTREMELY HIGH PERFORMANCE COST) Sort the game pixels."; > {
    pass {
        ComputeShader = CS_CreateMask<8, 8>;
        DispatchSizeX = BUFFER_WIDTH / 8;
        DispatchSizeY = BUFFER_HEIGHT / 8;
    }

#if AFX_DEBUG_MASK != 0
    pass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_DebugMask;
    }
#else
    pass {
        ComputeShader = CS_CreateSortValues<8, 8>;
        DispatchSizeX = BUFFER_WIDTH / 8;
        DispatchSizeY = BUFFER_HEIGHT / 8;
    }
    
    pass {
        ComputeShader = CS_ClearBuffers<8, 8>;
        DispatchSizeX = BUFFER_WIDTH / 8;
        DispatchSizeY = BUFFER_HEIGHT / 8;
    }

    pass {
        ComputeShader = CS_IdentifySpans<1, 1>;
#if AFX_HORIZONTAL_SORT == 0
        DispatchSizeX = BUFFER_WIDTH;
        DispatchSizeY = 1;
#else
        DispatchSizeX = 1;
        DispatchSizeY = BUFFER_HEIGHT;
#endif
    }

#if AFX_DEBUG_SPANS != 0
    pass {
        ComputeShader = CS_VisualizeSpans<1, 1>;
        DispatchSizeX = BUFFER_WIDTH;
        DispatchSizeY = BUFFER_HEIGHT;
    }
#else
    pass {
        ComputeShader = CS_PixelSort<1, 1>;
        DispatchSizeX = BUFFER_WIDTH;
        DispatchSizeY = BUFFER_HEIGHT;
    }

    pass {
        ComputeShader = CS_Composite<8, 8>;
        DispatchSizeX = BUFFER_WIDTH / 8;
        DispatchSizeY = BUFFER_HEIGHT / 8;
    }
#endif

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
#endif
}